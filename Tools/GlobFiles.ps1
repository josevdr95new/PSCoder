# GlobFiles.ps1 - Tool: glob_files
# Finds files matching a pattern (supports ** recursive)

function Invoke-ToolGlobFiles {
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [string]$Path = "",
        [string]$WorkingDir = (Get-Location).Path
    )

    if (-not $Pattern) { return "ERROR: No pattern provided" }
    if (-not $Path) { $Path = $WorkingDir }
    try {
        if ($Pattern -match "\*\*") {
            $regexPattern = $Pattern -replace '\*\*/', '(.*/)?' -replace '\*', '[^/\\]*' -replace '\?', '.'
            $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match $regexPattern } | Select-Object -First 100
        } else {
            $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 100
        }
        if (-not $files) { return "No files matching '$Pattern' in $Path" }
        $output = $files | ForEach-Object { $_.FullName }
        return "Found $(@($files).Count) files:`n" + ($output -join "`n")
    } catch { return "ERROR in glob: $($_.Exception.Message)" }
}
