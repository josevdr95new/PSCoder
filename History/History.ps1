# History.ps1 - Session history management for PSCoder
# Enhanced with: tags, cost tracking, token counts, branching (from claurst)

function Get-PSCoderSessionsDir {
    $config = Get-PSCoderConfig
    $dir = $config.historyDir
    if (-not $dir) { $dir = Join-Path $HOME ".pscoder\Sessions" }
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Save-PSCoderSession {
    param(
        [array]$Messages,
        [string]$Model,
        [string]$Provider = "",
        [int]$TotalTokens = 0,
        [double]$TotalCost = 0.0,
        [string]$WorkingDir = "",
        [array]$Tags = @(),
        [string]$BranchFrom = ""
    )
    $dir = Get-PSCoderSessionsDir
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $sessionId = [guid]::NewGuid().ToString().Substring(0, 8)
    $filename = "${timestamp}_${sessionId}.json"
    $filepath = Join-Path $dir $filename

    $firstUserMsg = $Messages | Where-Object { $_.role -eq "user" } | Select-Object -First 1
    $summary = if ($firstUserMsg) { $firstUserMsg.content.Substring(0, [Math]::Min(80, $firstUserMsg.content.Length)) } else { "Untitled session" }

    $session = @{
        id              = $sessionId
        timestamp       = (Get-Date -Format "o")
        model           = $Model
        provider        = $Provider
        summary         = $summary
        messageCount    = $Messages.Count
        workingDir      = $WorkingDir
        totalTokens     = $TotalTokens
        totalCost       = $TotalCost
        tags            = $Tags
        branchFrom      = $BranchFrom
        messages        = $Messages
    }

    $session | ConvertTo-Json -Depth 20 | Set-Content -Path $filepath -Encoding UTF8
    Write-InfoPS "Session saved: $filename ($($session.messageCount) msgs, $TotalTokens tokens)"
}

function Show-SessionHistory {
    $dir = Get-PSCoderSessionsDir
    $sessions = Get-ChildItem -Path $dir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 20
    if (-not $sessions) {
        Write-InfoPS "No saved sessions."
        return
    }
    Write-HeaderPS "Recent sessions"
    foreach ($s in $sessions) {
        try {
            $data = Get-Content $s.FullName -Raw | ConvertFrom-Json
            $id = $data.id
            $model = $data.model
            $summary = $data.summary
            $msgCount = $data.messageCount
            $tokens = if ($data.totalTokens) { "$($data.totalTokens) tok" } else { "" }
            $cost = if ($data.totalCost -gt 0) { "Cost: `${0:N4}" -f $data.totalCost } else { "" }
            $tags = if ($data.tags -and $data.tags.Count -gt 0) { "[$($data.tags -join ', ')]" } else { "" }

            $meta = @($tokens, $cost, $tags) | Where-Object { $_ }
            $metaStr = if ($meta.Count -gt 0) { " ($($meta -join ' | '))" } else { "" }

            Write-Host "  [$id] " -NoNewline -ForegroundColor Yellow
            Write-Host "$model " -NoNewline -ForegroundColor Blue
            Write-Host "($msgCount msgs)$metaStr " -NoNewline -ForegroundColor DarkGray
            Write-Host "- $summary" -ForegroundColor Gray
        } catch {
            Write-Host "  [error] $($s.Name)" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-InfoPS "Use /load <id> to load a session."
}

function Load-PSCoderSession {
    param([string]$SessionId, [ref]$Messages)
    $dir = Get-PSCoderSessionsDir
    $files = Get-ChildItem -Path $dir -Filter "*.json" | Where-Object { $_.BaseName -match "_$SessionId$" }
    if (-not $files) {
        Write-ErrorPS "Session not found: $SessionId"
        return
    }
    $file = $files | Select-Object -First 1
    try {
        $json = Get-Content $file.FullName -Raw
        $data = ($json | ConvertFrom-Json) | Convert-PSObjectToHashtable
        $Messages.Value = $data.messages
        $summary = $data.summary
        $msgCount = $data.messageCount
        $tokens = if ($data.totalTokens) { "$($data.totalTokens) tokens" } else { "" }
        $cost = if ($data.totalCost -gt 0) { "Cost: `${0:N4}" -f $data.totalCost } else { "" }
        Write-InfoPS "Session loaded: $summary ($msgCount messages, $tokens, $cost)"
    } catch {
        Write-ErrorPS "Error loading session: $($_.Exception.Message)"
    }
}
