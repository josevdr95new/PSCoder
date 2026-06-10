# BaseClient.ps1 - Shared HTTP client logic for API providers
# Enhanced with exponential backoff + Retry-After header support (from claurst)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$Script:MaxRetries = 5
$Script:InitialBackoffMs = 1000
$Script:MaxBackoffMs = 16000
$Script:RequestTimeoutSec = 600

function Invoke-APIChat {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][hashtable]$Body,
        [Parameter(Mandatory)][string]$ProviderName
    )

    $jsonBody = $Body | ConvertTo-Json -Depth 20
    Write-PSCoderLog -Level "DEBUG" -Message "Calling $ProviderName API" -Source "BaseClient"

    $retryCount = 0
    $backoffMs = $Script:InitialBackoffMs

    while ($true) {
        try {
            $request = [System.Net.HttpWebRequest]::Create($Uri)
            $request.Method = "POST"
            $request.ContentType = "application/json; charset=utf-8"
            $request.Timeout = $Script:RequestTimeoutSec * 1000
            $request.ReadWriteTimeout = $Script:RequestTimeoutSec * 1000
            foreach ($key in $Headers.Keys) {
                if ($key -eq "Authorization") { $request.Headers.Add($key, $Headers[$key]) }
                elseif ($key -eq "HTTP-Referer") { $request.Headers.Add($key, $Headers[$key]) }
                elseif ($key -eq "X-OpenRouter-Title") { $request.Headers.Add($key, $Headers[$key]) }
            }
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
            $request.ContentLength = $bodyBytes.Length
            $reqStream = $request.GetRequestStream()
            $reqStream.Write($bodyBytes, 0, $bodyBytes.Length)
            $reqStream.Close()
            $webResponse = $request.GetResponse()
            $respStream = $webResponse.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($respStream, [System.Text.Encoding]::UTF8)
            $rawJson = $reader.ReadToEnd()
            $reader.Close()
            $webResponse.Close()
            $response = $rawJson | ConvertFrom-Json
            Write-PSCoderLog -Level "DEBUG" -Message "$ProviderName API call successful" -Source "BaseClient"
            return $response
        }
        catch {
            $errorMsg = $_.Exception.Message
            $statusCode = 0
            $retryAfterSec = 0

            # Extract status code and Retry-After header
            try {
                if ($_.Exception.Response) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                    $retryAfterHeader = $_.Exception.Response.Headers["Retry-After"]
                    if ($retryAfterHeader) {
                        $retryAfterSec = [int]$retryAfterHeader
                    }
                }
            } catch {}

            # Parse error body for better messages
            try {
                if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
                    $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                    $errorBody = $reader.ReadToEnd()
                    $reader.Dispose()
                    $errorJson = $errorBody | ConvertFrom-Json
                    if ($errorJson.error.message) {
                        $errorMsg = $errorJson.error.message
                    }
                }
            } catch {}

            # Determine if retryable
            $isRetryable = $false
            if ($statusCode -eq 429 -or $statusCode -eq 500 -or $statusCode -eq 502 -or $statusCode -eq 503 -or $statusCode -eq 504) {
                $isRetryable = $true
            }
            if ($errorMsg -match "timeout|tiempo de espera|connection reset") {
                $isRetryable = $true
            }

            if ($isRetryable -and $retryCount -lt $Script:MaxRetries) {
                $retryCount++

                # Use Retry-After header if present, otherwise exponential backoff
                if ($retryAfterSec -gt 0) {
                    $waitMs = $retryAfterSec * 1000
                } else {
                    $waitMs = $backoffMs
                    $backoffMs = [Math]::Min($backoffMs * 2, $Script:MaxBackoffMs)
                }

                $waitSec = [Math]::Round($waitMs / 1000, 1)
                Write-PSCoderLog -Level "WARN" -Message "$ProviderName retry $retryCount/$Script:MaxRetries after ${waitSec}s (status: $statusCode)" -Source "BaseClient"
                Write-InfoPS "$ProviderName rate limited/error. Retrying in ${waitSec}s (attempt $retryCount/$Script:MaxRetries)..."
                Start-Sleep -Milliseconds $waitMs
                continue
            }

            Write-PSCoderLog -Level "ERROR" -Message "$ProviderName API error: $errorMsg (status: $statusCode, retries: $retryCount)" -Source "BaseClient"
            Write-ErrorPS "$ProviderName`n API: $errorMsg"
            return $null
        }
    }
}

function Build-ChatBody {
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][array]$Messages,
        [array]$Tools = @(),
        [int]$MaxTokens = 4096,
        [double]$Temperature = 0.7,
        [string]$MaxTokensKey = "max_tokens",
        [hashtable]$ExtraParams = @{}
    )

    $body = @{
        model = $Model
        messages = $Messages
        $MaxTokensKey = $MaxTokens
        temperature = $Temperature
    }

    if ($Tools.Count -gt 0) { $body.tools = $Tools }

    foreach ($key in $ExtraParams.Keys) {
        $body[$key] = $ExtraParams[$key]
    }

    return $body
}
