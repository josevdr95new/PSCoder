# Init.ps1 - Centralized subsystem initialization for PSCoder

function Initialize-PSCoderSubsystems {
    $dirsToCreate = @(
        (Join-Path $HOME ".pscoder"),
        (Join-Path $HOME ".pscoder\Sessions"),
        (Join-Path $HOME ".pscoder\healing"),
        (Join-Path $HOME ".pscoder\improve"),
        (Join-Path $HOME ".pscoder\cache"),
        (Join-Path $HOME ".pscoder\cache\search"),
        (Join-Path $HOME ".pscoder\cache\fetch"),
        (Join-Path $HOME ".pscoder\reasoning"),
        (Join-Path $HOME ".pscoder\memory_decisions"),
        (Join-Path $HOME ".pscoder\hooks")
    )

    foreach ($dir in $dirsToCreate) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    Initialize-AutoHealing
    Initialize-AutoImprove
    Initialize-ReasoningEngine
    Initialize-MemoryDecision
    Initialize-SkillManager
}
