# WriteFile.ps1 - Tool: write_file
# Creates or overwrites a file with given content

function Invoke-ToolWriteFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Path) { return "ERROR: No path provided" }
    if (-not [System.IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $WorkingDir $Path }
    $exists = Test-Path $Path
    try {
        $dir = Split-Path $Path -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -Path $Path -Value $Content -Encoding UTF8
        if ($exists) { return "File overwritten: $Path" }
        else { return "File created: $Path" }
    } catch { return "ERROR writing file: $($_.Exception.Message)" }
}
