# WebFetch.ps1 - Get URL content for PSCoder
# Supports Markdown for Agents (Cloudflare), HTML cleaning, caching, and content detection
# Markdown for Agents: https://blog.cloudflare.com/markdown-for-agents/
# When sites support it, returns markdown directly (80% token savings!)

$Script:FetchCacheTTL = [TimeSpan]::FromMinutes(10)
$Script:MarkdownCacheTTL = [TimeSpan]::FromMinutes(30)

function Detect-ContentType {
    param([string]$Content, [string]$ContentType = "")
    if ($ContentType -match "application/json") { return "json" }
    if ($ContentType -match "application/xml") { return "xml" }
    if ($ContentType -match "text/xml") { return "xml" }
    if ($ContentType -match "text/markdown") { return "markdown" }
    if ($ContentType -match "text/html") { return "html" }
    if ($ContentType -match "text/plain") { return "text" }
    $trimmed = $Content.TrimStart()
    if ($trimmed.StartsWith("{") -or $trimmed.StartsWith("[")) {
        try { $null = $trimmed | ConvertFrom-Json; return "json" } catch {}
    }
    if ($trimmed.StartsWith("<?xml") -or $trimmed.StartsWith("<rss") -or $trimmed.StartsWith("<feed")) { return "xml" }
    if ($trimmed.StartsWith("<!DOCTYPE") -or $trimmed.StartsWith("<html")) { return "html" }
    if ($trimmed -match "^#{1,6}\s" -and $trimmed -match "\n") { return "markdown" }
    return "text"
}

function Format-Content {
    param([string]$Content, [string]$ContentType, [int]$MaxChars, [int]$Tokens = 0)
    $output = ""
    switch ($ContentType) {
        "json" {
            try {
                $json = $Content | ConvertFrom-Json
                $formatted = $json | ConvertTo-Json -Depth 10
                if ($formatted.Length -gt $MaxChars) { $formatted = $formatted.Substring(0, $MaxChars) + "`n... (truncated)" }
                $output = $formatted
            } catch {
                if ($Content.Length -gt $MaxChars) { $output = $Content.Substring(0, $MaxChars) + "`n... (truncated)" }
                else { $output = $Content }
            }
        }
        "xml" {
            try {
                $xml = [xml]$Content
                $sw = New-Object System.IO.StringWriter
                $writer = New-Object System.Xml.XmlTextWriter($sw)
                $writer.Formatting = [System.Xml.Formatting]::Indented
                $xml.WriteContentTo($writer)
                $writer.Flush()
                $formatted = $sw.ToString()
                if ($formatted.Length -gt $MaxChars) { $formatted = $formatted.Substring(0, $MaxChars) + "`n... (truncated)" }
                $output = $formatted
            } catch {
                if ($Content.Length -gt $MaxChars) { $output = $Content.Substring(0, $MaxChars) + "`n... (truncated)" }
                else { $output = $Content }
            }
        }
        "markdown" {
            if ($Tokens -gt 0) {
                $output += "[Markdown via Cloudflare - ~$Tokens tokens (80% savings vs HTML)]`n`n"
            }
            if ($Content.Length -gt $MaxChars) { $output += $Content.Substring(0, $MaxChars) + "`n... (truncated)" }
            else { $output += $Content }
        }
        "html" {
            $output = Clean-HtmlContent -Html $Content -MaxChars $MaxChars
        }
        default {
            $text = Clean-Text $Content
            if ($text.Length -gt $MaxChars) { $output = $text.Substring(0, $MaxChars) + "`n... (truncated)" }
            else { $output = $text }
        }
    }
    return $output
}

