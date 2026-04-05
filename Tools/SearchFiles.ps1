# SearchFiles.ps1 - Tool: search_files
# Searches for a pattern in files within a directory

function Invoke-ToolSearchFiles {
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [string]$Path = "",
        [string]$FilePattern = "*.*",
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Pattern) { return "ERROR: No pattern provided" }
    if (-not $Path) { $Path = $WorkingDir }
    try {
        $results = Get-ChildItem -Path $Path -Filter $FilePattern -Recurse -File -ErrorAction SilentlyContinue |
            Select-String -Pattern $Pattern -ErrorAction SilentlyContinue | Select-Object -First 50
        if (-not $results) { return "No results for '$Pattern' in $Path" }
        $output = $results | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" }
        return "Found $(@($results).Count) results:`n" + ($output -join "`n")
    } catch { return "ERROR in search: $($_.Exception.Message)" }
}
