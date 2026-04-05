# Memory.ps1 - Persistent memory system for PSCoder

function Get-PSCoderMemory {
    $config = Get-PSCoderConfig
    $memFile = $config.memoryFile
    if (-not $memFile) { $memFile = Join-Path $HOME ".pscoder\MEMORY.md" }
    if (Test-Path $memFile) {
        $content = Get-Content -Path $memFile -Raw -Encoding UTF8
        return $content
    }
    # Create default memory if it doesn't exist
    $defaultMemory = @"
# PSCoder Memory

## User Info
- Name: (not set)
- OS: Windows
- Working Directory: (not set)

## Preferences
- Language: (not set)
- Show details: enabled

## Projects
- (no projects yet)

## Learnings
- (no learnings yet)
"@
    $defaultMemory | Set-Content -Path $memFile -Encoding UTF8
    return $defaultMemory
}

function Show-PSCoderMemory {
    $memory = Get-PSCoderMemory
    if (-not $memory -or $memory.Trim().Length -eq 0) {
        Write-InfoPS "Memory is empty. Use /memory edit to add information."
        return
    }
    Write-HeaderPS "Long-term memory"
    Write-Host $memory -ForegroundColor Gray
}

function Set-PSCoderMemory {
    param([string]$Content)
    $config = Get-PSCoderConfig
    $memFile = $config.memoryFile
    $Content | Set-Content -Path $memFile -Encoding UTF8
}

function Add-PSCoderMemoryNote {
    param([string]$Note)
    $config = Get-PSCoderConfig
    $memFile = $config.memoryFile
    
    # If memory doesn't exist, create it
    if (-not (Test-Path $memFile)) {
        Get-PSCoderMemory | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $entry = "`n### [$timestamp] $Note`n"
    Add-Content -Path $memFile -Value $entry -Encoding UTF8
}

