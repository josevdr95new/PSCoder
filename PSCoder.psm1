#Requires -Version 5.1
# PSCoder.psm1 - Main module for PSCoder

# Configure UTF-8 encoding for special characters
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Load shared assemblies once
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

$PSScriptRoot_ = Split-Path $MyInvocation.MyCommand.Path -Parent

# Load modules in dependency order
$modulesToLoad = @(
    "Config/Config.ps1"
    "Tools/Cache.ps1"
    "UI/Formatter.ps1"
    "API/BaseClient.ps1"
    "API/OpenRouter.ps1"
    "API/Groq.ps1"
    "API/OrcaRouter.ps1"
    "Tools/WebSearch.ps1"
    "Tools/WebFetch.ps1"
    "Tools/OcrImage.ps1"
    "Tools/ToolRegistry.ps1"
    "Tools/ExecutePowerShell.ps1"
    "Tools/ReadFile.ps1"
    "Tools/WriteFile.ps1"
    "Tools/EditFile.ps1"
    "Tools/SearchFiles.ps1"
    "Tools/GlobFiles.ps1"
    "Tools/ListDirectory.ps1"
    "Core/Logger.ps1"
    "Core/Hooks.ps1"
    "Core/ContextBuilder.ps1"
    "Core/AutoImprove.ps1"
    "Core/AutoHealing.ps1"
    "Core/AgentNarration.ps1"
    "Memory/Memory.ps1"
    "Core/Init.ps1"
    "Core/ReasoningEngine.ps1"
    "Core/MemoryDecision.ps1"
    "Tools/SkillManager.ps1"
    "Tools/Invoke-Tool.ps1"
    "History/History.ps1"
    "Commands/SlashCommands.ps1"
    "Core/SystemPrompt.ps1"
    "Core/Permissions.ps1"
    "Core/InterruptHandler.ps1"
    "Core/Main-Loop.ps1"
)

$failedModules = @()
foreach ($module in $modulesToLoad) {
    $modulePath = Join-Path $PSScriptRoot_ $module
    if (Test-Path $modulePath) {
        try {
            . $modulePath
        } catch {
            $failedModules += "$module : $($_.Exception.Message)"
        }
    } else {
        $failedModules += "$module : file not found"
    }
}

if ($failedModules.Count -gt 0) {
    Write-Warning "PSCoder: Failed to load $($failedModules.Count) module(s):"
    foreach ($f in $failedModules) {
        Write-Warning "  - $f"
    }
}

# Initialize configuration and subsystems
Initialize-PSCoderConfig
Initialize-PSCoderSubsystems
Initialize-Hooks
Initialize-Permissions

# Export all module members
Export-ModuleMember -Function *
