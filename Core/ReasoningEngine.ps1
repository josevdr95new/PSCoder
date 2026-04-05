# ReasoningEngine.ps1 - Step-by-step reasoning, planning, and verification system
# Coordinates existing systems (AutoHeal, Memory, Tools) into a structured workflow
# Phases: Plan -> Execute with Verification -> Deliver -> Auto-Memory

$Script:ReasoningPlans = @{}
$Script:CurrentPlanId = $null
$Script:ReasoningDir = Join-Path $HOME ".pscoder\reasoning"
$Script:PlanHistory = @()

function Initialize-ReasoningEngine {
    Load-PlanHistory
}

function Load-PlanHistory {
    $historyPath = Join-Path $Script:ReasoningDir "plan_history.json"
    if (Test-Path $historyPath) {
        try {
            $loaded = Get-Content $historyPath -Raw | ConvertFrom-Json
            if ($loaded -is [array]) { $Script:PlanHistory = $loaded }
            else { $Script:PlanHistory = @($loaded) }
        } catch {
            $Script:PlanHistory = @()
        }
    }
}

function Save-PlanHistory {
    $historyPath = Join-Path $Script:ReasoningDir "plan_history.json"
    @($Script:PlanHistory) | ConvertTo-Json -Depth 10 | Set-Content -Path $historyPath -Encoding UTF8
}

function Invoke-CreatePlan {
    param(
        [Parameter(Mandatory)][string]$Task,
        [string]$Context = "",
        [array]$Steps = @()
    )

    $planId = [guid]::NewGuid().ToString().Substring(0, 8)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $similarPlan = Find-SimilarPlan -Task $Task
    if ($similarPlan) {
        $result = "SIMILAR PLAN FOUND IN HISTORY`n"
        $result += "=" * 50 + "`n"
        $result += "Previous plan ID: $($similarPlan.id)`n"
        $result += "Original task: $($similarPlan.task)`n"
        $result += "Status: $($similarPlan.status)`n"
        $result += "Steps completed: $($similarPlan.completedSteps)/$($similarPlan.totalSteps)`n"
        $result += "`nYou can reuse this plan or create a new one.`n"
        $result += "To reuse: reference plan ID $($similarPlan.id)`n"
        return $result
    }

    $previousSolutions = ""
    $taskWords = $Task -split '\s+' | Where-Object { $_.Length -gt 3 }
    foreach ($word in $taskWords) {
        $sol = Find-Solution -Problem $word
        if ($sol.found) {
            $previousSolutions += "- Known solution for '$word': $($sol.solution)`n"
        }
    }

    # If steps were provided, add them to the plan
    $planSteps = @()
    $stepNum = 1
    foreach ($s in $Steps) {
        $planSteps += @{
            number = $stepNum
            description = $s.description
            suggestedTool = if ($s.tool) { $s.tool } else { "" }
            toolValid = $true
            alternativeTool = if ($s.alternative) { $s.alternative } else { "" }
            altValid = $true
            successCriteria = if ($s.successCriteria) { $s.successCriteria } else { "" }
            status = "pending"
            result = ""
            executedAt = ""
            error = ""
            attempts = 0
        }
        $stepNum++
    }

    $plan = @{
        id = $planId
        task = $Task
        context = $Context
        createdAt = $timestamp
        status = "planning"
        steps = $planSteps
        completedSteps = 0
        totalSteps = $planSteps.Count
        failedSteps = 0
        alternativesUsed = 0
        toolsUsed = @()
        errors = @()
        learnings = @()
    }

    $Script:ReasoningPlans[$planId] = $plan
    $Script:CurrentPlanId = $planId

    $result = "PLAN CREATED: $planId`n"
    $result += "=" * 50 + "`n"
    $result += "Task: $Task`n"
    if ($Context) { $result += "Context: $Context`n" }
    $result += "Created: $timestamp`n"
    $result += "Status: Ready to execute`n"
    $result += "Steps: $($planSteps.Count)`n"
    if ($previousSolutions) {
        $result += "`nPREVIOUS SOLUTIONS FOUND:`n$previousSolutions"
    }
    if ($planSteps.Count -gt 0) {
        $result += "`nPLAN STEPS:`n"
        foreach ($s in $planSteps) {
            $result += "  Step $($s.number): $($s.description)"
            if ($s.suggestedTool) { $result += " [Tool: $($s.suggestedTool)]" }
            $result += "`n"
        }
        $result += "`nYou can now execute each step and use verify_step after each one.`n"
    } else {
        $result += "`nNo steps defined yet. Use add_plan_step to add steps, or start executing directly.`n"
    }

    return $result
}

