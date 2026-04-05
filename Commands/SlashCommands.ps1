# SlashCommands.ps1 - Slash commands for PSCoder

function Invoke-SlashCommand {
    param(
        [string]$Command,
        [ref]$Model,
        [ref]$Messages,
        [ref]$Provider
    )

    $parts = $Command.Trim().Split(" ", 2, [System.StringSplitOptions]::RemoveEmptyEntries)
    $cmd = $parts[0].ToLower()
    $args = if ($parts.Count -gt 1) { $parts[1] } else { "" }

    switch ($cmd) {
        "/help" {
            Show-Help
            return "continue"
        }
        "/clear" {
            $workingDir = (Get-Location).Path
            $memory = Get-PSCoderMemory
            $prompt = Get-PSCoderSystemPrompt -WorkingDir $workingDir -MemoryContent $memory
            $Messages.Value = @(@{ role = "system"; content = $prompt })
            Write-InfoPS "Conversation cleared."
            return "clear"
        }
        "/new" { return "reload" }
        "/model" {
            if ($args) {
                $Model.Value = $args
                Set-PSCoderConfig -Updates @{ model = $args }
                Write-InfoPS "Model changed to: $args"
            } else {
                Write-HeaderPS "Available models"
                Write-Host "  [OpenRouter]" -ForegroundColor Cyan
                Get-ModelsList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                Write-Host "  [Groq]" -ForegroundColor Cyan
                Get-GroqModelsList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                Write-Host "  Current: $($Model.Value)" -ForegroundColor Yellow
            }
            return "continue"
        }
        "/provider" {
            if ($args) {
                $prov = $args.ToLower()
                if ($prov -in @("openrouter", "groq")) {
                    $Provider.Value = $prov
                    Set-PSCoderConfig -Updates @{ provider = $prov }
                    Write-InfoPS "Provider changed to: $prov"
                    if ($prov -eq "groq") {
                        Write-InfoPS "Default Groq model: qwen/qwen3-32b"
                        $Model.Value = "qwen/qwen3-32b"
                        Set-PSCoderConfig -Updates @{ model = "qwen/qwen3-32b" }
                    } else {
                        Write-InfoPS "Default OpenRouter model: stepfun/step-3.5-flash:free"
                        $Model.Value = "stepfun/step-3.5-flash:free"
                        Set-PSCoderConfig -Updates @{ model = "stepfun/step-3.5-flash:free" }
                    }
                } else {
                    Write-ErrorPS "Invalid provider. Use: openrouter or groq"
                }
            } else {
                Write-HeaderPS "Current provider: $($Provider.Value)"
                Write-Host "  Available providers:" -ForegroundColor Gray
                Write-Host "  - openrouter (GPT, Gemini, Qwen, Llama...)" -ForegroundColor Gray
                Write-Host "  - groq (Llama, Mixtral, Gemma, Qwen...)" -ForegroundColor Gray
                Write-Host "  Use /provider <name> to change" -ForegroundColor Gray
            }
            return "continue"
        }
        "/history" {
            Show-SessionHistory
            return "continue"
        }
        "/load" {
            if ($args) {
                Load-PSCoderSession -SessionId $args -Messages $Messages
            } else {
                Write-ErrorPS "Usage: /load <session-id>"
            }
            return "continue"
        }
        "/memory" {
            if ($args -eq "edit") {
                $memFile = (Get-PSCoderConfig).memoryFile
                Write-InfoPS "Opening memory at: $memFile"
                $editor = if ($env:EDITOR) { $env:EDITOR } else { "notepad.exe" }
                Start-Process $editor -ArgumentList $memFile
            } elseif ($args -eq "clear") {
                Set-PSCoderMemory -Content "# PSCoder Memory`n`n## User Info`n`n## Preferences`n`n## Projects`n"
                Write-InfoPS "Memory cleared."
            } elseif ($args.StartsWith("add ", [System.StringComparison]::OrdinalIgnoreCase)) {
                $note = $args.Substring(4).Trim()
                if ($note) {
                    Add-PSCoderMemoryNote -Note $note
                    Write-InfoPS "Added to memory: $note"
                } else {
                    Write-ErrorPS "Usage: /memory add <information>"
                }
            } else {
                Show-PSCoderMemory
            }
            return "continue"
        }
        "/tools" {
            Write-HeaderPS "Available Tools"
            $tools = Get-ToolNameList
            foreach ($tool in $tools) {
                Write-Host "  [+] $tool" -ForegroundColor Green
            }
            Write-Host ""
            Write-InfoPS "Tools are called automatically by the AI based on context."
            return "continue"
        }
        "/config" {
            $config = Get-PSCoderConfig
            Write-HeaderPS "Configuration"
            foreach ($key in $config.Keys | Sort-Object) {
                $val = $config[$key]
                $displayVal = if ($key -match "apiKey|Key") {
                    if ($val -and $val.Length -gt 8) { $val.Substring(0, 4) + "..." + $val.Substring($val.Length - 4) }
                    elseif ($val) { "***" }
                    else { "(not set)" }
                } else { $val }
                Write-Host "  $key = " -NoNewline -ForegroundColor Gray
                Write-Host "$displayVal" -ForegroundColor White
            }
            if ($args) {
                $parts2 = $args.Split(" ", 2)
                if ($parts2.Count -eq 2) {
                    $key = $parts2[0]
                    $val = $parts2[1]
                    # Try to convert boolean/number values
                    if ($val -eq "true") { $val = $true }
                    elseif ($val -eq "false") { $val = $false }
                    elseif ($val -match "^\d+$") { $val = [int]$val }
                    elseif ($val -match "^\d+\.\d+$") { $val = [double]$val }
                    Set-PSCoderConfig -Updates @{ $key = $val }
                    Write-InfoPS "Config updated: $key = $val"
                } else {
                    Write-ErrorPS "Usage: /config <key> <value>"
                }
            }
            return "continue"
        }
        "/exit" { return "exit" }
        "/quit" { return "exit" }
        "/narrate" {
            $nargs = $args.ToLower().Trim()
            if ($nargs -eq "on") {
                Set-AgentNarration -Enabled $true
                Set-PSCoderConfig -Updates @{ agentNarration = $true }
            } elseif ($nargs -eq "off") {
                Set-AgentNarration -Enabled $false
                Set-PSCoderConfig -Updates @{ agentNarration = $false }
            } elseif ($nargs -eq "voice") {
                Set-AgentSpeech -Enabled $true
                Set-PSCoderConfig -Updates @{ speechEnabled = $true }
            } elseif ($nargs -eq "novoice") {
                Set-AgentSpeech -Enabled $false
                Set-PSCoderConfig -Updates @{ speechEnabled = $false }
            } elseif ($nargs -eq "test") {
                Test-AgentSpeech
            } else {
                Get-AgentStatus
            }
            return "continue"
        }
        "/speak" {
            if ($args) {
                Test-AgentSpeech -Text $args
            } else {
                Test-AgentSpeech
            }
            return "continue"
        }
        "/pwd" {
            Write-InfoPS "Current directory: $((Get-Location).Path)"
            return "continue"
        }
        default {
            Write-ErrorPS "Unknown command: $cmd. Use /help to see commands."
            return "continue"
        }
    }
}

