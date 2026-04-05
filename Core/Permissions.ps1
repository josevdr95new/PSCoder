# Permissions.ps1 - Advanced permission system for PSCoder
# Inspired by claurst's PermissionManager: modes, persistent rules, path matching

$Script:PermissionMode = "Default"
$Script:SessionRules = @()
$Script:PersistentRules = @()
$Script:AlwaysApproved = @{}

# Permission levels for tools
$Script:ToolPermissionLevels = @{
    "read_file"       = "Read"
    "search_files"    = "Read"
    "glob_files"      = "Read"
    "list_directory"  = "Read"
    "get_current_dir" = "Read"
    "web_search"      = "Read"
    "web_fetch"       = "Network"
    "ocr_image"       = "Read"
    "write_file"      = "Write"
    "edit_file"       = "Write"
    "execute_powershell" = "Execute"
    "auto_heal"       = "Read"
    "learn_from_error" = "Read"
    "find_solution"   = "Read"
}

# Safe commands for execute_powershell
$Script:SafeCommands = @(
    "Get-", "Test-", "Measure-", "Select-Object", "Where-Object",
    "Sort-Object", "Out-String", "Write-Host", "echo",
    "ls", "dir", "cat", "type", "pwd", "whoami", "date", "tree", "cls", "clear"
)

function Initialize-Permissions {
    Load-PersistentRules
}

function Load-PersistentRules {
    $rulesFile = Join-Path $HOME ".pscoder\permission_rules.json"
    if (Test-Path $rulesFile) {
        try {
            $loaded = Get-Content $rulesFile -Raw | ConvertFrom-Json
            if ($loaded -is [array]) { $Script:PersistentRules = $loaded }
            else { $Script:PersistentRules = @($loaded) }
        } catch { $Script:PersistentRules = @() }
    }
}

function Save-PersistentRules {
    $rulesFile = Join-Path $HOME ".pscoder\permission_rules.json"
    @($Script:PersistentRules) | ConvertTo-Json -Depth 5 | Set-Content -Path $rulesFile -Encoding UTF8
}

function Get-ToolPermissionLevel {
    param([string]$ToolName)
    if ($Script:ToolPermissionLevels.ContainsKey($ToolName)) {
        return $Script:ToolPermissionLevels[$ToolName]
    }
    return "Execute"
}

