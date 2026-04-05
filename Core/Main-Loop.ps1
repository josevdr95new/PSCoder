# Main-Loop.ps1 - Main REPL loop for PSCoder
# Enhanced with: ContextBuilder, Hooks, exponential backoff, improved auto-compact, tool result budget

function Start-PSCoder {
    param(
        [string]$InitialModel,
        [string]$InitialProvider
    )

    # Load configuration
    $config = Get-PSCoderConfig
    $model = if ($InitialModel) { $InitialModel } else { $config.model }
    $provider = if ($InitialProvider) { $InitialProvider } else { $config.provider }
    $workingDir = (Get-Location).Path
    $messages = @()
    $totalTokens = 0
    $turnCount = 0
    $sessionCost = 0.0
    $queryDepth = 0
    $chainId = [guid]::NewGuid().ToString()

    # Token budget configuration
    $contextWindow = 128000
    $compactThreshold = 0.85
    $autoCompactThreshold = [Math]::Floor($contextWindow * $compactThreshold)
    $toolResultBudget = 5000
    $maxToolResultsPerTurn = 20
    $sessionId = $chainId

    # Track files read for read-before-write enforcement
    $readFileState = @{}

    # Initialize agent narration from config
    if ($config.ContainsKey("agentNarration")) {
        Set-AgentNarration -Enabled $config.agentNarration
    }
    if ($config.ContainsKey("speechEnabled")) {
        Set-AgentSpeech -Enabled $config.speechEnabled
    }
    if ($config.ContainsKey("speechRate")) {
        $Script:SpeechRate = $config.speechRate
    }
    if ($config.ContainsKey("speechVolume")) {
        $Script:SpeechVolume = $config.speechVolume
    }

    # Build dynamic context (git + PSCODER.md)
    $context = Build-FullContext -WorkingDir $workingDir
    $memoryContent = Get-PSCoderMemory
    $systemPrompt = Get-PSCoderSystemPrompt -WorkingDir $workingDir -MemoryContent $memoryContent -GitStatus $context.gitStatus -ProjectContext $context.projectMd
    $messages += @{ role = "system"; content = $systemPrompt }

    # Start banner
    Write-PSCoderBanner
    Write-InfoPS "Provider: $provider"
    Write-InfoPS "Model: $model"
    Write-InfoPS "Directory: $workingDir"
    Write-InfoPS "Type /help for commands, or ask your question directly"
    Write-InfoPS "Use /exit to quit"

    # Disable Ctrl+C - console will ignore it
    try {
        [Console]::TreatControlCAsInput = $true
    } catch {}

    while ($true) {
        # Show prompt
        Write-PSCoderPrompt -Model $model -CurrentDir $workingDir

        # Read user input
        try {
            $userInput = Read-Host
        } catch {
            # Any exception during Read-Host - just continue
            continue
        }
        if (-not $userInput -or $userInput.Trim() -eq "") { continue }
        $userInput = $userInput.Trim()

        # Update activity time
        $Script:LastActivityTime = Get-Date

        # Slash commands
        if ($userInput.StartsWith("/")) {
            $action = Invoke-SlashCommand -Command $userInput -Model ([ref]$model) -Messages ([ref]$messages) -Provider ([ref]$provider)
            switch ($action) {
                "exit" {
                    Invoke-StopHook -AssistantMessage "Session ended" -SessionId $sessionId
                    if ($config.saveHistory -and $turnCount -gt 0) {
                        Save-PSCoderSession -Messages $messages -Model $model
                    }
                    Write-StatusBar -Model $model -Tokens $totalTokens -Turn $turnCount -Provider $provider -Cost $sessionCost
                    Write-InfoPS "Session saved. Goodbye!"
                    return
                }
                "clear" {
                    $context = Build-FullContext -WorkingDir $workingDir
                    $memoryContent = Get-PSCoderMemory
                    $systemPrompt = Get-PSCoderSystemPrompt -WorkingDir $workingDir -MemoryContent $memoryContent -GitStatus $context.gitStatus -ProjectContext $context.projectMd
                    continue
                }
                "reload" {
                    $context = Build-FullContext -WorkingDir $workingDir
                    $memoryContent = Get-PSCoderMemory
                    $systemPrompt = Get-PSCoderSystemPrompt -WorkingDir $workingDir -MemoryContent $memoryContent -GitStatus $context.gitStatus -ProjectContext $context.projectMd
                    $messages = @(@{ role = "system"; content = $systemPrompt })
                    $totalTokens = 0
                    $sessionCost = 0.0
                    $queryDepth = 0
                    $chainId = [guid]::NewGuid().ToString()
                    $sessionId = $chainId
                    $readFileState.Clear()
                    Write-InfoPS "Conversation restarted."
                    continue
                }
            }
            continue
        }

        # Add user message to history
        $messages += @{ role = "user"; content = $userInput }
        $turnCount++
        $queryDepth++

        # Check context size and auto-compact if needed
        $contextSize = Estimate-MessageTokens -Messages $messages
        if ($contextSize -gt $autoCompactThreshold) {
            Write-AgentThought -Thought "Context approaching limit, compacting conversation..."
            $messages = Invoke-AutoCompact -Messages $messages -SystemPrompt $systemPrompt -ContextWindow $contextWindow -Threshold $compactThreshold -Model $model -Provider $provider
            Write-AgentResult -Result "Context compacted. Continuing conversation."
        }

        # Tool calling loop
        $maxRounds = 10
        $round = 0
        $continueLoop = $true
        $startTime = Get-Date
        $toolResultCount = 0
        $lastError = $null
        $retryCount = 0

        while ($continueLoop -and $round -lt $maxRounds) {
            $round++
            $queryDepth++
            $toolSchemas = Get-ToolSchemas

            Write-AgentThought -Thought "Processing your request..."
            Write-ThinkingStart
            $apiStart = Get-Date

            # Call API based on provider with error recovery
            $response = $null
            $apiError = $null
            try {
                if ($provider -eq "groq") {
                    $response = Invoke-GroqChat `
                        -Model $model `
                        -Messages $messages `
                        -Tools $toolSchemas `
                        -MaxTokens $config.maxTokens `
                        -Temperature $config.temperature
                } else {
                    $response = Invoke-OpenRouterChat `
                        -Model $model `
                        -Messages $messages `
                        -Tools $toolSchemas `
                        -MaxTokens $config.maxTokens `
                        -Temperature $config.temperature
                }
            } catch {
                $apiError = $_.Exception.Message
            }

            # Error recovery: retry with fallback
            if (-not $response -and $apiError) {
                if ($apiError -match "429|rate.limit|too.many" -and $retryCount -lt 2) {
                    $retryCount++
                    Write-AgentError -Error "Rate limited. Retrying in $($retryCount * 5)s (attempt $retryCount/2)..."
                    Start-Sleep -Seconds ($retryCount * 5)
                    $round--
                    continue
                }
                elseif ($apiError -match "context|token|length" -and $messages.Count -gt 3) {
                    Write-AgentError -Error "Context too long. Compacting and retrying..."
                    $messages = Invoke-AutoCompact -Messages $messages -SystemPrompt $systemPrompt -ContextWindow $contextWindow -Threshold $compactThreshold -Model $model -Provider $provider
                    $round--
                    $retryCount = 0
                    continue
                }
                else {
                    Write-ErrorPS "API Error: $apiError"
                    Write-AgentError -Error "API call failed: $apiError"
                    $continueLoop = $false
                    break
                }
            }

            $apiElapsed = ((Get-Date) - $apiStart).TotalSeconds
            Write-ThinkingDone
            $retryCount = 0

            if (-not $response) {
                Write-ErrorPS "No response received from API"
                $continueLoop = $false
                break
            }

            # Process response
            $assistantMsg = $response.choices[0].message
            $hasToolCalls = $assistantMsg.tool_calls -and $assistantMsg.tool_calls.Count -gt 0

            # Build assistant message for history
            $assistantHistory = @{ role = "assistant"; content = $assistantMsg.content }
            if ($hasToolCalls) {
                $assistantHistory.tool_calls = $assistantMsg.tool_calls
            }
            $messages += $assistantHistory

            # Display AI text
            if ($assistantMsg.content -and $assistantMsg.content.Trim()) {
                Write-AssistantMessage -Message $assistantMsg.content
            }

            # Execute tools if any
            if ($hasToolCalls) {
                foreach ($toolCall in $assistantMsg.tool_calls) {
                    $toolId = $toolCall.id
                    $toolName = $toolCall.function.name
                    $toolArgs = @{}
                    try {
                        $parsedArgs = ($toolCall.function.arguments | ConvertFrom-Json) | Convert-PSObjectToHashtable
                        if ($parsedArgs) { $toolArgs = $parsedArgs }
                    } catch {}

                    # Narrate what tool is about to do
                    $toolDesc = switch ($toolName) {
                        "execute_powershell" { if ($toolArgs.command) { "Executing: $($toolArgs.command)" } else { "Executing PowerShell command" } }
                        "read_file" { if ($toolArgs.path) { "Reading file: $($toolArgs.path)" } else { "Reading a file" } }
                        "write_file" { if ($toolArgs.path) { "Writing file: $($toolArgs.path)" } else { "Writing a file" } }
                        "edit_file" { if ($toolArgs.path) { "Editing file: $($toolArgs.path)" } else { "Editing a file" } }
                        "search_files" { if ($toolArgs.pattern) { "Searching for: $($toolArgs.pattern)" } else { "Searching files" } }
                        "glob_files" { if ($toolArgs.pattern) { "Finding files matching: $($toolArgs.pattern)" } else { "Finding files" } }
                        "list_directory" { if ($toolArgs.path) { "Listing directory: $($toolArgs.path)" } else { "Listing current directory" } }
                        "web_search" { if ($toolArgs.query) { "Searching web for: $($toolArgs.query)" } else { "Searching the web" } }
                        "web_fetch" { if ($toolArgs.url) { "Fetching URL: $($toolArgs.url)" } else { "Fetching a URL" } }
                        "auto_heal" { "Analyzing error and finding fix" }
                        "learn_from_error" { "Learning from this error for next time" }
                        "find_solution" { "Searching for a previous solution" }
                        "list_skills" { "Listing available skills" }
                        "read_skill" { if ($toolArgs.skillName) { "Loading skill: $($toolArgs.skillName)" } else { "Loading a skill" } }
                        "save_learning" { if ($toolArgs.category) { "Saving learning: $($toolArgs.category)" } else { "Saving learning" } }
                        default { "Using tool: $toolName" }
                    }
                    Write-AgentAction -Action $toolDesc

                    Write-ToolCall -ToolName $toolName -Arguments $toolCall.function.arguments

                    # Check permissions
                    $needsApproval = Test-ToolNeedsApproval -ToolName $toolName -Arguments $toolArgs
                    $approved = $true

                    if ($needsApproval) {
                        $desc = "Execute '$toolName'"
                        if ($toolName -eq "execute_powershell" -and $toolArgs.command) {
                            $desc = "Execute: $($toolArgs.command)"
                        } elseif ($toolName -eq "write_file") {
                            $desc = "Write: $($toolArgs.path)"
                        } elseif ($toolName -eq "edit_file") {
                            $desc = "Edit: $($toolArgs.path)"
                        }
                        $decision = Confirm-Action -Message $desc
                        if ($decision -eq "no") {
                            $approved = $false
                        } elseif ($decision -eq "always") {
                            Set-ToolAlwaysApproved -ToolName $toolName
                        }
                    }

                    # Execute tool
                    if ($approved) {
                        # Fire PreToolUse hook (can block execution)
                        $hookAllowed = Invoke-PreToolUseHook -ToolName $toolName -ToolInput $toolArgs -SessionId $sessionId

                        if ($hookAllowed -eq $false) {
                            $result = "Blocked by PreToolUse hook."
                            Write-AgentError -Error "Hook blocked $toolName"
                        } else {
                            $result = Invoke-PSCoderTool -ToolName $toolName -Arguments $toolArgs -WorkingDir $workingDir -ReadFileState $readFileState

                            # Fire PostToolUse hook
                            Invoke-PostToolUseHook -ToolName $toolName -ToolInput $toolArgs -ToolOutput $result -IsError $false -SessionId $sessionId
                        }

                        # Track read files for read-before-write enforcement
                        if ($toolName -eq "read_file" -and $toolArgs.path) {
                            $absPath = if ([System.IO.Path]::IsPathRooted($toolArgs.path)) { $toolArgs.path } else { Join-Path $workingDir $toolArgs.path }
                            try {
                                $readFileState[$absPath] = @{
                                    mtime = (Get-Item $absPath).LastWriteTime
                                    content = if ($result.Length -gt 1000) { $result.Substring(0, 1000) } else { $result }
                                }
                            } catch {}
                        }

                        # Show skill content when a skill is loaded
                        if ($toolName -eq "read_skill" -and $result -notmatch "^ERROR") {
                            $skillName = if ($toolArgs.skillName) { $toolArgs.skillName } else { "unknown" }
                            $skillDesc = ""
                            $skillTools = ""
                            $skillWorkflow = ""
                            if ($result -match '(?s)## Description\s*\r?\n(.+?)\r?\n##') { $skillDesc = $Matches[1].Trim() -replace '\r?\n', ' ' }
                            if ($result -match '(?s)## Tools to use\s*\r?\n(.+?)\r?\n##') { $skillTools = $Matches[1].Trim() -replace '\r?\n', ', ' }
                            if ($result -match '(?s)## Workflow\s*\r?\n(.+?)\r?\n##') { $skillWorkflow = $Matches[1].Trim() -replace '\r?\n', ' | ' }
                            $skillSummary = "SKILL: $skillName"
                            if ($skillDesc) { $skillSummary += " | $skillDesc" }
                            if ($skillTools) { $skillSummary += " | Tools: $skillTools" }
                            if ($skillWorkflow) { $skillSummary += " | Steps: $skillWorkflow" }
                            Write-InfoPS $skillSummary
                        }

                        # Truncate large tool results (tool result budget)
                        if ($result.Length -gt $toolResultBudget) {
                            $truncatedResult = $result.Substring(0, $toolResultBudget) + "`n... (output truncated, $([Math]::Round($result.Length/1KB, 1))KB total)"
                            $tempFile = Join-Path $env:TEMP "pscoder_tool_result_$([guid]::NewGuid().ToString().Substring(0,8)).txt"
                            $result | Set-Content -Path $tempFile -Encoding UTF8
                            $truncatedResult += "`nFull output saved to: $tempFile"
                            $result = $truncatedResult
                        }

                        # Narrate result
                        $resultSummary = if ($result.Length -gt 100) { $result.Substring(0, 100) + "..." } else { $result }
                        Write-AgentResult -Result "$toolName completed: $resultSummary"

                        Write-ToolResult -ToolName $toolName -Result $result -Success $true
                        $toolResultCount++
                    } else {
                        $result = "User rejected execution of this tool."
                        Write-AgentError -Error "User rejected the action"
                        Write-ToolResult -ToolName $toolName -Result $result -Success $false

                        # Still fire PostToolUse hook for rejected tools
                        Invoke-PostToolUseHook -ToolName $toolName -ToolInput $toolArgs -ToolOutput $result -IsError $true -SessionId $sessionId
                    }

                    # Add result to history
                    $messages += @{
                        role = "tool"
                        tool_call_id = $toolId
                        content = $result
                    }

                    # Check tool result budget
                    if ($toolResultCount -ge $maxToolResultsPerTurn) {
                        Write-InfoPS "Tool result limit reached for this turn. Compacting."
                        $messages = Invoke-AutoCompact -Messages $messages -SystemPrompt $systemPrompt -ContextWindow $contextWindow -Threshold $compactThreshold -Model $model -Provider $provider
                        $toolResultCount = 0
                    }
                }
            }
            else {
                # No more tools, end turn - fire Stop hook
                Invoke-StopHook -AssistantMessage $assistantMsg.content -SessionId $sessionId
                $continueLoop = $false
            }

            # Update tokens and cost
            if ($response.usage) {
                $totalTokens += $response.usage.total_tokens
                $sessionCost += Get-EstimatedCost -Model $model -Tokens $response.usage.total_tokens -Provider $provider
            }
        }

        if ($round -ge $maxRounds) {
            Write-InfoPS "Tool iteration limit reached."
        }

        # Stop hooks: extract memories, auto-dream
        Invoke-StopHooks -Messages $messages -WorkingDir $workingDir

        # Show status bar after each turn
        Write-StatusBar -Model $model -Tokens $totalTokens -Turn $turnCount -Provider $provider -Cost $sessionCost
    }
}

