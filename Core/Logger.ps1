# Logger.ps1 - Logging system for PSCoder

$Script:LogLevels = @{ DEBUG = 0; INFO = 1; WARN = 2; ERROR = 3 }
$Script:CurrentLogLevel = $Script:LogLevels.INFO
$Script:LogFile = Join-Path $HOME ".pscoder\pscoder.log"

function Write-PSCoderLog {
    param(
        [Parameter(Mandatory)][string]$Level,
        [Parameter(Mandatory)][string]$Message,
        [string]$Source = ""
    )

    if ($Script:LogLevels[$Level] -lt $Script:CurrentLogLevel) { return }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level]"
    if ($Source) { $logEntry += " [$Source]" }
    $logEntry += " $Message"

    try {
        Add-Content -Path $Script:LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    } catch {
        # Log write failed - write to stderr as last resort
        [Console]::Error.WriteLine("PSCoder log write failed: $($_.Exception.Message)")
    }
}

function Set-PSCoderLogLevel {
    param([string]$Level = "INFO")
    if ($Script:LogLevels.ContainsKey($Level.ToUpper())) {
        $Script:CurrentLogLevel = $Script:LogLevels[$Level.ToUpper()]
    }
}

function Clear-PSCoderLog {
    if (Test-Path $Script:LogFile) {
        Clear-Content -Path $Script:LogFile -ErrorAction SilentlyContinue
    }
}

function Get-PSCoderLog {
    param([int]$Last = 50)
    if (-not (Test-Path $Script:LogFile)) { return "No log file found." }
    Get-Content $Script:LogFile -Tail $Last
}
