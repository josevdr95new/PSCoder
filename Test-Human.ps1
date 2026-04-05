# Test completo como usuario humano
$ErrorActionPreference = "Stop"
$pass = 0
$fail = 0

function Test-Step {
    param([string]$Name, [scriptblock]$Script)
    Write-Host "`n=== TEST: $Name ===" -ForegroundColor Cyan
    try {
        & $Script
        $script:pass++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    } catch {
        $script:fail++
        Write-Host "  [FAIL] $Name : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Import-Module "$PSScriptRoot\PSCoder.psd1" -Force 2>&1 | Out-Null

# 1. Configuracion
Test-Step "Config loads" {
    $config = Get-PSCoderConfig
    if ($config.model -and $config.provider) {
        Write-Host "  Model: $($config.model)"
        Write-Host "  Provider: $($config.provider)"
    } else { throw "Config missing model/provider" }
}

# 2. Skills - listar
Test-Step "List all skills" {
    $skills = Get-SkillList
    if ($skills -match "AVAILABLE SKILLS") {
        Write-Host "  Skills listed successfully"
    } else { throw "Skills not listed" }
}

# 3. Skills - leer uno
Test-Step "Read skill: debug-error" {
    $content = Get-SkillContent -SkillName "debug-error"
    if ($content -match "## Description" -and $content -match "## Workflow") {
        Write-Host "  Skill content loaded with description and workflow"
    } else { throw "Skill content incomplete" }
}

# 4. Skills - leer otro
Test-Step "Read skill: web-research" {
    $content = Get-SkillContent -SkillName "web-research"
    if ($content -match "## Tools to use" -and $content -match "web_search") {
        Write-Host "  Skill content loaded with tools section"
    } else { throw "Skill content incomplete" }
}

# 5. Memoria - obtener
Test-Step "Get memory" {
    $mem = Get-PSCoderMemory
    if ($mem -and $mem.Length -gt 50) {
        Write-Host "  Memory loaded: $($mem.Length) chars"
    } else { throw "Memory empty or too small" }
}

# 6. Memoria - agregar nota
Test-Step "Add memory note" {
    Add-PSCoderMemoryNote -Note "TEST: Human verification test at $(Get-Date -Format 'HH:mm')"
    $mem = Get-PSCoderMemory
    if ($mem -match "TEST: Human verification") {
        Write-Host "  Note added and verified"
    } else { throw "Note not found in memory" }
}

# 7. MemoryDecision - analisis automatico
Test-Step "MemoryDecision analyzes conversation" {
    $messages = @(
        @{ role = "user"; content = "I prefer using dark theme for my projects" },
        @{ role = "assistant"; content = "Got it, I'll use dark theme." },
        @{ role = "tool"; content = "File created: test.ps1" }
    )
    $result = Invoke-MemoryDecision -Messages $messages -WorkingDir "C:\test\project"
    Write-Host "  Result: $($result.Substring(0, [Math]::Min(100, $result.Length)))"
    if ($result -match "MEMORY DECISIONS|Nothing valuable") {
        Write-Host "  MemoryDecision executed correctly"
    } else { throw "MemoryDecision returned unexpected result" }
}

# 8. Permissions - web tools auto-aprobadas
Test-Step "Web tools auto-approved" {
    $webTools = @("web_search", "web_fetch", "create_plan", "verify_step", "verify_task", "list_skills", "read_skill", "save_learning")
    foreach ($tool in $webTools) {
        $needsApproval = Test-ToolNeedsApproval -ToolName $tool
        if ($needsApproval) { throw "$tool should be auto-approved" }
    }
    Write-Host "  All 8 tools auto-approved"
}

# 9. Permissions - tools peligrosas requieren aprobacion
Test-Step "Dangerous tools require approval" {
    $dangerous = @("execute_powershell", "write_file", "edit_file")
    foreach ($tool in $dangerous) {
        $needsApproval = Test-ToolNeedsApproval -ToolName $tool
        if (-not $needsApproval) { throw "$tool should require approval" }
    }
    Write-Host "  All 3 dangerous tools require approval"
}

# 10. File tools - escribir y leer (via dispatcher como lo haria la IA)
Test-Step "Write and read file" {
    $testPath = Join-Path $env:TEMP "pscoder_test_$(Get-Random).txt"
    $result = Invoke-PSCoderTool -ToolName "write_file" -Arguments @{ path = $testPath; content = "Hello from PSCoder test!" }
    if ($result -match "created") {
        $readResult = Invoke-PSCoderTool -ToolName "read_file" -Arguments @{ path = $testPath }
        if ($readResult -match "Hello from PSCoder test!") {
            Write-Host "  File written and read successfully"
            Remove-Item $testPath -Force -ErrorAction SilentlyContinue
        } else { throw "File content mismatch" }
    } else { throw "File not created" }
}

# 11. File tools - editar (via dispatcher)
Test-Step "Edit file" {
    $testPath = Join-Path $env:TEMP "pscoder_test_edit_$(Get-Random).txt"
    Invoke-PSCoderTool -ToolName "write_file" -Arguments @{ path = $testPath; content = "Hello World" } | Out-Null
    $result = Invoke-PSCoderTool -ToolName "edit_file" -Arguments @{ path = $testPath; oldText = "World"; newText = "PSCoder" }
    if ($result -match "edited") {
        $readResult = Invoke-PSCoderTool -ToolName "read_file" -Arguments @{ path = $testPath }
        if ($readResult -match "Hello PSCoder") {
            Write-Host "  File edited successfully"
            Remove-Item $testPath -Force -ErrorAction SilentlyContinue
        } else { throw "Edit not applied" }
    } else { throw "File not edited" }
}

# 12. Directory tools (via dispatcher)
Test-Step "List directory" {
    $result = Invoke-PSCoderTool -ToolName "list_directory" -Arguments @{ path = $PSScriptRoot }
    if ($result -match "Directory:") {
        Write-Host "  Directory listed successfully"
    } else { throw "Directory listing failed" }
}

# 13. Glob files (via dispatcher)
Test-Step "Glob files" {
    $result = Invoke-PSCoderTool -ToolName "glob_files" -Arguments @{ pattern = "*.ps1"; path = $PSScriptRoot }
    if ($result -match "Found") {
        Write-Host "  Glob found files"
    } else { throw "Glob failed" }
}

# 14. Search files (via dispatcher)
Test-Step "Search files" {
    $result = Invoke-PSCoderTool -ToolName "search_files" -Arguments @{ pattern = "function"; path = $PSScriptRoot; filePattern = "*.ps1" }
    if ($result -match "Found|No results") {
        Write-Host "  Search completed"
    } else { throw "Search failed" }
}

# 15. Execute PowerShell (via dispatcher)
Test-Step "Execute PowerShell" {
    $result = Invoke-PSCoderTool -ToolName "execute_powershell" -Arguments @{ command = "Write-Host 'Hello from PS'" }
    if ($result -match "Hello from PS|no output") {
        Write-Host "  PowerShell executed"
    } else { throw "PowerShell execution failed" }
}

# 16. Auto-heal
Test-Step "Auto-heal analyzes error" {
    $result = Invoke-AutoHeal -ErrorMessage "Command 'Get-Foo' was not recognized"
    if ($result -match "ERROR ANALYSIS" -and $result -match "command_not_found") {
        Write-Host "  Error classified correctly"
    } else { throw "Auto-heal failed" }
}

# 17. Find solution
Test-Step "Find solution (none expected)" {
    $result = Find-Solution -Problem "zzznonexistent999uniqueerror"
    if ($result.found -eq $false) {
        Write-Host "  No solution found (expected)"
    } else { throw "Should not find solution for zzznonexistent999uniqueerror" }
}

# 18. Learn and find
Test-Step "Learn and find solution" {
    Add-Learning -Category "test" -Problem "unique test error abc" -Solution "unique test solution"
    $result = Find-Solution -Problem "unique test error abc"
    if ($result.found -eq $true -and $result.solution -eq "unique test solution") {
        Write-Host "  Learning saved and found"
    } else { throw "Learning not found" }
}

# 19. System prompt
Test-Step "System prompt includes all instructions" {
    $prompt = Get-PSCoderSystemPrompt -WorkingDir "C:\test"
    $checks = @("HIDDEN WINDOW", "web_search vs web_fetch", "list_skills", "create_plan", "Planning tools")
    foreach ($check in $checks) {
        if ($prompt -notmatch [regex]::Escape($check)) {
            throw "Missing: $check"
        }
    }
    Write-Host "  All key instructions present ($($prompt.Length) chars)"
}

# 20. Session save/load
Test-Step "Save and load session" {
    $dir = Get-PSCoderSessionsDir
    $messages = @(
        @{ role = "system"; content = "test" },
        @{ role = "user"; content = "Hello PSCoder" },
        @{ role = "assistant"; content = "Hello!" }
    )
    Save-PSCoderSession -Messages $messages -Model "test-model" -WorkingDir "C:\test" 2>&1 | Out-Null
    
    # Find the latest session
    $files = Get-ChildItem -Path $dir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($files) {
        $data = Get-Content $files.FullName -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
        if ($data.summary -eq "Hello PSCoder") {
            Write-Host "  Session saved and verified"
        } else { throw "Session summary mismatch" }
    } else { throw "No session file found" }
}

# 21. Cache
Test-Step "Cache set and get" {
    Set-Cache -Namespace "test" -Key "mykey" -Data "cached value"
    $result = Get-Cache -Namespace "test" -Key "mykey" -TTL ([TimeSpan]::FromMinutes(1))
    if ($result -eq "cached value") {
        Write-Host "  Cache works"
    } else { throw "Cache mismatch" }
}

# 22. Hooks
Test-Step "Hooks initialized" {
    $hookLog = Get-HookLog
    if ($hookLog -match "Hook log|HOOK|empty") {
        Write-Host "  Hooks system ready"
    } else { throw "Hooks not initialized" }
}

# 23. ContextBuilder
Test-Step "Context builder works" {
    $context = Build-FullContext -WorkingDir $PSScriptRoot
    if ($context.ContainsKey("gitStatus") -and $context.ContainsKey("projectMd")) {
        Write-Host "  Context built successfully"
    } else { throw "Context missing fields" }
}

# 24. Reasoning engine
Test-Step "Create plan" {
    $result = Invoke-CreatePlan -Task "Test plan for verification"
    if ($result -match "PLAN CREATED") {
        Write-Host "  Plan created"
    } else { throw "Plan not created" }
}

# 25. Web search (real)
Test-Step "Web search works (real API)" {
    $result = Invoke-WebSearch -Query "PowerShell version" -MaxResults 3
    if ($result.Length -gt 50) {
        Write-Host "  Search returned $($result.Length) chars"
    } else { throw "Search returned too little" }
}

# 26. Web fetch (real)
Test-Step "Web fetch works (real URL)" {
    $result = Invoke-WebFetch -Url "https://jsonplaceholder.typicode.com/posts/1" -MaxChars 500
    if ($result -match "Fetched|json") {
        Write-Host "  Fetch returned content"
    } else { throw "Fetch failed" }
}

# 27. Tool schemas
Test-Step "All tool schemas registered" {
    $schemas = Get-ToolSchemas
    $expectedTools = @("execute_powershell", "read_file", "write_file", "edit_file", "search_files", "glob_files", "list_directory", "web_search", "web_fetch", "auto_heal", "learn_from_error", "find_solution", "ocr_image", "create_plan", "verify_step", "verify_task", "save_learning", "list_skills", "read_skill")
    $foundNames = $schemas | ForEach-Object { $_.function.name }
    $missing = $expectedTools | Where-Object { $_ -notin $foundNames }
    if ($missing.Count -eq 0) {
        Write-Host "  All 19 tools registered"
    } else { throw "Missing: $($missing -join ', ')" }
}

# 28. Tool dispatcher
Test-Step "Tool dispatcher routes correctly" {
    $result = Invoke-PSCoderTool -ToolName "get_current_dir" -Arguments @{}
    if ($result -match "Current directory") {
        Write-Host "  Dispatcher works"
    } else { throw "Dispatcher failed" }
}

# Results
Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  HUMAN SIMULATION TEST RESULTS" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  Passed: $pass" -ForegroundColor Green
Write-Host "  Failed: $fail" -ForegroundColor Red
Write-Host "=" * 60 -ForegroundColor Cyan
if ($fail -eq 0) {
    Write-Host "  ALL TESTS PASSED - Everything works like a human would use it" -ForegroundColor Green
} else {
    Write-Host "  SOME TESTS FAILED" -ForegroundColor Red
}
Write-Host "=" * 60 -ForegroundColor Cyan