function Invoke-WebFetch {
    param(
        [Parameter(Mandatory)][string]$Url,
        [int]$MaxChars = 15000
    )

    if (-not $Url.StartsWith("http://") -and -not $Url.StartsWith("https://")) {
        $Url = "https://$Url"
    }

    $cached = Get-Cache -Namespace "fetch" -Key $Url -TTL $Script:FetchCacheTTL
    if ($cached -and $cached.content) {
        $formatted = Format-Content -Content $cached.content -ContentType $cached.contentType -MaxChars $MaxChars -Tokens $cached.tokens
        $result = "Fetched (cached): $Url`n"
        $result += "-" * 60 + "`n"
        $result += "Type: $($cached.contentType) | Size: $([Math]::Round($cached.size / 1KB, 1))KB"
        if ($cached.tokens -gt 0) { $result += " | Tokens: ~$($cached.tokens)" }
        $result += "`n" + "-" * 60 + "`n"
        $result += $formatted
        return $result
    }

    # Request markdown first, fallback to HTML
    # This enables Cloudflare's Markdown for Agents: https://blog.cloudflare.com/markdown-for-agents/
    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Accept" = "text/markdown, text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        "Accept-Language" = "en-US,en;q=0.9"
        "Accept-Encoding" = "gzip, deflate, br"
        "Connection" = "keep-alive"
    }

    $fetchStart = Get-Date

    try {
        $response = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5 -ErrorAction Stop
        $content = $response.Content
        $contentType = $response.Headers["Content-Type"]
        $statusCode = [int]$response.StatusCode
        $fetchTime = ((Get-Date) - $fetchStart).TotalSeconds

        # Check for Cloudflare markdown token count header
        $tokenCount = 0
        $tokenHeader = $response.Headers["x-markdown-tokens"]
        if ($tokenHeader) {
            try { $tokenCount = [int]$tokenHeader } catch {}
        }

        $detectedType = Detect-ContentType -Content $content -ContentType $contentType
        $contentSize = $content.Length
        $formatted = Format-Content -Content $content -ContentType $detectedType -MaxChars $MaxChars -Tokens $tokenCount
        Set-Cache -Namespace "fetch" -Key $Url -Data @{ content = $content; contentType = $detectedType; size = $contentSize; tokens = $tokenCount } -ContentType $detectedType

        $result = "Fetched: $Url`n"
        $result += "-" * 60 + "`n"
        $result += "Type: $detectedType | Size: $([Math]::Round($contentSize / 1KB, 1))KB | Time: $($fetchTime.ToString('F2'))s"
        if ($tokenCount -gt 0) {
            $htmlTokens = [Math]::Round($tokenCount * 5)
            $savings = [Math]::Round((1 - ($tokenCount / $htmlTokens)) * 100)
            $result += " | Tokens: ~$tokenCount (saved ~$savings% vs HTML)"
        }
        $result += "`nStatus: $statusCode`n" + "-" * 60 + "`n"
        $result += $formatted
        return $result
    }
    catch {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Encoding = [System.Text.Encoding]::UTF8
            $webClient.Headers.Add("User-Agent", $headers["User-Agent"])
            $webClient.Headers.Add("Accept", $headers["Accept"])
            $webClient.Headers.Add("Accept-Language", $headers["Accept-Language"])
            $content = $webClient.DownloadString($Url)
            $contentType = $webClient.ResponseHeaders["Content-Type"]
            $webClient.Dispose()
            $fetchTime = ((Get-Date) - $fetchStart).TotalSeconds
            $detectedType = Detect-ContentType -Content $content -ContentType $contentType
            $contentSize = $content.Length
            $formatted = Format-Content -Content $content -ContentType $detectedType -MaxChars $MaxChars
            Set-Cache -Namespace "fetch" -Key $Url -Data @{ content = $content; contentType = $detectedType; size = $contentSize; tokens = 0 } -ContentType $detectedType
            $result = "Fetched: $Url`n" + "-" * 60 + "`n"
            $result += "Type: $detectedType | Size: $([Math]::Round($contentSize / 1KB, 1))KB | Time: $($fetchTime.ToString('F2'))s`n"
            $result += "-" * 60 + "`n" + $formatted
            return $result
        }
        catch {
            $errorMsg = $_.Exception.Message
            if ($errorMsg -match "403|Forbidden") { return "Error: Access denied (403). Site blocks automated requests." }
            elseif ($errorMsg -match "404|Not Found") { return "Error: Page not found (404). Check the URL." }
            elseif ($errorMsg -match "timeout|tiempo") { return "Error: Timeout. Site is taking too long to respond." }
            elseif ($errorMsg -match "conexion|connection|DNS") { return "Error: Could not connect. Check your internet connection and URL." }
            else { return "Error fetching URL: $errorMsg" }
        }
    }
}

