# SkillManager.ps1 - Skill discovery and loading system for PSCoder
# Skills are markdown files in Skills/ directory that teach the agent specialized workflows
# The agent lists skills, reads relevant ones, and uses their instructions to perform tasks better

$Script:SkillsDir = Join-Path $PSScriptRoot\.. "Skills"

function Initialize-SkillManager {
    # Skills directory is in the project root, not in .pscoder
}

function Get-SkillList {
    if (-not (Test-Path $Script:SkillsDir)) {
        return "No skills directory found."
    }

    $skillFiles = Get-ChildItem -Path $Script:SkillsDir -Filter "*.md" -File

    if (-not $skillFiles) {
        return "No skills found. Add .md files to the Skills/ directory."
    }

    $result = "AVAILABLE SKILLS`n"
    $result += "=" * 50 + "`n"

    foreach ($file in $skillFiles) {
        $name = $file.BaseName
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $description = ""
        $whenToUse = ""

        # Extract description - (?s) enables dotall for multiline matching
        if ($content -match '(?s)## Description\s*\r?\n(.+?)\r?\n##') {
            $description = $Matches[1].Trim() -replace '\r?\n', ' '
        }

        # Extract when to use
        if ($content -match '(?s)## When to use\s*\r?\n(.+?)\r?\n##') {
            $whenToUse = $Matches[1].Trim() -replace '\r?\n', ' '
        }

        $result += "`n[$name]`n"
        $result += "  Description: $description`n"
        if ($whenToUse) {
            $result += "  Use when: $whenToUse`n"
        }
    }

    return $result
}

function Get-SkillContent {
    param([Parameter(Mandatory)][string]$SkillName)

    if (-not (Test-Path $Script:SkillsDir)) {
        return "ERROR: No skills directory."
    }

    # Try exact match first
    $skillFile = Get-ChildItem -Path $Script:SkillsDir -Filter "$SkillName.md" -File
    if (-not $skillFile) {
        # Try partial match
        $skillFile = Get-ChildItem -Path $Script:SkillsDir -Filter "*.md" -File | Where-Object { $_.BaseName -match $SkillName }
    }

    if (-not $skillFile) {
        $available = (Get-ChildItem -Path $Script:SkillsDir -Filter "*.md" -File | ForEach-Object { $_.BaseName }) -join ", "
        return "ERROR: Skill '$SkillName' not found. Available: $available"
    }

    $content = Get-Content -Path $skillFile.FullName -Raw -Encoding UTF8

    return $content
}
