# ListDirectory.ps1 - Tool: list_directory
# Lists files and directories in a given path

function Invoke-ToolListDirectory {
    param(
        [string]$Path = "",
        $ShowHidden = $false,
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Path) { $Path = $WorkingDir }
    $showHidden = [bool]$ShowHidden
    try {
        if (-not (Test-Path $Path)) { return "ERROR: Directory does not exist: $Path" }
        $items = Get-ChildItem -Path $Path -Force:$ShowHidden
        if (-not $items) { return "Empty directory: $Path" }
        $output = $items | ForEach-Object {
            $type = if ($_.PSIsContainer) { "DIR" } else { "FILE" }
            $size = if ($_.PSIsContainer) { "" } else { "[{0:N0} KB]" -f ($_.Length / 1KB) }
            $date = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            "  [{0}] {1}  {2}  {3}" -f $type, $_.Name, $size, $date
        }
        return "Directory: $Path`n" + ($output -join "`n")
    } catch { return "ERROR listing directory: $($_.Exception.Message)" }
}

# Tool: get_current_dir
function Invoke-ToolGetCurrentDir {
    param([string]$WorkingDir = (Get-Location).Path)
    return "Current directory: $WorkingDir"
}
