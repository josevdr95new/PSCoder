# Hooks.ps1 - PreToolUse, PostToolUse, Stop hooks for PSCoder
# Inspired by claurst's hook system

$Script:HookScriptsDir = Join-Path $HOME ".pscoder\hooks"
$Script:HookLog = @()

function Initialize-Hooks {
    # Create default hook examples if none exist
    $preToolFile = Join-Path $Script:HookScriptsDir "PreToolUse.ps1"
    $postToolFile = Join-Path $Script:HookScriptsDir "PostToolUse.ps1"
    $stopFile = Join-Path $Script:HookScriptsDir "Stop.ps1"

    if (-not (Test-Path $preToolFile)) {
        @"
# PreToolUse hook - runs BEFORE each tool execution
# Return $true to allow, $false to block
# Variables available: `$ToolName, `$ToolInput, `$SessionId

# Example: block dangerous commands
# if (`$ToolName -eq "execute_powershell" -and `$ToolInput.command -match "Remove-Item.*-Recurse") {
#     return $false
# }

return $true
"@ | Set-Content -Path $preToolFile -Encoding UTF8
    }

    if (-not (Test-Path $postToolFile)) {
        @"
# PostToolUse hook - runs AFTER each tool execution
# Variables available: `$ToolName, `$ToolInput, `$ToolOutput, `$IsError, `$SessionId

# Example: log all tool executions
# `$logEntry = "[`$(Get-Date -Format 'HH:mm:ss')] `$ToolName -> `$(if(`$IsError){'ERROR'}else{'OK'})"
# Add-Content -Path "`$env:TEMP\pscoder_hooks.log" -Value `$logEntry

"@ | Set-Content -Path $postToolFile -Encoding UTF8
    }

    if (-not (Test-Path $stopFile)) {
        @"
# Stop hook - runs at the end of each turn
# Variables available: `$AssistantMessage, `$SessionId

# Example: extract key info from conversation
# `$msg = `$AssistantMessage
# if (`$msg -match "IMPORTANT: (.+)") {
#     Add-PSCoderMemoryNote -Note `$Matches[1]
# }

"@ | Set-Content -Path $stopFile -Encoding UTF8
    }
}

function Invoke-PreToolUseHook {
    param(
        [string]$ToolName,
        $ToolInput,
        [string]$SessionId
    )

    $hookFile = Join-Path $Script:HookScriptsDir "PreToolUse.ps1"
    if (-not (Test-Path $hookFile)) { return $true }

    try {
        $result = & $hookFile
        $Script:HookLog += @{
            event = "PreToolUse"
            tool = $ToolName
            result = $result
            timestamp = Get-Date -Format "HH:mm:ss"
        }
        return $result
    } catch {
        Write-PSCoderLog -Level "WARN" -Message "PreToolUse hook failed: $($_.Exception.Message)" -Source "Hooks"
        return $true
    }
}

function Invoke-PostToolUseHook {
    param(
        [string]$ToolName,
        $ToolInput,
        [string]$ToolOutput,
        [bool]$IsError,
        [string]$SessionId
    )

    $hookFile = Join-Path $Script:HookScriptsDir "PostToolUse.ps1"
    if (-not (Test-Path $hookFile)) { return }

    try {
        & $hookFile
        $Script:HookLog += @{
            event = "PostToolUse"
            tool = $ToolName
            isError = $IsError
            timestamp = Get-Date -Format "HH:mm:ss"
        }
    } catch {
        Write-PSCoderLog -Level "WARN" -Message "PostToolUse hook failed: $($_.Exception.Message)" -Source "Hooks"
    }
}

function Invoke-StopHook {
    param(
        [string]$AssistantMessage,
        [string]$SessionId
    )

    $hookFile = Join-Path $Script:HookScriptsDir "Stop.ps1"
    if (-not (Test-Path $hookFile)) { return }

    try {
        & $hookFile
        $Script:HookLog += @{
            event = "Stop"
            timestamp = Get-Date -Format "HH:mm:ss"
        }
    } catch {
        Write-PSCoderLog -Level "WARN" -Message "Stop hook failed: $($_.Exception.Message)" -Source "Hooks"
    }
}

function Get-HookLog {
    param([int]$Last = 20)
    if ($Script:HookLog.Count -eq 0) { return "No hook executions logged." }
    $result = "HOOK LOG`n"
    $result += "=" * 50 + "`n"
    foreach ($entry in ($Script:HookLog | Select-Object -Last $Last)) {
        $result += "[$($entry.timestamp)] $($entry.event): $($entry.tool) -> $(if($entry.result -eq $false){'BLOCKED'}elseif($entry.isError){'ERROR'}else{'OK'})`n"
    }
    return $result
}

function Clear-HookLog {
    $Script:HookLog = @()
}