function Show-Help {
    Write-HeaderPS "PSCoder Commands"
    Write-Host "  /help          Show this help" -ForegroundColor Gray
    Write-Host "  /clear         Clear conversation" -ForegroundColor Gray
    Write-Host "  /new           New conversation (reload memory)" -ForegroundColor Gray
    Write-Host "  /model         Change AI model (e.g., /model openai/gpt-4o)" -ForegroundColor Gray
    Write-Host "  /model         No args: list available models" -ForegroundColor Gray
    Write-Host "  /provider      Change provider (openrouter/groq)" -ForegroundColor Gray
    Write-Host "  /provider      No args: show current provider" -ForegroundColor Gray
    Write-Host "  /history       List saved sessions" -ForegroundColor Gray
    Write-Host "  /load <id>     Load a previous session" -ForegroundColor Gray
    Write-Host "  /memory        Show long-term memory" -ForegroundColor Gray
    Write-Host "  /memory edit   Open memory file for editing" -ForegroundColor Gray
    Write-Host "  /memory clear  Clear memory" -ForegroundColor Gray
    Write-Host "  /memory add X  Add info to memory" -ForegroundColor Gray
    Write-Host "  /tools         List available tools" -ForegroundColor Gray
    Write-Host "  /config        Show configuration" -ForegroundColor Gray
    Write-Host "  /config <k> <v> Change a configuration" -ForegroundColor Gray
    Write-Host "  /narrate       Show agent narration status" -ForegroundColor Gray
    Write-Host "  /narrate on    Enable agent narration (visual + voice)" -ForegroundColor Gray
    Write-Host "  /narrate off   Disable agent narration" -ForegroundColor Gray
    Write-Host "  /narrate voice Enable voice only" -ForegroundColor Gray
    Write-Host "  /narrate test  Test voice output" -ForegroundColor Gray
    Write-Host "  /speak <text>  Speak custom text" -ForegroundColor Gray
    Write-Host "  /pwd           Show current directory" -ForegroundColor Gray
    Write-Host "  /exit          Save and exit" -ForegroundColor Gray
}
