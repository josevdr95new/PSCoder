# OpenRouter.ps1 - HTTP client for OpenRouter API

$Script:OpenRouterBaseURL = "https://openrouter.ai/api/v1"

function Invoke-OpenRouterChat {
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][array]$Messages,
        [Parameter()][array]$Tools = @(),
        [int]$MaxTokens = 4096,
        [double]$Temperature = 0.7,
        [string]$ApiKey,
        [switch]$Reasoning
    )
    if (-not $ApiKey) { $ApiKey = Get-OpenRouterApiKey }
    if (-not $ApiKey) {
        Write-ErrorPS "API Key not found. Use '/config apiKey <your-key>' or set `$env:OPENROUTER_API_KEY"
        return $null
    }
    $extraParams = @{}
    if ($Reasoning) { $extraParams.reasoning = @{ enabled = $true } }
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
        "HTTP-Referer" = "https://pscoder.local"
        "X-OpenRouter-Title" = "PSCoder"
    }
    $body = Build-ChatBody -Model $Model -Messages $Messages -Tools $Tools -MaxTokens $MaxTokens -Temperature $Temperature -ExtraParams $extraParams
    return Invoke-APIChat -Uri "$Script:OpenRouterBaseURL/chat/completions" -Headers $headers -Body $body -ProviderName "OpenRouter"
}

function Get-ModelsList {
    return @(
        "--- FREE ---"
        "stepfun/step-3.5-flash:free"
        "meta-llama/llama-4-maverick:free"
        "google/gemini-3-27b-it:free"
        "qwen/qwen3.6-plus:free"
        "--- OPENAI ---"
        "openai/gpt-4o"
        "openai/gpt-4o-mini"
        "openai/o3-mini"
        "--- GOOGLE ---"
        "google/gemini-2.5-pro"
        "google/gemini-2.5-flash"
        "--- META ---"
        "meta-llama/llama-4-maverick"
        "meta-llama/llama-4-scout"
        "--- DEEPSEEK ---"
        "deepseek/deepseek-chat-v3"
        "deepseek/deepseek-r1"
        "--- QWEN ---"
        "qwen/qwen3.6-plus"
        "qwen/qwen-max"
        "--- MISTRAL ---"
        "mistralai/mistral-large"
    )
}
