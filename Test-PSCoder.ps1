# Test-PSCoder.ps1 - Test suite for PSCoder module
$ErrorActionPreference = "Stop"
$pass = 0
$fail = 0

function Test-Step {
    param([string]$Name, [scriptblock]$Script)
    Write-Host "`n  [TEST] $Name" -ForegroundColor Cyan
    try {
        & $Script
        $script:pass++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    } catch {
        $script:fail++
        Write-Host "  [FAIL] $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Loading PSCoder..." -ForegroundColor Yellow
$modulePath = Join-Path $PSScriptRoot "PSCoder.psd1"
Import-Module $modulePath -Force 2>&1 | Out-Null

# Phase 1: Module Loading
Test-Step "Module loads" {
    $mod = Get-Module PSCoder
    if (-not $mod) { throw "Module not loaded" }
    Write-Host "  Version $($mod.Version)"
}

Test-Step "Config initializes" {
    $config = Get-PSCoderConfig
    if (-not $config.model) { throw "No model in config" }
    Write-Host "  Model: $($config.model)"
}

Test-Step "System prompt generated" {
    $prompt = Get-PSCoderSystemPrompt -WorkingDir "C:\test"
    if ($prompt.Length -lt 1000) { throw "System prompt too short: $($prompt.Length)" }
    if ($prompt -match "Claude|Anthropic") { throw "Contains Claude references" }
    Write-Host "  Length: $($prompt.Length) chars"
}

Test-Step "All tool schemas registered" {
    $schemas = Get-ToolSchemas
    if ($schemas.Count -lt 15) { throw "Too few tools: $($schemas.Count)" }
    Write-Host "  $($schemas.Count) tools registered"
}

# Phase 2: Tool Tests
Test-Step "Web search works" {
    $result = Invoke-WebSearch -Query "PowerShell version" -MaxResults 3
    if ($result.Length -lt 50) { throw "Search returned too little" }
    Write-Host "  Length: $($result.Length) chars"
}

Test-Step "Web fetch works" {
    $result = Invoke-WebFetch -Url "https://jsonplaceholder.typicode.com/posts/1" -MaxChars 500
    if ($result.Length -lt 20) { throw "Fetch returned too little" }
    Write-Host "  OK"
}

Test-Step "File I/O cycle" {
    $testPath = Join-Path $env:TEMP "pscoder_test_$([guid]::NewGuid().ToString().Substring(0,8)).txt"
    $writeResult = Invoke-PSCoderTool -ToolName "write_file" -Arguments @{ path = $testPath; content = "Hello PSCoder" }
    if ($writeResult -notmatch "created") { throw "Write failed" }
    $readResult = Invoke-PSCoderTool -ToolName "read_file" -Arguments @{ path = $testPath }
    if ($readResult -notmatch "Hello PSCoder") { throw "Read failed" }
    Remove-Item $testPath -Force -ErrorAction SilentlyContinue
    Write-Host "  OK"
}

Test-Step "Directory tools" {
    $result = Invoke-PSCoderTool -ToolName "list_directory" -Arguments @{ path = $PSScriptRoot }
    if ($result -notmatch "Directory:") { throw "Directory listing failed" }
    Write-Host "  OK"
}

Test-Step "execute_powershell" {
    $result = Invoke-PSCoderTool -ToolName "execute_powershell" -Arguments @{ command = "Write-Host 'test'" }
    Write-Host "  OK"
}

Test-Step "auto_heal" {
    $result = Invoke-AutoHeal -ErrorMessage "Command not recognized"
    if ($result -notmatch "ERROR ANALYSIS") { throw "Auto-heal failed" }
    Write-Host "  OK"
}

Test-Step "learn/find_solution" {
    Add-Learning -Category "test" -Problem "unique test error xyz" -Solution "test solution"
    $result = Find-Solution -Problem "unique test error xyz"
    if (-not $result.found) { throw "Learning not found" }
    Write-Host "  OK"
}

# Phase 3: Permissions
Test-Step "Safe tools auto-approved" {
    $safeTools = @("web_search", "web_fetch", "create_plan", "list_skills", "read_skill")
    foreach ($tool in $safeTools) {
        if (Test-ToolNeedsApproval -ToolName $tool) { throw "$tool should be auto-approved" }
    }
    Write-Host "  OK"
}

Test-Step "Dangerous commands flagged" {
    if (-not (Test-ToolNeedsApproval -ToolName "execute_powershell" -Arguments @{ command = "Remove-Item -Recurse" })) {
        throw "Remove-Item -Recurse should require approval"
    }
    Write-Host "  OK"
}

# Phase 4: Memory & Cache
Test-Step "Memory system" {
    $mem = Get-PSCoderMemory
    if ($mem.Length -lt 50) { throw "Memory too short" }
    Write-Host "  $($mem.Length) chars"
}

Test-Step "Add memory note" {
    Add-PSCoderMemoryNote -Note "TEST: Verification at $(Get-Date -Format 'HH:mm')"
    $mem = Get-PSCoderMemory
    if ($mem -notmatch "TEST:") { throw "Note not added" }
    Write-Host "  OK"
}

Test-Step "Cache set/get" {
    Set-Cache -Namespace "test" -Key "key1" -Data "cached"
    $result = Get-Cache -Namespace "test" -Key "key1" -TTL ([TimeSpan]::FromMinutes(1))
    if ($result -ne "cached") { throw "Cache mismatch" }
    Write-Host "  OK"
}

# Phase 5: Architecture
Test-Step "ContextBuilder" {
    $context = Build-FullContext -WorkingDir $PSScriptRoot
    if (-not $context.ContainsKey("gitStatus")) { throw "Missing gitStatus" }
    Write-Host "  OK"
}

Test-Step "Hooks system" {
    $log = Get-HookLog
    if ($log -notmatch "Hook|empty") { throw "Hooks not initialized" }
    Write-Host "  OK"
}

Test-Step "Auto-compact" {
    $msgs = @(
        @{ role = "system"; content = "sys" }
    )
    1..10 | ForEach-Object { $msgs += @{ role = "user"; content = "msg $_" }; $msgs += @{ role = "assistant"; content = "reply $_" } }
    $compacted = Invoke-AutoCompact -Messages $msgs -SystemPrompt "sys"
    if ($compacted.Count -ge $msgs.Count) { throw "Compaction failed" }
    Write-Host "  $($msgs.Count) -> $($compacted.Count)"
}

# Phase 6: Main Loop
Test-Step "Start-PSCoder exists" {
    if (-not (Get-Command Start-PSCoder -ErrorAction SilentlyContinue)) { throw "Start-PSCoder not found" }
    Write-Host "  OK"
}

# Phase 7: Slash Commands
Test-Step "Slash commands" {
    $model = [ref]"test"
    $messages = [ref]@()
    $provider = [ref]"openrouter"
    $action = Invoke-SlashCommand -Command "/help" -Model $model -Messages $messages -Provider $provider
    if ($action -ne "continue") { throw "Help command failed" }
    Write-Host "  OK"
}

# Phase 8: Brand Independence
Test-Step "No Claude/Anthropic references" {
    $files = Get-ChildItem -Path $PSScriptRoot -Recurse -Include "*.ps1","*.psd1","*.psm1","*.md","*.json","*.bat" -File | Where-Object { $_.Name -ne "Test-PSCoder.ps1" }
    $found = $false
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "C`laude|Anthropic") {
            Write-Host "  FOUND in $($f.Name)" -ForegroundColor Red
            $found = $true
        }
    }
    if ($found) { throw "References found" }
    Write-Host "  All files clean"
}

# Results
Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  TEST RESULTS" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  Total: $($pass + $fail)" -ForegroundColor White
Write-Host "  Passed: $pass" -ForegroundColor Green
Write-Host "  Failed: $fail" -ForegroundColor Red
Write-Host "=" * 60 -ForegroundColor Cyan
if ($fail -eq 0) {
    Write-Host "  ALL TESTS PASSED" -ForegroundColor Green
} else {
    Write-Host "  SOME TESTS FAILED" -ForegroundColor Red
}
Write-Host "=" * 60 -ForegroundColor Cyan
