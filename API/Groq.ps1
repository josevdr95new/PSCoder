# Groq.ps1 - HTTP client for Groq API (OpenAI-compatible)

$Script:GroqBaseURL = "https://api.groq.com/openai/v1"

function Invoke-GroqChat {
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][array]$Messages,
        [Parameter()][array]$Tools = @(),
        [int]$MaxTokens = 4096,
        [double]$Temperature = 0.6,
        [string]$ApiKey,
        [string]$ReasoningEffort = "default"
    )
    if (-not $ApiKey) { $ApiKey = Get-GroqApiKey }
    if (-not $ApiKey) {
        Write-ErrorPS "Groq API Key not found. Use '/config groqApiKey <your-key>' or set `$env:GROQ_API_KEY"
        return $null
    }

    $extraParams = @{ top_p = 0.95; stream = $false }
    if ($ReasoningEffort) { $extraParams.reasoning_effort = $ReasoningEffort }

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    $body = Build-ChatBody -Model $Model -Messages $Messages -Tools $Tools -MaxTokens $MaxTokens -Temperature $Temperature -MaxTokensKey "max_completion_tokens" -ExtraParams $extraParams
    return Invoke-APIChat -Uri "$Script:GroqBaseURL/chat/completions" -Headers $headers -Body $body -ProviderName "Groq"
}

function Get-GroqModelsList {
    return @(
        "--- GROQ ---"
        "llama-3.3-70b-versatile"
        "llama-3.1-8b-instant"
        "llama-3.1-70b-versatile"
        "llama3-70b-8192"
        "llama3-8b-8192"
        "--- LLAMA 4 ---"
        "meta-llama/llama-4-maverick-17b-128e-instruct"
        "meta-llama/llama-4-scout-17b-16e-instruct"
        "--- DEEPSEEK ---"
        "deepseek-r1-distill-llama-70b"
        "deepseek-r1-distill-qwen-32b"
        "--- QWEN ---"
        "qwen/qwen3-32b"
        "--- MIXTRAL / GEMMA ---"
        "mixtral-8x7b-32768"
        "gemma2-9b-it"
        "gemma-7b-it"
        "--- OTHERS ---"
        "compound-beta"
        "compound-beta-mini"
    )
}
