# ReadFile.ps1 - Tool: read_file
# Reads the content of a file

function Invoke-ToolReadFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Path) { return "ERROR: No path provided" }
    if (-not [System.IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $WorkingDir $Path }
    if (-not (Test-Path $Path)) { return "ERROR: File does not exist: $Path" }
    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        $lines = ($content -split "`n").Count
        $size = (Get-Item $Path).Length
        return "File: $Path ($lines lines, $size bytes)`n---`n$content"
    } catch { return "ERROR reading file: $($_.Exception.Message)" }
}
