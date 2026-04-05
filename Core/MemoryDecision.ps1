# MemoryDecision.ps1 - Automatic memory decision system
# Analyzes each conversation turn and decides what to save automatically
# Uses Add-Learning and Add-PSCoderMemoryNote instead of writing to internal state directly

$Script:MemoryDecisionDir = Join-Path $HOME ".pscoder\memory_decisions"
$Script:DecisionLog = @()
$Script:MemoryFilters = @{
    ErrorPatterns = @("error", "failed", "exception", "not found", "access denied", "timeout", "cannot")
    SolutionPatterns = @("fixed", "resolved", "solution", "worked", "success", "completed")
    UserPreferencePatterns = @("prefer", "always", "never", "use ", "don't use", "i like", "i want", "my ")
    ProjectPatterns = @("project", "repository", "module", "script", "application", "website")
    NewCommandPatterns = @("install", "setup", "configure", "create", "init", "new ")
    NoisePatterns = @("hello", "thanks", "ok", "yes", "no", "good", "bye", "help", "what is")
}

function Initialize-MemoryDecision {
    Load-DecisionLog
}

function Load-DecisionLog {
    $logPath = Join-Path $Script:MemoryDecisionDir "decision_log.json"
    if (Test-Path $logPath) {
        try {
            $loaded = Get-Content $logPath -Raw | ConvertFrom-Json
            if ($loaded -is [array]) { $Script:DecisionLog = $loaded }
            else { $Script:DecisionLog = @($loaded) }
        } catch {
            $Script:DecisionLog = @()
        }
    }
}

function Save-DecisionLog {
    $logPath = Join-Path $Script:MemoryDecisionDir "decision_log.json"
    @($Script:DecisionLog) | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding UTF8
}

function Invoke-MemoryDecision {
    param(
        [array]$Messages,
        [string]$WorkingDir = ""
    )

    $decisions = @()
    $actionsTaken = 0

    $userMessages = $Messages | Where-Object { $_.role -eq "user" } | Select-Object -Last 5
    $assistantMessages = $Messages | Where-Object { $_.role -eq "assistant" } | Select-Object -Last 5
    $toolMessages = $Messages | Where-Object { $_.role -eq "tool" } | Select-Object -Last 10

    if ($userMessages.Count -eq 0) { return "No user messages to analyze." }

    $lastUserInput = $userMessages[-1].content
    $lastAssistantOutput = ""
    if ($assistantMessages.Count -gt 0) {
        $lastAssistantOutput = $assistantMessages[-1].content
    }

    $toolResults = ($toolMessages | ForEach-Object { $_.content }) -join "`n"

    $errorDecision = Invoke-CheckErrorLearning -UserInput $lastUserInput -ToolResults $toolResults -AssistantOutput $lastAssistantOutput
    if ($errorDecision.shouldSave) {
        $decisions += $errorDecision
        $actionsTaken++
    }

    $prefDecision = Invoke-CheckUserPreferences -UserInput $lastUserInput -AssistantOutput $lastAssistantOutput
    if ($prefDecision.shouldSave) {
        $decisions += $prefDecision
        $actionsTaken++
    }

    $projDecision = Invoke-CheckProjectContext -UserInput $lastUserInput -WorkingDir $WorkingDir -ToolResults $toolResults
    if ($projDecision.shouldSave) {
        $decisions += $projDecision
        $actionsTaken++
    }

    $patternDecision = Invoke-CheckSuccessPattern -ToolResults $toolResults -AssistantOutput $lastAssistantOutput
    if ($patternDecision.shouldSave) {
        $decisions += $patternDecision
        $actionsTaken++
    }

    $cmdDecision = Invoke-CheckCommandPattern -UserInput $lastUserInput -ToolResults $toolResults
    if ($cmdDecision.shouldSave) {
        $decisions += $cmdDecision
        $actionsTaken++
    }

    if ($decisions.Count -gt 0) {
        $logEntry = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            decisions = $decisions
            actionsTaken = $actionsTaken
            userInput = if ($lastUserInput.Length -gt 200) { $lastUserInput.Substring(0, 200) + "..." } else { $lastUserInput }
        }
        $Script:DecisionLog += $logEntry
        Save-DecisionLog
    }

    if ($actionsTaken -eq 0) {
        return "Memory analysis: Nothing valuable to save this turn."
    }

    $result = "MEMORY DECISIONS: $actionsTaken action(s) taken`n"
    $result += "=" * 50 + "`n"
    foreach ($d in $decisions) {
        $dtype = if ($d -is [hashtable]) { $d["type"] } else { $d.type }
        $daction = if ($d -is [hashtable]) { $d["action"] } else { $d.action }
        $dreason = if ($d -is [hashtable]) { $d["reason"] } else { $d.reason }
        if ($dtype) { $result += "[$($dtype.ToUpper())] $daction : $dreason`n" }
    }
    $result += "`nMemory updated automatically.`n"

    return $result
}

function Invoke-CheckErrorLearning {
    param(
        [string]$UserInput,
        [string]$ToolResults,
        [string]$AssistantOutput
    )

    $decision = @{
        type = "error_learning"
        shouldSave = $false
        action = ""
        reason = ""
    }

    if ($ToolResults -match "ERROR|failed|exception|not found") {
        if ($ToolResults -match "completed|success|created|edited|fixed") {
            $errorMatch = ""
            if ($ToolResults -match "ERROR: (.+?)(?:\n|$)") { $errorMatch = $Matches[1] }
            elseif ($ToolResults -match "failed: (.+?)(?:\n|$)") { $errorMatch = $Matches[1] }

            if ($errorMatch) {
                $existing = Find-Solution -Problem $errorMatch
                if (-not $existing.found) {
                    $solution = ""
                    if ($AssistantOutput -match "((?:fixed|resolved|solved|worked).+?)(?:\.|$)") {
                        $solution = $Matches[1]
                    } else {
                        $solution = "Resolved through tool execution"
                    }

                    Add-Learning -Category "error_resolution" -Problem $errorMatch -Solution $solution -Context $UserInput
                    $decision.shouldSave = $true
                    $decision.action = "Saved error resolution to learnings"
                    $decision.reason = "New error resolved: $errorMatch"
                }
            }
        }
    }

    return $decision
}

