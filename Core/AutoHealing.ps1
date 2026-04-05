# AutoHealing.ps1 - Self-repair system for PSCoder with smart error recovery

$Script:ErrorLog = @()
$Script:HealingDir = Join-Path $HOME ".pscoder\healing"

function Initialize-AutoHealing {
    $Script:ErrorLog = @()
}

function Invoke-AutoHeal {
    param(
        [Parameter(Mandatory)][string]$ErrorMessage,
        [string]$Command = "",
        [string]$Context = ""
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorType = "unknown"
    $suggestion = ""
    $fix = ""
    $alternatives = @()
    $severity = "low"

    if ($ErrorMessage -match "no se reconoce|not recognized|command not found") {
        $errorType = "command_not_found"
        $severity = "medium"
        $suggestion = "Command not found. Check spelling or install the module."
        $fix = "Get-Command *$($Command.Split(' ')[0])* | Select-Object Name"
        $alternatives = @(
            "Try: Get-Command to find similar commands",
            "Try: Install-Module if not installed",
            "Try: Add path to `$env:PATH if custom location"
        )
    }
    elseif ($ErrorMessage -match "no se encuentra|file not found|cannot find") {
        $errorType = "file_not_found"
        $severity = "medium"
        $suggestion = "File or path does not exist."
        $fix = "Test-Path '$Command'"
        $alternatives = @(
            "Try: Check current directory with Get-Location",
            "Try: Use absolute path instead of relative",
            "Try: Use glob_files to find the file"
        )
    }
    elseif ($ErrorMessage -match "acceso denegado|access denied|permission|unauthorized") {
        $errorType = "permission_denied"
        $severity = "high"
        $suggestion = "No permissions. Run as administrator."
        $alternatives = @(
            "Try: Run PowerShell as Administrator",
            "Try: Change file permissions with icacls",
            "Try: Use a different output location"
        )
    }
    elseif ($ErrorMessage -match "timeout|tiempo de espera") {
        $errorType = "timeout"
        $severity = "low"
        $suggestion = "Operation timed out."
        $alternatives = @(
            "Try: Increase timeout value",
            "Try: Run again (temporary network issue)",
            "Try: Check internet connection"
        )
    }
    elseif ($ErrorMessage -match "api|401|403|forbidden") {
        $errorType = "api_error"
        $severity = "high"
        $suggestion = "API error. Check API key and quota."
        $alternatives = @(
            "Try: Verify API key with '/config apiKey'",
            "Try: Switch provider with '/provider groq'",
            "Try: Check API quota at openrouter.ai"
        )
    }
    elseif ($ErrorMessage -match "network|conexion|connection|dns") {
        $errorType = "network_error"
        $severity = "medium"
        $suggestion = "Network error. Check connection."
        $fix = "Test-Connection 8.8.8.8 -Count 1 -Quiet"
        $alternatives = @(
            "Try: Test-Connection 8.8.8.8",
            "Try: Check firewall settings",
            "Try: Use offline tools instead"
        )
    }
    elseif ($ErrorMessage -match "json|convert|parse") {
        $errorType = "parse_error"
        $severity = "medium"
        $suggestion = "Failed to parse data. Check format."
        $alternatives = @(
            "Try: Validate JSON format",
            "Try: Use read_file to check raw content",
            "Try: Handle as plain text instead"
        )
    }
    else {
        $errorType = "unknown"
        $severity = "low"
        $suggestion = "Unknown error. Check the message."
        $alternatives = @(
            "Try: Re-run the command",
            "Try: Check error message for details",
            "Try: Use auto_heal for more analysis"
        )
    }

    # Log with max size limit (keep last 100 entries)
    $Script:ErrorLog += [PSCustomObject]@{
        timestamp = $timestamp
        type = $errorType
        severity = $severity
        message = $ErrorMessage
        command = $Command
        suggestion = $suggestion
        fix = $fix
        alternatives = $alternatives
    }
    if ($Script:ErrorLog.Count -gt 100) {
        $Script:ErrorLog = $Script:ErrorLog[-100..-1]
    }

    $result = "ERROR ANALYSIS`n"
    $result += "=" * 50 + "`n"
    $result += "Type: $errorType`n"
    $result += "Severity: $severity`n"
    $result += "Message: $ErrorMessage`n"
    $result += "Suggestion: $suggestion`n"
    if ($fix) {
        $result += "Quick fix: $fix`n"
    }
    if ($alternatives.Count -gt 0) {
        $result += "`nAlternative approaches:`n"
        $i = 1
        foreach ($alt in $alternatives) {
            $result += "  $i. $alt`n"
            $i++
        }
    }

    # Try to find previous solution
    $prevSolution = Find-Solution -Problem $errorType
    if ($prevSolution.found) {
        $result += "`nPrevious solution found:`n"
        $result += "  $($prevSolution.solution)`n"
    }

    return $result
}