function Invoke-AddPlanStep {
    param(
        [string]$PlanId = $Script:CurrentPlanId,
        [Parameter(Mandatory)][string]$Description,
        [string]$Tool = "",
        [string]$SuccessCriteria = "",
        [string]$Alternative = ""
    )

    if (-not $PlanId -or -not $Script:ReasoningPlans.ContainsKey($PlanId)) {
        return "ERROR: Plan not found. Create a plan first."
    }

    $plan = $Script:ReasoningPlans[$PlanId]
    $stepNum = $plan.steps.Count + 1

    $step = @{
        number = $stepNum
        description = $Description
        suggestedTool = $Tool
        toolValid = $true
        alternativeTool = $Alternative
        altValid = $true
        successCriteria = $SuccessCriteria
        status = "pending"
        result = ""
        executedAt = ""
        error = ""
        attempts = 0
    }

    $plan.steps += $step
    $plan.totalSteps = $plan.steps.Count

    $result = "Step $stepNum added: $Description"
    if ($Tool) { $result += " [Tool: $Tool]" }
    return $result
}

function Invoke-VerifyStep {
    param(
        [string]$PlanId = $Script:CurrentPlanId,
        [Parameter(Mandatory)][int]$StepNumber,
        [Parameter(Mandatory)][string]$Result,
        [bool]$Success = $true
    )

    if (-not $PlanId -or -not $Script:ReasoningPlans.ContainsKey($PlanId)) {
        return "ERROR: Plan not found."
    }

    $plan = $Script:ReasoningPlans[$PlanId]
    $step = $plan.steps | Where-Object { $_.number -eq $StepNumber }
    if (-not $step) {
        return "ERROR: Step $StepNumber not found in plan."
    }

    $step.attempts++
    $step.executedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($Success) {
        $criteriaMet = $true
        $criteriaDetail = ""
        if ($step.successCriteria) {
            if ($Result -notmatch $step.successCriteria) {
                $criteriaMet = $false
                $criteriaDetail = "Result does not match success criteria: $($step.successCriteria)"
            }
        }

        if ($criteriaMet) {
            $step.status = "completed"
            $step.result = $Result
            $plan.completedSteps++

            if ($step.suggestedTool -and $plan.toolsUsed -notcontains $step.suggestedTool) {
                $plan.toolsUsed += $step.suggestedTool
            }

            $result = "STEP $StepNumber VERIFIED: SUCCESS`n"
            $result += "-" * 40 + "`n"
            $result += "Description: $($step.description)`n"
            if ($step.suggestedTool) { $result += "Tool used: $($step.suggestedTool)`n" }
            if ($step.successCriteria) { $result += "Criteria: PASSED`n" }
            $result += "Progress: $($plan.completedSteps)/$($plan.totalSteps)`n"

            if ($plan.completedSteps -eq $plan.totalSteps) {
                $plan.status = "completed"
                $result += "`nPLAN COMPLETE: All steps executed successfully.`n"
                $result += Invoke-PlanSummary -PlanId $PlanId
            }

            Save-PlanToHistory -Plan $plan
        } else {
            $step.status = "failed"
            $step.error = $criteriaDetail
            $plan.failedSteps++
            $plan.errors += "Step ${StepNumber}: $criteriaDetail"

            $result = "STEP ${StepNumber}: CRITERIA NOT MET`n"
            $result += "-" * 40 + "`n"
            $result += "Description: $($step.description)`n"
            $result += "Expected: $($step.successCriteria)`n"
            $result += "Got: $Result`n"

            if ($step.alternativeTool -and $step.altValid) {
                $result += "`nAlternative tool available: $($step.alternativeTool)`n"
                $result += "Consider retrying with alternative.`n"
            }

            $result += "`nTip: Use auto_heal to analyze and find a fix.`n"
        }
    } else {
        $step.status = "failed"
        $step.error = $Result
        $step.result = $Result
        $plan.failedSteps++
        $plan.errors += "Step ${StepNumber}: $Result"

        $result = "STEP ${StepNumber}: FAILED`n"
        $result += "-" * 40 + "`n"
        $result += "Description: $($step.description)`n"
        $result += "Error: $Result`n"

        $healResult = Invoke-AutoHeal -ErrorMessage $Result
        $result += "`nAUTO-HEAL ANALYSIS:`n$healResult`n"

        $prevSol = Find-Solution -Problem $step.description
        if ($prevSol.found) {
            $result += "`nPREVIOUS SOLUTION FOUND:`n  $($prevSol.solution)`n"
        }

        if ($step.alternativeTool -and $step.altValid) {
            $result += "`nAlternative tool: $($step.alternativeTool)`n"
            $plan.alternativesUsed++
            $step.status = "alternative"
        }
    }

    return $result
}

