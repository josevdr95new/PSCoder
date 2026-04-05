# Config.ps1 - Configuration management for PSCoder

$Script:PSCoderConfigDir = Join-Path $HOME ".pscoder"
$Script:PSCoderConfigFile = Join-Path $Script:PSCoderConfigDir "config.json"

$Script:DefaultConfig = @{
    apiKey          = ""
    groqApiKey      = ""
    braveSearchApiKey = ""
    provider        = "openrouter"
    model           = "qwen/qwen3.6-plus:free"
    maxTokens       = 4096
    temperature     = 0.7
    permissions     = @{ autoApprove = $false; dangerousCommands = "ask" }
    memoryEnabled   = $true
    saveHistory     = $true
    historyDir      = (Join-Path $Script:PSCoderConfigDir "Sessions")
    memoryFile      = (Join-Path $Script:PSCoderConfigDir "MEMORY.md")
    agentNarration  = $true
    speechEnabled   = $true
    speechRate      = 0
    speechVolume    = 100
}

function Convert-PSObjectToHashtable {
    param([Parameter(ValueFromPipeline)]$InputObject)
    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [System.Collections.Hashtable]) { return $InputObject }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @()
            foreach ($item in $InputObject) { $collection += Convert-PSObjectToHashtable $item }
            return $collection
        }
        if ($InputObject -is [psobject]) {
            $hash = @{}
            foreach ($prop in $InputObject.PSObject.Properties) {
                $hash[$prop.Name] = Convert-PSObjectToHashtable $prop.Value
            }
            return $hash
        }
        return $InputObject
    }
}

function Initialize-PSCoderConfig {
    if (-not (Test-Path $Script:PSCoderConfigFile)) {
        $Script:DefaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:PSCoderConfigFile -Encoding UTF8
    }
    $memFile = $Script:DefaultConfig.memoryFile
    if (-not (Test-Path $memFile)) {
        "# PSCoder Memory`n`n## Preferencias`n`n## Proyectos`n" | Set-Content -Path $memFile -Encoding UTF8
    }
}

function Get-PSCoderConfig {
    if (-not (Test-Path $Script:PSCoderConfigFile)) {
        Initialize-PSCoderConfig
    }
    try {
        $json = Get-Content -Path $Script:PSCoderConfigFile -Raw
        $config = ($json | ConvertFrom-Json) | Convert-PSObjectToHashtable
    } catch {
        # Config file corrupted, use defaults
        Write-PSCoderLog -Level "WARN" -Message "Config file corrupted, using defaults: $($_.Exception.Message)" -Source "Config"
        $config = $Script:DefaultConfig.Clone()
    }
    if (-not $config.historyDir) { $config.historyDir = $Script:DefaultConfig.historyDir }
    if (-not $config.memoryFile) { $config.memoryFile = $Script:DefaultConfig.memoryFile }
    return $config
}

function Set-PSCoderConfig {
    param([hashtable]$Updates)
    $config = Get-PSCoderConfig
    foreach ($key in $Updates.Keys) {
        $config[$key] = $Updates[$key]
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:PSCoderConfigFile -Encoding UTF8
}

function Get-OpenRouterApiKey {
    $config = Get-PSCoderConfig
    if ($config.apiKey -and $config.apiKey -ne "") {
        return $config.apiKey
    }
    if ($env:OPENROUTER_API_KEY) { return $env:OPENROUTER_API_KEY }
    return $null
}

function Get-GroqApiKey {
    $config = Get-PSCoderConfig
    if ($config.groqApiKey -and $config.groqApiKey -ne "") {
        return $config.groqApiKey
    }
    if ($env:GROQ_API_KEY) { return $env:GROQ_API_KEY }
    return $null
}

function Test-PSCoderConfig {
    $config = Get-PSCoderConfig
    $issues = @()

    if (-not $config.apiKey -or $config.apiKey -eq "") {
        if (-not $env:OPENROUTER_API_KEY) {
            $issues += "OpenRouter API key not set. Set via '/provider' command or `$env:OPENROUTER_API_KEY"
        }
    }

    if (-not $config.groqApiKey -or $config.groqApiKey -eq "") {
        if (-not $env:GROQ_API_KEY) {
            $issues += "Groq API key not set. Set via config or `$env:GROQ_API_KEY"
        }
    }

    if ($issues.Count -eq 0) {
        return @{ valid = $true; message = "Configuration is valid." }
    }

    return @{ valid = $false; issues = $issues; message = ($issues -join "`n") }
}
