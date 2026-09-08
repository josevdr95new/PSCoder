# OrcaRouter.ps1 - HTTP client for OrcaRouter API (OpenAI-compatible)
# https://api.orcarouter.ai/v1/chat/completions
# Modelos: z-ai/glm-5.3-flash-free (FREE), z-ai/glm-5.3, etc.
# API Key: sk-orca-nzQIdv0h6Y4DHU8cgsl2jockrSESO1qQeiSukxJ6oZm

$Script:OrcaRouterBaseURL = "https://api.orcarouter.ai/v1"

function Invoke-OrcaRouterChat {
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][array]$Messages,
        [Parameter()][array]$Tools = @(),
        [int]$MaxTokens = 4096,
        [double]$Temperature = 0.7,
        [string]$ApiKey
    )
    if (-not $ApiKey) { $ApiKey = Get-OrcaRouterApiKey }
    if (-not $ApiKey) {
        Write-ErrorPS "OrcaRouter API Key not found. Use '/config orcaApiKey <your-key>' or set `$env:ORCAROUTER_API_KEY"
        return $null
    }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    $body = Build-ChatBody -Model $Model -Messages $Messages -Tools $Tools -MaxTokens $MaxTokens -Temperature $Temperature
    return Invoke-APIChat -Uri "$Script:OrcaRouterBaseURL/chat/completions" -Headers $headers -Body $body -ProviderName "OrcaRouter"
}

function Get-OrcaRouterModelsList {
    return @(
        "--- FREE (gratiss, sin crédito) ---"
        "z-ai/glm-5.3-flash-free"
        "deepseek/deepseek-v4-flash-free"
        "deepseek/deepseek-v4-pro-free"
        "tencent/hy3-free"
        "--- Z.AI (GLM) ---"
        "z-ai/glm-5.3-flash"
        "z-ai/glm-5.3"
        "z-ai/glm-5.3-turbo"
        "--- OPENAI ---"
        "openai/gpt-4o"
        "openai/gpt-4o-mini"
        "openai/o3-mini"
        "--- ANTHROPIC ---"
        "anthropic/claude-3.5-sonnet"
        "--- GOOGLE ---"
        "google/gemini-2.5-pro"
        "google/gemini-2.5-flash"
        "--- META ---"
        "meta-llama/llama-4-maverick"
        "--- DEEPSEEK ---"
        "deepseek/deepseek-chat-v3"
        "deepseek/deepseek-r1"
    )
}
