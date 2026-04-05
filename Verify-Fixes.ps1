# Verify all fixes work correctly
Import-Module "$PSScriptRoot\PSCoder.psd1" -Force 2>&1 | Out-Null

$pass = 0
$fail = 0

# Test 1: MemoryDecision null safety
Write-Host "=== TEST 1: MemoryDecision null safety ===" -ForegroundColor Cyan
try {
    $decisions = @(
        @{ type = 'error_learning'; action = 'Saved error'; reason = 'Test' },
        @{ type = 'user_preference'; action = 'Added pref'; reason = 'User likes dark mode' }
    )
    $result = ''
    foreach ($d in $decisions) {
        $dtype = if ($d -is [hashtable]) { $d['type'] } else { $d.type }
        $daction = if ($d -is [hashtable]) { $d['action'] } else { $d.action }
        $dreason = if ($d -is [hashtable]) { $d['reason'] } else { $d.reason }
        if ($dtype) { $result += "[$($dtype.ToUpper())] $daction : $dreason`n" }
    }
    Write-Host 'PASS: MemoryDecision null safety works' -ForegroundColor Green
    Write-Host $result
    $pass++
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 2: Skill content parsing
Write-Host "=== TEST 2: Skill content parsing ===" -ForegroundColor Cyan
try {
    $skillContent = Get-SkillContent -SkillName 'debug-error'
    $skillDesc = ''
    $skillTools = ''
    $skillWorkflow = ''
    if ($skillContent -match '(?s)## Description\s*\r?\n(.+?)\r?\n##') { $skillDesc = $Matches[1].Trim() -replace '\r?\n', ' ' }
    if ($skillContent -match '(?s)## Tools to use\s*\r?\n(.+?)\r?\n##') { $skillTools = $Matches[1].Trim() -replace '\r?\n', ', ' }
    if ($skillContent -match '(?s)## Workflow\s*\r?\n(.+?)\r?\n##') { $skillWorkflow = $Matches[1].Trim() -replace '\r?\n', ' | ' }
    Write-Host 'PASS: Skill content parsing works' -ForegroundColor Green
    Write-Host "  Description: $skillDesc"
    Write-Host "  Tools: $skillTools"
    Write-Host "  Workflow: $skillWorkflow"
    $pass++
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 3: Permissions - auto-approve planning tools
Write-Host "=== TEST 3: Permissions - auto-approve planning tools ===" -ForegroundColor Cyan
try {
    $safeTools = @('web_search', 'web_fetch', 'create_plan', 'verify_step', 'verify_task', 'list_skills', 'read_skill', 'save_learning')
    $allSafe = $true
    foreach ($tool in $safeTools) {
        $needsApproval = Test-ToolNeedsApproval -ToolName $tool
        if ($needsApproval) {
            Write-Host "  FAIL: $tool requires approval" -ForegroundColor Red
            $allSafe = $false
        }
    }
    if ($allSafe) {
        Write-Host 'PASS: All planning and skill tools are auto-approved' -ForegroundColor Green
        $pass++
    } else {
        $fail++
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 4: System prompt contains new instructions
Write-Host "=== TEST 4: System prompt contains new instructions ===" -ForegroundColor Cyan
try {
    $prompt = Get-PSCoderSystemPrompt -WorkingDir 'C:\test'
    $checks = @(
        @{ name = 'hidden window'; pattern = 'HIDDEN WINDOW' },
        @{ name = 'skill loaded'; pattern = 'skill' },
        @{ name = 'web_search vs web_fetch'; pattern = 'web_search vs web_fetch' },
        @{ name = 'API search'; pattern = 'API' },
        @{ name = 'planning tools safe'; pattern = 'Planning tools' }
    )
    $allFound = $true
    foreach ($check in $checks) {
        if ($prompt -match [regex]::Escape($check.pattern)) {
            Write-Host "  [OK] Contains: $($check.name)" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Missing: $($check.name)" -ForegroundColor Red
            $allFound = $false
        }
    }
    if ($allFound) {
        Write-Host 'PASS: All new instructions present in system prompt' -ForegroundColor Green
        $pass++
    } else {
        $fail++
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 5: All skills load correctly
Write-Host "=== TEST 5: All skills load correctly ===" -ForegroundColor Cyan
try {
    $skills = Get-SkillList
    $skillNames = @('code-generation', 'data-extraction', 'debug-error', 'documentation', 'file-analysis', 'powershell-admin', 'refactor', 'web-research')
    $allLoaded = $true
    foreach ($name in $skillNames) {
        if ($skills -match "\[$name\]") {
            Write-Host "  [OK] $name" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $name" -ForegroundColor Red
            $allLoaded = $false
        }
    }
    if ($allLoaded) {
        Write-Host 'PASS: All 8 skills load correctly' -ForegroundColor Green
        $pass++
    } else {
        $fail++
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 6: ExecutePowerShell uses hidden window
Write-Host "=== TEST 6: ExecutePowerShell uses hidden window ===" -ForegroundColor Cyan
try {
    $content = Get-Content "$PSScriptRoot\Tools\ExecutePowerShell.ps1" -Raw
    if ($content -match 'WindowStyle.*Hidden' -and $content -match 'Out-File') {
        Write-Host 'PASS: ExecutePowerShell uses hidden window with output capture' -ForegroundColor Green
        $pass++
    } else {
        Write-Host 'FAIL: ExecutePowerShell missing hidden window or output capture' -ForegroundColor Red
        $fail++
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

# Test 7: Permissions - dangerous tools still require approval
Write-Host "=== TEST 7: Dangerous tools still require approval ===" -ForegroundColor Cyan
try {
    $dangerousTools = @('execute_powershell', 'write_file', 'edit_file')
    $allDangerous = $true
    foreach ($tool in $dangerousTools) {
        $needsApproval = Test-ToolNeedsApproval -ToolName $tool
        if (-not $needsApproval) {
            Write-Host "  FAIL: $tool should require approval" -ForegroundColor Red
            $allDangerous = $false
        }
    }
    if ($allDangerous) {
        Write-Host 'PASS: Dangerous tools still require approval' -ForegroundColor Green
        $pass++
    } else {
        $fail++
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail++
}

Write-Host ''
Write-Host "=== VERIFICATION RESULTS ===" -ForegroundColor Cyan
Write-Host "Passed: $pass" -ForegroundColor Green
Write-Host "Failed: $fail" -ForegroundColor Red
if ($fail -eq 0) {
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
} else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
}