function Invoke-VerifyTask {
    param(
        [string]$PlanId = $Script:CurrentPlanId,
        [string]$ExpectedOutcome = ""
    )

    if (-not $PlanId -or -not $Script:ReasoningPlans.ContainsKey($PlanId)) {
        return "ERROR: Plan not found."
    }

    $plan = $Script:ReasoningPlans[$PlanId]

    $fileChecks = ""
    $allFilesOk = $true

    foreach ($step in $plan.steps) {
        if ($step.result -match "File: (\S+)" -or $step.result -match "created: (\S+)" -or $step.result -match "edited: (\S+)") {
            $filePath = $Matches[1]
            if (Test-Path $filePath) {
                $size = (Get-Item $filePath).Length
                $fileChecks += "  [OK] $filePath ($size bytes)`n"
            } else {
                $fileChecks += "  [FAIL] $filePath (not found)`n"
                $allFilesOk = $false
            }
        }
    }

    $result = "TASK VERIFICATION REPORT`n"
    $result += "=" * 50 + "`n"
    $result += "Task: $($plan.task)`n"
    $result += "Plan ID: $($plan.id)`n"
    $result += "Status: $($plan.status)`n"
    $result += "Steps: $($plan.completedSteps)/$($plan.totalSteps) completed`n"
    if ($plan.failedSteps -gt 0) { $result += "Failed steps: $($plan.failedSteps)`n" }
    if ($plan.alternativesUsed -gt 0) { $result += "Alternatives used: $($plan.alternativesUsed)`n" }
    $result += "Tools used: $($plan.toolsUsed -join ', ')`n"
    $result += "`n"

    if ($fileChecks) {
        $result += "FILE VERIFICATION:`n$fileChecks`n"
    }

    if ($ExpectedOutcome) {
        $allResults = ($plan.steps | ForEach-Object { $_.result }) -join "`n"
        if ($allResults -match $ExpectedOutcome) {
            $result += "OUTCOME: Expected result achieved [OK]`n"
        } else {
            $result += "OUTCOME: Expected result NOT fully achieved [WARNING]`n"
            $result += "Expected pattern: $ExpectedOutcome`n"
        }
    }

    if ($plan.completedSteps -eq $plan.totalSteps -and $allFilesOk) {
        $result += "`nFINAL STATUS: TASK COMPLETED SUCCESSFULLY`n"
    } elseif ($plan.failedSteps -gt 0) {
        $result += "`nFINAL STATUS: TASK COMPLETED WITH ERRORS`n"
        $result += "Review failed steps above for details.`n"
    } else {
        $result += "`nFINAL STATUS: TASK INCOMPLETE`n"
        $result += "$($plan.totalSteps - $plan.completedSteps) steps remaining.`n"
    }

    $result += "`nSTEP SUMMARY:`n"
    foreach ($step in $plan.steps) {
        $icon = switch ($step.status) {
            "completed" { "[OK]" }
            "failed" { "[FAIL]" }
            "alternative" { "[ALT]" }
            "pending" { "[PENDING]" }
            default { "[??]" }
        }
        $result += "  Step $($step.number): $icon $($step.description)`n"
    }

    return $result
}

function Invoke-PlanSummary {
    param([string]$PlanId = $Script:CurrentPlanId)

    if (-not $PlanId -or -not $Script:ReasoningPlans.ContainsKey($PlanId)) {
        return ""
    }

    $plan = $Script:ReasoningPlans[$PlanId]
    $result = "`nPLAN SUMMARY: $($plan.id)`n"
    $result += "=" * 50 + "`n"
    $result += "Task: $($plan.task)`n"
    $result += "Completed: $($plan.completedSteps)/$($plan.totalSteps) steps`n"
    $result += "Tools used: $($plan.toolsUsed -join ', ')`n"
    if ($plan.errors.Count -gt 0) {
        $result += "Errors encountered: $($plan.errors.Count)`n"
    }
    $result += "`nAll steps verified and completed.`n"

    return $result
}

function Find-SimilarPlan {
    param([string]$Task)

    $taskWords = $Task.ToLower() -split '\s+' | Where-Object { $_.Length -gt 3 }

    foreach ($historyPlan in $Script:PlanHistory) {
        if ($historyPlan.status -ne "completed") { continue }
        $historyWords = $historyPlan.task.ToLower() -split '\s+' | Where-Object { $_.Length -gt 3 }
        $matchCount = 0
        foreach ($word in $taskWords) {
            if ($historyWords -contains $word) { $matchCount++ }
        }
        if ($matchCount -ge 2 -and $taskWords.Count -gt 0) {
            return $historyPlan
        }
    }

    return $null
}

function Save-PlanToHistory {
    param($Plan)

    $historyEntry = @{
        id = $Plan.id
        task = $Plan.task
        status = $Plan.status
        completedSteps = $Plan.completedSteps
        totalSteps = $Plan.totalSteps
        failedSteps = $Plan.failedSteps
        alternativesUsed = $Plan.alternativesUsed
        toolsUsed = $Plan.toolsUsed
        createdAt = $Plan.createdAt
        completedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $Script:PlanHistory += $historyEntry

    if ($Script:PlanHistory.Count -gt 50) {
        $Script:PlanHistory = $Script:PlanHistory | Select-Object -Last 50
    }

    Save-PlanHistory
}
