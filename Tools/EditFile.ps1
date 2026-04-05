# EditFile.ps1 - Tool: edit_file
# Replaces text in an existing file

function Invoke-ToolEditFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OldText,
        [Parameter(Mandatory)][string]$NewText,
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Path) { return "ERROR: No path provided" }
    if (-not [System.IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $WorkingDir $Path }
    if (-not (Test-Path $Path)) { return "ERROR: File does not exist: $Path" }
    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        if ($content -notmatch [regex]::Escape($OldText)) {
            return "ERROR: Text to replace not found in $Path"
        }
        $newContent = $content.Replace($OldText, $NewText)
        Set-Content -Path $Path -Value $newContent -Encoding UTF8
        return "File edited: $Path (text replaced)"
    } catch { return "ERROR editing file: $($_.Exception.Message)" }
}