function Invoke-CheckUserPreferences {
    param(
        [string]$UserInput,
        [string]$AssistantOutput
    )

    $decision = @{
        type = "user_preference"
        shouldSave = $false
        action = ""
        reason = ""
    }

    $isPreference = $false
    $preferenceText = ""

    foreach ($pattern in $Script:MemoryFilters.UserPreferencePatterns) {
        if ($UserInput -match "(?i)$pattern") {
            $isPreference = $true
            $preferenceText = $UserInput
            break
        }
    }

    if (-not $isPreference -and $AssistantOutput -match "(?i)(user prefers|you prefer|setting|configured) (.+?)(?:\.|$)") {
        $isPreference = $true
        $preferenceText = "Preference: $($Matches[2])"
    }

    if ($isPreference -and $preferenceText.Length -gt 10) {
        $isNoise = $false
        foreach ($noise in $Script:MemoryFilters.NoisePatterns) {
            if ($preferenceText -match "(?i)^$noise") {
                $isNoise = $true
                break
            }
        }

        if (-not $isNoise) {
            $currentMemory = ""
            try { $currentMemory = Get-PSCoderMemory } catch {}
            if ($currentMemory -notmatch [regex]::Escape($preferenceText.Substring(0, [Math]::Min(30, $preferenceText.Length)))) {
                Add-PSCoderMemoryNote -Note "PREFERENCE: $preferenceText"
                $decision.shouldSave = $true
                $decision.action = "Added user preference to memory"
                $decision.reason = $preferenceText
            }
        }
    }

    return $decision
}

function Invoke-CheckProjectContext {
    param(
        [string]$UserInput,
        [string]$WorkingDir,
        [string]$ToolResults
    )

    $decision = @{
        type = "project_context"
        shouldSave = $false
        action = ""
        reason = ""
    }

    $isProject = $false
    $projectInfo = ""

    foreach ($pattern in $Script:MemoryFilters.ProjectPatterns) {
        if ($UserInput -match "(?i)$pattern") {
            $isProject = $true
            break
        }
    }

    if ($ToolResults -match "File created: (.+)" -or $ToolResults -match "Directory: (.+?)`n") {
        $isProject = $true
        $projectInfo = $Matches[1]
    }

    if ($isProject -and $WorkingDir) {
        $currentMemory = ""
        try { $currentMemory = Get-PSCoderMemory } catch {}
        $dirName = Split-Path $WorkingDir -Leaf
        if ($currentMemory -notmatch [regex]::Escape($dirName)) {
            $projectNote = "Project directory: $WorkingDir"
            if ($projectInfo) { $projectNote += " - Created: $projectInfo" }
            Add-PSCoderMemoryNote -Note $projectNote
            $decision.shouldSave = $true
            $decision.action = "Added project context to memory"
            $decision.reason = "New project detected: $dirName"
        }
    }

    return $decision
}

function Invoke-CheckSuccessPattern {
    param(
        [string]$ToolResults,
        [string]$AssistantOutput
    )

    $decision = @{
        type = "success_pattern"
        shouldSave = $false
        action = ""
        reason = ""
    }

    if ($ToolResults -match "File (created|edited|overwritten): (.+?)`n") {
        $action = $Matches[1]
        $filePath = $Matches[2]

        $notableExtensions = @(".ps1", ".psm1", ".psd1", ".json", ".yaml", ".yml", ".md", ".cs", ".py", ".js", ".ts", ".html", ".css")
        $isNotable = $false
        foreach ($ext in $notableExtensions) {
            if ($filePath -match [regex]::Escape($ext)) {
                $isNotable = $true
                break
            }
        }

        if ($isNotable) {
            Add-Learning -Category "success_pattern" -Problem "File ${action}: $filePath" -Solution "Completed successfully" -Context $AssistantOutput.Substring(0, [Math]::Min(200, $AssistantOutput.Length))
            $decision.shouldSave = $true
            $decision.action = "Recorded file $action pattern"
            $decision.reason = "$filePath $action"
        }
    }

    return $decision
}

function Invoke-CheckCommandPattern {
    param(
        [string]$UserInput,
        [string]$ToolResults
    )

    $decision = @{
        type = "command_pattern"
        shouldSave = $false
        action = ""
        reason = ""
    }

    $isNewCommand = $false
    foreach ($pattern in $Script:MemoryFilters.NewCommandPatterns) {
        if ($UserInput -match "(?i)$pattern") {
            $isNewCommand = $true
            break
        }
    }

    if ($isNewCommand -and $ToolResults -match "(command executed|output|result)") {
        if ($ToolResults -notmatch "ERROR") {
            $cmdContext = $UserInput.Substring(0, [Math]::Min(100, $UserInput.Length))
            Add-Learning -Category "command_workflow" -Problem $cmdContext -Solution "Executed successfully"
            $decision.shouldSave = $true
            $decision.action = "Recorded command workflow pattern"
            $decision.reason = "New workflow: $cmdContext"
        }
    }

    return $decision
}