function Clean-HtmlContent {
    param([string]$Html, [int]$MaxChars)
    $text = $Html
    $text = [regex]::Replace($text, '<script[^>]*>.*?</script>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<style[^>]*>.*?</style>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<header[^>]*>.*?</header>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<footer[^>]*>.*?</footer>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<nav[^>]*>.*?</nav>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<aside[^>]*>.*?</aside>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<form[^>]*>.*?</form>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<button[^>]*>.*?</button>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<input[^>]*>', '', 'IgnoreCase')
    $text = [regex]::Replace($text, '<select[^>]*>.*?</select>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<textarea[^>]*>.*?</textarea>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<iframe[^>]*>.*?</iframe>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<embed[^>]*>', '', 'IgnoreCase')
    $text = [regex]::Replace($text, '<object[^>]*>.*?</object>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<video[^>]*>.*?</video>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<audio[^>]*>.*?</audio>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<canvas[^>]*>.*?</canvas>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<svg[^>]*>.*?</svg>', '', 'Singleline,IgnoreCase')
    $text = [regex]::Replace($text, '<img[^>]*>', '', 'IgnoreCase')
    $text = [regex]::Replace($text, '<!--.*?-->', '', 'Singleline')
    $text = [regex]::Replace($text, '<code[^>]*>', ' [code] ', 'IgnoreCase')
    $text = [regex]::Replace($text, '</code>', ' [/code] ', 'IgnoreCase')
    $text = [regex]::Replace($text, '<pre[^>]*>', "`n[code block]`n", 'IgnoreCase')
    $text = [regex]::Replace($text, '</pre>', "`n[/code block]`n", 'IgnoreCase')
    $blockTags = @('div', 'p', 'br', 'hr', 'li', 'tr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'article', 'section', 'main', 'blockquote', 'dd', 'dt', 'figcaption', 'figure')
    foreach ($tag in $blockTags) {
        $text = [regex]::Replace($text, "</$tag>", "`n", 'IgnoreCase')
        $text = [regex]::Replace($text, "<$tag[^>]*>", "`n", 'IgnoreCase')
    }
    $text = [regex]::Replace($text, '<[^>]+>', ' ')
    try { $text = [System.Web.HttpUtility]::HtmlDecode($text) } catch {}
    $entities = @{
        '&nbsp;' = ' '; '&amp;' = '&'; '&lt;' = '<'; '&gt;' = '>'; '&quot;' = '"'
        '&#39;' = "'"; '&mdash;' = '-'; '&ndash;' = '-'; '&hellip;' = '...'
        '&laquo;' = '<<'; '&raquo;' = '>>'; '&copy;' = '(c)'; '&reg;' = '(R)'
        '&trade;' = '(TM)'; '&#8211;' = '-'; '&#8212;' = '--'; '&#8216;' = "'"
        '&#8217;' = "'"; '&#8220;' = '"'; '&#8221;' = '"'; '&#8230;' = '...'
    }
    foreach ($entity in $entities.GetEnumerator()) {
        $text = $text -replace [regex]::Escape($entity.Key), $entity.Value
    }
    $lines = $text -split "`n"
    $cleanLines = @()
    foreach ($line in $lines) {
        $line = [regex]::Replace($line, '\s+', ' ').Trim()
        if ($line.Length -lt 3) { continue }
        if ($line -match '^[\s\-\*\=\#\@\!\$\%\^\&\(\)\[\]\{\}\<\>\,\.\;\:]+$') { continue }
        $cleanLines += $line
    }
    $text = $cleanLines -join "`n"
    $text = [regex]::Replace($text, "`n{3,}", "`n`n")
    try {
        $text = [regex]::Replace($text, '\\u([0-9a-fA-F]{4})', { param($m); [char][int]::Parse($m.Groups[1].Value, 'HexNumber') })
    } catch {}
    if ($text.Length -gt $MaxChars) { $text = $text.Substring(0, $MaxChars) + "`n... (truncated)" }
    return $text.Trim()
}

function Clean-Text {
    param([string]$Text)
    $text = [System.Web.HttpUtility]::HtmlDecode($Text)
    $text = [regex]::Replace($text, '<[^>]+>', ' ')
    $text = [regex]::Replace($text, '\s+', ' ')
    return $text.Trim()
}

Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
