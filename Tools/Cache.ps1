# Cache.ps1 - Unified caching system for PSCoder

$Script:PSCoderCache = @{}
$Script:PSCoderCacheDir = Join-Path $HOME ".pscoder\cache"

function Initialize-Cache {
    # Cache directory created by Init.ps1
}

function Get-Cache {
    param(
        [Parameter(Mandatory)][string]$Namespace,
        [Parameter(Mandatory)][string]$Key,
        [TimeSpan]$TTL = [TimeSpan]::FromMinutes(10)
    )

    $nsKey = "$Namespace::$Key"
    if (-not $Script:PSCoderCache.ContainsKey($nsKey)) {
        return $null
    }

    $entry = $Script:PSCoderCache[$nsKey]
    $cacheTime = $null
    try {
        $cacheTime = [DateTime]::Parse($entry.timestamp)
    } catch {
        $Script:PSCoderCache.Remove($nsKey)
        return $null
    }
    if ((Get-Date) - $cacheTime -lt $TTL) {
        return $entry.data
    }

    $Script:PSCoderCache.Remove($nsKey)
    $null
}

function Set-Cache {
    param(
        [Parameter(Mandatory)][string]$Namespace,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)]$Data,
        [string]$ContentType = ""
    )

    $nsKey = "$Namespace::$Key"
    $entry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        contentType = $ContentType
        data = $Data
    }
    $Script:PSCoderCache[$nsKey] = $entry

    $safeName = [regex]::Replace($Key.ToLower().Trim(), '[^a-z0-9]', '_')
    if ($safeName.Length -gt 80) { $safeName = $safeName.Substring(0, 80) }
    $nsDir = Join-Path $Script:PSCoderCacheDir $Namespace
    if (-not (Test-Path $nsDir)) {
        New-Item -ItemType Directory -Path $nsDir -Force | Out-Null
    }
    $cacheFile = Join-Path $nsDir "$safeName.json"
    $cacheMeta = @{
        url = $Key
        timestamp = $entry.timestamp
        contentType = $ContentType
        preview = if ($Data -is [string] -and $Data.Length -gt 500) { $Data.Substring(0, 500) } elseif ($Data -is [string]) { $Data } else { "" }
    }
    $cacheMeta | ConvertTo-Json -Depth 3 | Set-Content $cacheFile -Encoding UTF8
}

Initialize-Cache
