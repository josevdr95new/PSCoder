# ExecutePowerShell.ps1 - Tool: execute_powershell
# Executes a PowerShell command or script on the user's local machine
# Runs in a hidden window with a timeout to prevent hanging

function Invoke-ToolExecutePowerShell {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Command) { return "ERROR: No command provided" }

    # Detect expensive operations and add warnings
    $isExpensive = $false
    if ($Command -match '(?i)Get-ChildItem.*-Recurse.*[A-Z]:\\' -or $Command -match '(?i)Get-ChildItem.*-Path\s*"[A-Z]:\\"') {
        $isExpensive = $true
    }

    # Set timeout: 60s for expensive operations, 30s for normal
    $timeoutSec = if ($isExpensive) { 60 } else { 30 }

    try {
        $tmpFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $outFile = [System.IO.Path]::GetTempFileName() + ".out"
        $errFile = [System.IO.Path]::GetTempFileName() + ".err"

        # Wrap command with timeout and output capture
        $wrapper = @"
`$ErrorActionPreference = 'Continue'
`$OutputEncoding = [System.Text.Encoding]::UTF8
try {
    `$result = & { $Command } 2>&1
    if (`$result) {
        `$result | Out-String -Width 200 | Out-File -FilePath '$outFile' -Encoding UTF8 -Force
    }
} catch {
    `$_.Exception.Message | Out-File -FilePath '$errFile' -Encoding UTF8 -Force
}
"@
        Set-Content -Path $tmpFile -Value $wrapper -Encoding UTF8

        $psExe = Join-Path $PSHOME "powershell.exe"
        if (-not (Test-Path $psExe)) { $psExe = "powershell" }

        $procArgs = @{
            FilePath = $psExe
            ArgumentList = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tmpFile`""
            WindowStyle = "Hidden"
            PassThru = $true
        }
        $proc = Start-Process @procArgs

        # Wait with timeout
        $finished = $proc.WaitForExit($timeoutSec * 1000)

        if (-not $finished) {
            # Timeout - kill the process
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            Remove-Item $outFile -Force -ErrorAction SilentlyContinue
            Remove-Item $errFile -Force -ErrorAction SilentlyContinue
            return "TIMEOUT: Command exceeded ${timeoutSec}s limit. The operation may be too expensive (e.g., scanning entire drive). Try a more specific path or use -Depth instead of -Recurse."
        }

        # Read output
        $output = ""
        if (Test-Path $outFile) {
            $output = Get-Content -Path $outFile -Raw -Encoding UTF8
            Remove-Item $outFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $errFile) {
            $errContent = Get-Content -Path $errFile -Raw -Encoding UTF8
            if ($errContent.Trim()) {
                $output += "`nSTDERR: $errContent"
            }
            Remove-Item $errFile -Force -ErrorAction SilentlyContinue
        }

        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue

        if ($output -and $output.Trim()) {
            # Truncate very large output
            if ($output.Length -gt 10000) {
                $output = $output.Substring(0, 10000) + "`n... (output truncated, $($output.Length) chars total)"
            }
            return $output.Trim()
        } elseif ($proc.ExitCode -ne 0) {
            return "(command exited with code $($proc.ExitCode), no output)"
        } else {
            return "(command executed with no output)"
        }
    } catch { return "ERROR: $($_.Exception.Message)" }
}