function Test-ToolNeedsApproval {
    param(
        [string]$ToolName,
        [hashtable]$Arguments = @{}
    )

    $targetPath = $null
    if ($Arguments.path) { $targetPath = $Arguments.path }
    elseif ($Arguments.url) { $targetPath = $Arguments.url }
    elseif ($Arguments.command) { $targetPath = $Arguments.command }

    $level = Get-ToolPermissionLevel -ToolName $ToolName

    # Step 1: BypassPermissions
    if ($Script:PermissionMode -eq "BypassPermissions") { return $false }

    # Step 2: Check deny rules first (deny beats allow)
    foreach ($rule in $Script:PersistentRules) {
        if ($rule.action -eq "Deny") {
            if (Test-RuleMatch -Rule $rule -ToolName $ToolName -TargetPath $targetPath) {
                return $true
            }
        }
    }
    foreach ($rule in $Script:SessionRules) {
        if ($rule.action -eq "Deny") {
            if (Test-RuleMatch -Rule $rule -ToolName $ToolName -TargetPath $targetPath) {
                return $true
            }
        }
    }

    # Step 3: Check allow rules
    foreach ($rule in $Script:PersistentRules) {
        if ($rule.action -eq "Allow") {
            if (Test-RuleMatch -Rule $rule -ToolName $ToolName -TargetPath $targetPath) {
                return $false
            }
        }
    }
    foreach ($rule in $Script:SessionRules) {
        if ($rule.action -eq "Allow") {
            if (Test-RuleMatch -Rule $rule -ToolName $ToolName -TargetPath $targetPath) {
                return $false
            }
        }
    }

    # Step 3: Web tools are safe - auto-approve (read-only network access)
    if ($ToolName -in @("web_search", "web_fetch")) { return $false }

    # Step 3b: Planning and skill tools are safe - auto-approve (read-only, no side effects)
    if ($ToolName -in @("create_plan", "verify_step", "verify_task", "list_skills", "read_skill", "save_learning")) { return $false }

    # Step 4: AlwaysApproved
    if ($Script:AlwaysApproved.ContainsKey($ToolName)) { return $false }

    # Step 5: AcceptEdits mode
    if ($Script:PermissionMode -eq "AcceptEdits") { return $false }

    # Step 6: Plan mode - reads only
    if ($Script:PermissionMode -eq "Plan") {
        return ($level -ne "Read")
    }

    # Step 7: Default mode - Read is auto, others need approval
    if ($level -eq "Read") { return $false }

    # Special case: safe PS commands
    if ($ToolName -eq "execute_powershell" -and $Arguments.command) {
        $cmd = $Arguments.command.Trim()
        foreach ($safe in $Script:SafeCommands) {
            if ($cmd.StartsWith($safe, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $false
            }
        }
        if ($cmd -match "^(ls|dir|cat|type|pwd|echo|date|whoami|tree|cls|clear)") {
            return $false
        }

        # Dangerous command detection - ALWAYS require approval
        $dangerousPatterns = @(
            "Remove-Item", "rm ", "del ", "rmdir",
            "Stop-Process", "kill",
            "Format-Volume", "Format-Disk",
            "Clear-Disk",
            "Set-ExecutionPolicy",
            "Invoke-Expression", "iex ",
            "Invoke-WebRequest.*-OutFile.*\.(exe|bat|cmd|ps1)",
            "New-Item.*-ItemType.*SymbolicLink",
            "icacls.*\/grant",
            "net user.*\/add",
            "net localgroup.*\/add"
        )
        foreach ($pattern in $dangerousPatterns) {
            if ($cmd -match "(?i)$pattern") {
                return $true
            }
        }
    }

    return $true
}

function Test-RuleMatch {
    param($Rule, [string]$ToolName, [string]$TargetPath)

    # Tool name check
    if ($Rule.tool_name -and $Rule.tool_name -ne $ToolName) { return $false }

    # Path pattern check (glob)
    if ($Rule.path_pattern -and $TargetPath) {
        if (-not (Test-GlobMatch -Pattern $Rule.path_pattern -TargetPath $TargetPath)) {
            return $false
        }
    } elseif ($Rule.path_pattern -and -not $TargetPath) {
        return $false
    }

    return $true
}

function Test-GlobMatch {
    param([string]$Pattern, [string]$TargetPath)

    # Convert glob pattern to regex
    $regex = [regex]::Escape($Pattern)
    $regex = $regex -replace '\\\*\*', '.*'
    $regex = $regex -replace '\\\*', '[^\\/]*'
    $regex = $regex -replace '\\\?', '.'

    return ($TargetPath -match "^$regex$")
}

function Set-ToolAlwaysApproved {
    param([string]$ToolName)
    $Script:AlwaysApproved[$ToolName] = $true
}

function Add-SessionAllow {
    param([string]$ToolName, [string]$PathPattern = "")
    $rule = @{ tool_name = $ToolName; action = "Allow"; path_pattern = $PathPattern }
    $Script:SessionRules += $rule
}

function Add-SessionDeny {
    param([string]$ToolName, [string]$PathPattern = "")
    $rule = @{ tool_name = $ToolName; action = "Deny"; path_pattern = $PathPattern }
    $Script:SessionRules += $rule
}

function Add-PersistentAllow {
    param([string]$ToolName, [string]$PathPattern = "")
    $rule = @{ tool_name = $ToolName; action = "Allow"; path_pattern = $PathPattern }
    $Script:PersistentRules += $rule
    Save-PersistentRules
}

function Add-PersistentDeny {
    param([string]$ToolName, [string]$PathPattern = "")
    $rule = @{ tool_name = $ToolName; action = "Deny"; path_pattern = $PathPattern }
    $Script:PersistentRules += $rule
    Save-PersistentRules
}

function Remove-PersistentRule {
    param([int]$Index)
    if ($Index -ge 0 -and $Index -lt $Script:PersistentRules.Count) {
        $Script:PersistentRules = @($Script:PersistentRules[0..($Index-1)]) + @($Script:PersistentRules[($Index+1)..($Script:PersistentRules.Count-1)])
        $Script:PersistentRules = @($Script:PersistentRules | Where-Object { $_ -ne $null })
        Save-PersistentRules
    }
}

function Set-PermissionMode {
    param([string]$Mode)
    $validModes = @("Default", "AcceptEdits", "BypassPermissions", "Plan")
    if ($Mode -in $validModes) {
        $Script:PermissionMode = $Mode
        Write-InfoPS "Permission mode set to: $Mode"
    } else {
        Write-ErrorPS "Invalid mode. Use: $($validModes -join ', ')"
    }
}

function Get-PermissionStatus {
    $result = "PERMISSION STATUS`n"
    $result += "=" * 50 + "`n"
    $result += "Mode: $Script:PermissionMode`n"
    $result += "Session rules: $($Script:SessionRules.Count)`n"
    $result += "Persistent rules: $($Script:PersistentRules.Count)`n"
    $result += "Always approved: $($Script:AlwaysApproved.Keys -join ', ')`n"

    if ($Script:PersistentRules.Count -gt 0) {
        $result += "`nPersistent rules:`n"
        for ($i = 0; $i -lt $Script:PersistentRules.Count; $i++) {
            $r = $Script:PersistentRules[$i]
            $pathInfo = if ($r.path_pattern) { " (path: $($r.path_pattern))" } else { "" }
            $result += "  [$i] $($r.action) $($r.tool_name)$pathInfo`n"
        }
    }

    return $result
}