# ============================================================
# Token Estimation
# ============================================================

function Estimate-MessageTokens {
    param([object[]]$Messages)
    $totalChars = 0
    foreach ($msg in $Messages) {
        $totalChars += $msg.content.Length
        if ($msg.tool_calls) {
            $totalChars += ($msg.tool_calls | ConvertTo-Json -Depth 5 -Compress).Length
        }
    }
    return [Math]::Ceiling($totalChars / 4)
}

# ============================================================
# Cost Estimation (model-aware pricing)
# ============================================================

function Get-EstimatedCost {
    param(
        [string]$Model,
        [int]$Tokens,
        [string]$Provider = "openrouter"
    )

    # Approximate per-1K-token pricing (input+output blended average)
    # Free models
    if ($Model -match ":free$") { return 0.0 }

    # Model-specific pricing (per 1K tokens, blended avg)
    $pricing = @{
        "openai/gpt-4o" = 0.005
        "openai/gpt-4o-mini" = 0.0003
        "openai/o3-mini" = 0.0011
        "google/gemini-2.5-pro" = 0.0025
        "google/gemini-2.5-flash" = 0.00075
        "google/gemini-3-27b-it:free" = 0.0
        "meta-llama/llama-4-maverick" = 0.0002
        "meta-llama/llama-4-scout" = 0.0002
        "deepseek/deepseek-chat-v3" = 0.00027
        "deepseek/deepseek-r1" = 0.00055
        "qwen/qwen3.6-plus" = 0.0004
        "qwen/qwen-max" = 0.0016
        "mistralai/mistral-large" = 0.002
        "llama-3.3-70b-versatile" = 0.00059
        "llama-3.1-8b-instant" = 0.00004
        "llama-3.1-70b-versatile" = 0.00059
        "mixtral-8x7b-32768" = 0.00024
        "gemma2-9b-it" = 0.00007
        "qwen/qwen3-32b" = 0.00018
    }

    $rate = 0.001  # default fallback
    foreach ($key in $pricing.Keys) {
        if ($Model -match [regex]::Escape($key)) {
            $rate = $pricing[$key]
            break
        }
    }

    return ($Tokens / 1000) * $rate
}

