# AutoImprove.ps1 - Self-improvement and learning system for PSCoder
# Stores error/solution pairs, patterns, and provides Find-Solution

$Script:ImproveDir = Join-Path $HOME ".pscoder\improve"
$Script:Learnings = @()
$Script:Patterns = @{}

function Initialize-AutoImprove {
    Load-Learnings
    Load-Patterns
}

function Load-Learnings {
    $learningsPath = Join-Path $Script:ImproveDir "learnings.json"
    if (Test-Path $learningsPath) {
        try {
            $loaded = Get-Content $learningsPath -Raw | ConvertFrom-Json
            if ($loaded) {
                if ($loaded -is [array]) { $Script:Learnings = $loaded }
                else { $Script:Learnings = @($loaded) }
            }
        } catch {
            $Script:Learnings = @()
        }
    }
}

function Load-Patterns {
    $patternsPath = Join-Path $Script:ImproveDir "patterns.json"
    if (Test-Path $patternsPath) {
        try {
            $Script:Patterns = Get-Content $patternsPath -Raw | ConvertFrom-Json | Convert-PSObjectToHashtable
        } catch {
            $Script:Patterns = @{}
        }
    }
}

function Add-Learning {
    param(
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][string]$Problem,
        [Parameter(Mandatory)][string]$Solution,
        [string]$Context = "",
        [string]$Code = ""
    )

    $learning = @{
        id = [guid]::NewGuid().ToString().Substring(0, 8)
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        category = $Category
        problem = $Problem
        solution = $Solution
        context = $Context
        code = $Code
        used = 0
    }

    if ($Script:Learnings -is [System.Collections.IEnumerable] -and $Script:Learnings -isnot [string]) {
        $Script:Learnings += $learning
    } else {
        $Script:Learnings = @($learning)
    }

    # Update pattern
    if (-not $Script:Patterns.ContainsKey($Category)) {
        $Script:Patterns[$Category] = @()
    }

    if ($Script:Patterns[$Category] -is [System.Collections.IDictionary]) {
        $Script:Patterns[$Category] = @(@{
            problem = $Problem
            solution = $Solution
        })
    } else {
        $Script:Patterns[$Category] += @{
            problem = $Problem
            solution = $Solution
        }
    }

    Save-Learnings
    Save-Patterns

    return "Learning registered: $Category - $Problem"
}

function Get-Learnings {
    param(
        [string]$Category = "",
        [int]$Last = 10
    )

    if ($Script:Learnings.Count -eq 0) {
        return "No learnings registered."
    }

    $filtered = if ($Category) {
        $Script:Learnings | Where-Object { $_.category -eq $Category }
    } else {
        $Script:Learnings
    }

    $result = "REGISTERED LEARNINGS`n"
    $result += "=" * 40 + "`n"

    foreach ($learning in ($filtered | Select-Object -Last $Last)) {
        $result += "`n[$($learning.id)] $($learning.category) - $($learning.timestamp)`n"
        $result += "  Problem: $($learning.problem)`n"
        $result += "  Solution: $($learning.solution)`n"
        $result += "  Used: $($learning.used) times`n"
    }

    return $result
}

function Find-Solution {
    param([Parameter(Mandatory)][string]$Problem)

    # Search in learnings
    foreach ($learning in $Script:Learnings) {
        if ($Problem -match [regex]::Escape($learning.problem) -or $learning.problem -match [regex]::Escape($Problem)) {
            $learning.used++
            Save-Learnings
            return @{
                found = $true
                solution = $learning.solution
                code = $learning.code
                category = $learning.category
                used_times = $learning.used
            }
        }
    }

    # Search by similarity
    $words = $Problem -split '\s+'
    foreach ($learning in $Script:Learnings) {
        $matchCount = 0
        foreach ($word in $words) {
            if ($learning.problem -match [regex]::Escape($word)) { $matchCount++ }
        }
        if ($matchCount -ge 2) {
            return @{
                found = $true
                solution = $learning.solution
                code = $learning.code
                category = $learning.category
                similarity = "partial"
            }
        }
    }

    return @{ found = $false; message = "No known solution found." }
}

function Save-Learnings {
    $learningsPath = Join-Path $Script:ImproveDir "learnings.json"
    $learningsArray = @($Script:Learnings)
    $learningsArray | ConvertTo-Json -Depth 10 | Set-Content -Path $learningsPath -Encoding UTF8
}

function Save-Patterns {
    $patternsPath = Join-Path $Script:ImproveDir "patterns.json"
    $Script:Patterns | ConvertTo-Json -Depth 10 | Set-Content -Path $patternsPath -Encoding UTF8
}
