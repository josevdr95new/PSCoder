# WebSearch.ps1 - Web search for PSCoder
# Brave Search API (primary) + DuckDuckGo HTML (fallback) + DuckDuckGo Instant Answer (last resort)

$Script:SearchCacheTTL = [TimeSpan]::FromMinutes(5)

function Get-SearchCacheKey {
    param([string]$Query, [int]$MaxResults)
    return "$Query|$MaxResults"
}

# ---------------------------------------------------------------------------
# Brave Search API
# ---------------------------------------------------------------------------
function Search-Brave {
    param(
        [string]$Query,
        [int]$MaxResults = 8,
        [string]$ApiKey
    )

    $encodedQuery = [System.Uri]::EscapeDataString($Query)
    $url = "https://api.search.brave.com/res/v1/web/search?q=$encodedQuery&count=$MaxResults"

    $headers = @{
        "Accept"               = "application/json"
        "Accept-Encoding"      = "gzip"
        "X-Subscription-Token" = $ApiKey
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop

    $results = @()
    $count = 0

    if ($response.web -and $response.web.results) {
        foreach ($r in $response.web.results) {
            if ($count -ge $MaxResults) { break }

            $title = ""
            if ($r.title) { $title = $r.title.Trim() }
            $url = ""
            if ($r.url) { $url = $r.url.Trim() }
            $description = ""
            if ($r.description) { $description = $r.description.Trim() }

            if (-not $title -or $title.Length -lt 3) { continue }
            if (-not $url) { continue }

            $count++
            $results += [PSCustomObject]@{
                position    = $count
                title       = $title
                url         = $url
                description = $description
                content     = ""
                date        = Get-Date -Format "yyyy-MM-dd"
                source      = "Brave Search"
            }
        }
    }

    return $results
}

# ---------------------------------------------------------------------------
# DuckDuckGo HTML search (more reliable than Instant Answer for general queries)
# ---------------------------------------------------------------------------
function Search-DuckDuckGoHtml {
    param(
        [string]$Query,
        [int]$MaxResults = 8
    )

    $userAgents = @(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
    )
    $userAgent = $userAgents | Get-Random

    $headers = @{
        "User-Agent"      = $userAgent
        "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        "Accept-Language" = "en-US,en;q=0.9"
    }

    $encodedQuery = [System.Uri]::EscapeDataString($Query)
    $url = "https://html.duckduckgo.com/html/?q=$encodedQuery"

    $response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop

    if ($response.StatusCode -ne 200 -or $response.Content.Length -lt 1000) {
        return @()
    }

    $html = $response.Content
    $results = @()
    $count = 0
    $seenUrls = @{}

    # Find all result blocks: <a class="result__a" href="...">title</a>
    $titleLinks = [regex]::Matches($html, '<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>(.*?)</a>', 'Singleline,IgnoreCase')

    # Get snippets
    $snippets = [regex]::Matches($html, 'class="result__snippet"[^>]*>(.*?)</(?:td|div)', 'Singleline,IgnoreCase')

    foreach ($tl in $titleLinks) {
        if ($count -ge $MaxResults) { break }

        $rawUrl = $tl.Groups[1].Value
        $title = [regex]::Replace($tl.Groups[2].Value, '<[^>]+>', '')
        try { $title = [System.Web.HttpUtility]::HtmlDecode($title).Trim() } catch { $title = $title.Trim() }

        # Decode DDG redirect URLs (uddg=...)
        $decodedUrl = Decode-DuckDuckGoUrl -RawUrl $rawUrl

        if (-not $title -or $title.Length -lt 3) { continue }
        if (-not $decodedUrl) { continue }
        if ($decodedUrl -match 'duckduckgo\.com') { continue }
        if ($seenUrls.ContainsKey($decodedUrl)) { continue }

        $seenUrls[$decodedUrl] = $true

        # Get matching snippet
        $snippet = ""
        if ($snippets.Count -gt $count) {
            $snippet = [regex]::Replace($snippets[$count].Groups[1].Value, '<[^>]+>', '')
            try { $snippet = [System.Web.HttpUtility]::HtmlDecode($snippet).Trim() } catch { $snippet = $snippet.Trim() }
        }

        $count++
        $results += [PSCustomObject]@{
            position    = $count
            title       = $title
            url         = $decodedUrl
            description = $snippet
            content     = ""
            date        = Get-Date -Format "yyyy-MM-dd"
            source      = "DuckDuckGo"
        }
    }

    return $results
}

function Decode-DuckDuckGoUrl {
    param([string]$RawUrl)

    # DDG redirects look like: //duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com&rut=...
    if ($RawUrl -match 'uddg=(https?%3A%2F%2F[^&]+)') {
        try {
            return [System.Uri]::UnescapeDataString($Matches[1])
        } catch {
            return $RawUrl
        }
    }

    # Direct URL
    if ($RawUrl -match '^https?://') {
        return $RawUrl
    }

    # Protocol-relative
    if ($RawUrl -match '^//') {
        return "https:$RawUrl"
    }

    return $RawUrl
}

# ---------------------------------------------------------------------------
# DuckDuckGo Instant Answer API (no API key, only for well-known entities)
# ---------------------------------------------------------------------------
function Search-DuckDuckGoInstant {
    param(
        [string]$Query,
        [int]$MaxResults = 8
    )

    $encodedQuery = [System.Uri]::EscapeDataString($Query)
    $url = "https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1&skip_disambig=1"

    $headers = @{ "User-Agent" = "PSCoder/1.0" }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop

    $results = @()
    $count = 0

    if ($response.Abstract -and $response.Abstract.Trim().Length -gt 0) {
        $count++
        $results += [PSCustomObject]@{
            position    = $count
            title       = if ($response.Heading) { $response.Heading } else { $Query }
            url         = if ($response.AbstractURL) { $response.AbstractURL } else { "" }
            description = $response.Abstract.Trim()
            content     = $response.Abstract.Trim()
            date        = Get-Date -Format "yyyy-MM-dd"
            source      = "DuckDuckGo Instant Answer"
        }
    }

    if ($response.RelatedTopics) {
        foreach ($topic in $response.RelatedTopics) {
            if ($count -ge $MaxResults) { break }
            if ($topic.Topics) {
                foreach ($sub in $topic.Topics) {
                    if ($count -ge $MaxResults) { break }
                    $text = if ($sub.Text) { $sub.Text.Trim() } else { "" }
                    $firstUrl = if ($sub.FirstURL) { $sub.FirstURL.Trim() } else { "" }
                    if ($text.Length -lt 5) { continue }
                    $count++
                    $results += [PSCustomObject]@{
                        position    = $count
                        title       = $text.Substring(0, [Math]::Min(80, $text.Length))
                        url         = $firstUrl
                        description = $text
                        content     = ""
                        date        = Get-Date -Format "yyyy-MM-dd"
                        source      = "DuckDuckGo"
                    }
                }
                continue
            }
            $text = if ($topic.Text) { $topic.Text.Trim() } else { "" }
            $firstUrl = if ($topic.FirstURL) { $topic.FirstURL.Trim() } else { "" }
            if ($text.Length -lt 5) { continue }
            $count++
            $results += [PSCustomObject]@{
                position    = $count
                title       = $text.Substring(0, [Math]::Min(80, $text.Length))
                url         = $firstUrl
                description = $text
                content     = ""
                date        = Get-Date -Format "yyyy-MM-dd"
                source      = "DuckDuckGo"
            }
        }
    }

    return $results
}

# ---------------------------------------------------------------------------
# Fetch page content - delegates to Clean-HtmlContent from WebFetch.ps1
# ---------------------------------------------------------------------------
function Extract-PageContent {
    param([string]$Html, [int]$MaxChars = 3000)

    if ($Html -match '^[^\x20-\x7E\s]') { return "" }

    try {
        return Clean-HtmlContent -Html $Html -MaxChars $MaxChars
    } catch {
        # Fallback if Clean-HtmlContent is not available
        $text = $Html
        $text = [regex]::Replace($text, '<script[^>]*>.*?</script>', '', 'Singleline,IgnoreCase')
        $text = [regex]::Replace($text, '<style[^>]*>.*?</style>', '', 'Singleline,IgnoreCase')
        $text = [regex]::Replace($text, '<[^>]+>', "`n")
        try { $text = [System.Web.HttpUtility]::HtmlDecode($text) } catch {}
        $text = ($text -split "`n" | Where-Object { $_.Trim().Length -ge 5 }) -join "`n"
        $text = [regex]::Replace($text, "`n{3,}", "`n`n")
        if ($text.Length -gt $MaxChars) { $text = $text.Substring(0, $MaxChars) + "`n... (truncated)" }
        return $text.Trim()
    }
}

# ---------------------------------------------------------------------------
# Main search function
# ---------------------------------------------------------------------------
function Invoke-WebSearch {
    param(
        [Parameter(Mandatory)][string]$Query,
        [int]$MaxResults = 8,
        [int]$FetchTopPages = 2
    )

    $cacheKey = Get-SearchCacheKey -Query $Query -MaxResults $MaxResults
    $cached = Get-Cache -Namespace "search" -Key $cacheKey -TTL $Script:SearchCacheTTL
    if ($cached) {
        return Format-SearchResults -Results $cached.results -Query $Query -Cached $true
    }

    $searchStart = Get-Date
    $results = @()
    $source = ""

    # Step 1: Brave Search API
    $braveKey = $null
    if ($env:BRAVE_SEARCH_API_KEY -and $env:BRAVE_SEARCH_API_KEY.Trim() -ne "") {
        $braveKey = $env:BRAVE_SEARCH_API_KEY.Trim()
    } else {
        try {
            $config = Get-PSCoderConfig
            if ($config.braveSearchApiKey -and $config.braveSearchApiKey.Trim() -ne "") {
                $braveKey = $config.braveSearchApiKey.Trim()
            }
        } catch {}
    }

    if ($braveKey) {
        try {
            $results = Search-Brave -Query $Query -MaxResults $MaxResults -ApiKey $braveKey
            if ($results.Count -gt 0) { $source = "Brave Search" }
        } catch { $results = @() }
    }

    # Step 2: DuckDuckGo HTML search (general queries)
    if ($results.Count -eq 0) {
        try {
            $results = Search-DuckDuckGoHtml -Query $Query -MaxResults $MaxResults
            if ($results.Count -gt 0) { $source = "DuckDuckGo" }
        } catch { $results = @() }
    }

    # Step 3: DuckDuckGo Instant Answer (well-known entities)
    if ($results.Count -eq 0) {
        try {
            $results = Search-DuckDuckGoInstant -Query $Query -MaxResults $MaxResults
            if ($results.Count -gt 0) { $source = "DuckDuckGo Instant Answer" }
        } catch { $results = @() }
    }

    $searchTime = ((Get-Date) - $searchStart).TotalSeconds

    if ($results.Count -eq 0) {
        return "No results found for: `"$Query`".`n`nTry a more specific search or different keywords.`nIf you have a specific URL, use web_fetch instead."
    }

    # Step 4: Fetch content from top pages
    $fetchedCount = 0
    foreach ($r in $results) {
        if ($fetchedCount -ge $FetchTopPages) { break }
        if (-not $r.url -or $r.url.Trim() -eq "") { continue }
        try {
            $pageHeaders = @{
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
                "Accept"     = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            }
            $pageResponse = Invoke-WebRequest -Uri $r.url -Headers $pageHeaders -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            if ($pageResponse.StatusCode -eq 200 -and $pageResponse.Content.Length -gt 100) {
                $content = Extract-PageContent -Html $pageResponse.Content -MaxChars 3000
                if ($content.Length -gt 50) {
                    $r.content = $content
                    $fetchedCount++
                }
            }
        } catch {}
    }

    Set-Cache -Namespace "search" -Key $cacheKey -Data @{ results = $results; count = $results.Count } -ContentType "search"
    return Format-SearchResults -Results $results -Query $Query -SearchTime $searchTime -Source $source
}

# ---------------------------------------------------------------------------
# Format output
# ---------------------------------------------------------------------------
function Format-SearchResults {
    param(
        [object[]]$Results,
        [string]$Query,
        [double]$SearchTime = 0,
        [bool]$Cached = $false,
        [string]$Source = ""
    )

    $output = ""
    $output += "Search Results: `"$Query`"`n"
    $output += "=" * 60 + "`n"
    if ($Cached) { $output += "(cached) " }
    if ($Source) { $output += "Source: $Source | " }
    if ($SearchTime -gt 0) { $output += "Time: $($SearchTime.ToString('F2'))s | " }
    $output += "Found: $($Results.Count) results`n"
    $output += "-" * 60 + "`n"

    foreach ($r in $Results) {
        $output += "`n[$($r.position)] $($r.title)`n"
        $output += "    URL: $($r.url)`n"
        if ($r.description -and $r.description.Trim().Length -gt 0) {
            $output += "    Description: $($r.description)`n"
        }
        if ($r.content -and $r.content.Trim().Length -gt 0) {
            $output += "`n    --- Content ---`n"
            $output += $r.content + "`n"
            $output += "    --- End ---`n"
        }
    }

    return $output
}