# ============================================================
# Auto-Compact (improved: token-based, from claurst specs)
# ============================================================

function Invoke-AutoCompact {
    param(
        [object[]]$Messages,
        [string]$SystemPrompt,
        [int]$ContextWindow = 128000,
        [double]$Threshold = 0.85,
        [string]$Model = "",
        [string]$Provider = ""
    )

    $keepCount = 5
    if ($Messages.Count -le $keepCount) { return $Messages }

    $systemMsg = $Messages[0]
    $recentMessages = $Messages[-($keepCount - 1)..-1]

    $oldMessages = $Messages[1..($Messages.Count - $keepCount)]
    $oldText = ($oldMessages | ForEach-Object {
        if ($_.role -eq "tool") { return "[Tool result]" }
        return "$($_.role): $($_.content)"
    }) -join "`n"

    # Try to summarize via LLM if available
    $summary = $null
    if ($Model -and $Provider) {
        try {
            $summaryMessages = @(
                @{ role = "system"; content = "Summarize the following conversation in 3-5 sentences. Focus on key decisions, actions taken, and outcomes. Be concise." }
                @{ role = "user"; content = "Summarize this conversation history:`n`n$oldText" }
            )
            if ($Provider -eq "groq") {
                $summaryResp = Invoke-GroqChat -Model $Model -Messages $summaryMessages -MaxTokens 512 -Temperature 0.3
            } else {
                $summaryResp = Invoke-OpenRouterChat -Model $Model -Messages $summaryMessages -MaxTokens 512 -Temperature 0.3
            }
            if ($summaryResp -and $summaryResp.choices -and $summaryResp.choices[0].message.content) {
                $summary = "Previous conversation summary: $($summaryResp.choices[0].message.content)"
            }
        } catch {
            # Fallback if LLM summarization fails
            $summary = $null
        }
    }

    # Fallback hardcoded summary
    if (-not $summary) {
        $summary = "Previous conversation summary: The user asked about various topics and the assistant provided responses using available tools."
    }

    $compacted = @($systemMsg)
    $compacted += @{ role = "assistant"; content = $summary }
    $compacted += $recentMessages

    return $compacted
}

# ============================================================
# Stop Hooks
# ============================================================

function Invoke-StopHooks {
    param(
        [object[]]$Messages,
        [string]$WorkingDir
    )

    # Auto memory decision: analyze conversation and save valuable info
    if (Get-Command Invoke-MemoryDecision -ErrorAction SilentlyContinue) {
        $memoryResult = Invoke-MemoryDecision -Messages $Messages -WorkingDir $WorkingDir
        if ($memoryResult -notmatch "Nothing valuable to save") {
            Write-InfoPS $memoryResult
        }
    }
}
