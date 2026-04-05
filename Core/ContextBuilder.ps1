# ContextBuilder.ps1 - Builds dynamic context for PSCoder
# Discovers project context files and git status

$Script:PSCoderContextCache = @{}
$Script:ContextCacheTTL = [TimeSpan]::FromMinutes(2)

function Build-GitContext {
    param([string]$WorkingDir = (Get-Location).Path)

    $cacheKey = "git::$WorkingDir"
    $cached = Get-ContextCache -Key $cacheKey
    if ($cached) { return $cached }

    $parts = @()

    # Git status
    try {
        $statusOut = & git -C $WorkingDir status --short --branch 2>$null
        if ($statusOut) {
            $statusText = $statusOut -join "`n"
            $parts += "# Git Status`n$statusText"
        }
    } catch {}

    # Recent commits
    try {
        $logOut = & git -C $WorkingDir log --oneline -5 2>$null
        if ($logOut) {
            $logText = $logOut -join "`n"
            $parts += "# Recent Commits`n$logText"
        }
    } catch {}

    $result = ""
    if ($parts.Count -gt 0) {
        $result = $parts -join "`n`n"
    }
    Set-ContextCache -Key $cacheKey -Value $result
    return $result
}

function Build-ProjectMdContext {
    param([string]$WorkingDir = (Get-Location).Path)

    $cacheKey = "projectmd::$WorkingDir"
    $cached = Get-ContextCache -Key $cacheKey
    if ($cached) { return $cached }

    $parts = @()

    # Global ~/.pscoder/PSCODER.md
    $globalMd = Join-Path $HOME ".pscoder\PSCODER.md"
    if (Test-Path $globalMd) {
        try {
            $content = Get-Content -LiteralPath $globalMd -Raw -Encoding UTF8
            if ($content -and $content.Trim().Length -gt 0) {
                $parts += "# Global Context (from $globalMd)`n$content"
            }
        } catch {}
    }

    # Walk up from WorkingDir to root looking for PSCODER.md
    $dir = $WorkingDir
    $projectMds = @()
    $maxDepth = 10
    $depth = 0
    while ($dir -and $depth -lt $maxDepth) {
        $candidate = Join-Path $dir "PSCODER.md"
        if ((Test-Path $candidate) -and ($candidate -ne $globalMd)) {
            try {
                $content = Get-Content -LiteralPath $candidate -Raw -Encoding UTF8
                if ($content -and $content.Trim().Length -gt 0) {
                    $projectMds += "# Project Context (from $candidate)`n$content"
                }
            } catch {}
        }

        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
        $depth++
    }

    # Reverse so outermost directory comes first
    [array]::Reverse($projectMds)
    $parts += $projectMds

    $result = ""
    if ($parts.Count -gt 0) {
        $result = $parts -join "`n`n"
    }
    Set-ContextCache -Key $cacheKey -Value $result
    return $result
}

function Build-FullContext {
    param([string]$WorkingDir = (Get-Location).Path)

    return @{
        gitStatus  = Build-GitContext -WorkingDir $WorkingDir
        projectMd  = Build-ProjectMdContext -WorkingDir $WorkingDir
    }
}

# Cache helpers
function Get-ContextCache {
    param([string]$Key)
    if (-not $Script:PSCoderContextCache.ContainsKey($Key)) { return $null }
    $entry = $Script:PSCoderContextCache[$Key]
    if ((Get-Date) - $entry.cachedAt -lt $Script:ContextCacheTTL) {
        return $entry.value
    }
    $Script:PSCoderContextCache.Remove($Key)
    return $null
}

function Set-ContextCache {
    param([string]$Key, [string]$Value)
    $Script:PSCoderContextCache[$Key] = @{
        value = $Value
        cachedAt = Get-Date
    }
}

function Clear-ContextCache {
    $Script:PSCoderContextCache.Clear()
}
