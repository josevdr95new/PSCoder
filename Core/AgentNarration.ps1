# AgentNarration.ps1 - Agent narration and speech system for PSCoder
# Narrates agent thoughts/actions/results visually and via Windows Speech

$Script:AgentNarrationEnabled = $true
$Script:SpeechEnabled = $true
$Script:SpeechVoice = $null
$Script:SpeechRate = 0
$Script:SpeechVolume = 100

function Initialize-AgentSpeech {
    try {
        $Script:SpeechVoice = New-Object -ComObject SAPI.SpVoice
        $Script:SpeechVoice.Rate = $Script:SpeechRate
        $Script:SpeechVoice.Volume = $Script:SpeechVolume
        return $true
    } catch {
        $Script:SpeechVoice = $null
        return $false
    }
}

function Speak-Text {
    param([string]$Text)
    if ($Script:SpeechEnabled -and $Script:SpeechVoice) {
        try {
            $null = $Script:SpeechVoice.Speak($Text, 1)
        } catch {}
    }
}

function Write-AgentThought {
    param([string]$Thought, [bool]$Speak = $true)
    if (-not $Script:AgentNarrationEnabled) { return }
    Write-Host ""
    Write-Host "  [Thinking] " -NoNewline -ForegroundColor Cyan
    Write-Host $Thought -ForegroundColor Cyan
    if ($Speak) {
        Speak-Text -Text $Thought
    }
}

function Write-AgentAction {
    param([string]$Action, [bool]$Speak = $true)
    if (-not $Script:AgentNarrationEnabled) { return }
    Write-Host ""
    Write-Host "  [Action] " -NoNewline -ForegroundColor Yellow
    Write-Host $Action -ForegroundColor Yellow
    if ($Speak) {
        Speak-Text -Text $Action
    }
}

function Write-AgentResult {
    param([string]$Result, [bool]$Speak = $true)
    if (-not $Script:AgentNarrationEnabled) { return }
    Write-Host ""
    Write-Host "  [Result] " -NoNewline -ForegroundColor Green
    Write-Host $Result -ForegroundColor Green
    if ($Speak) {
        Speak-Text -Text $Result
    }
}

function Write-AgentError {
    param([string]$Error, [bool]$Speak = $true)
    if (-not $Script:AgentNarrationEnabled) { return }
    Write-Host ""
    Write-Host "  [Error] " -NoNewline -ForegroundColor Red
    Write-Host $Error -ForegroundColor Red
    if ($Speak) {
        Speak-Text -Text "Error: $Error"
    }
}

function Set-AgentNarration {
    param([bool]$Enabled)
    $Script:AgentNarrationEnabled = $Enabled
    if ($Enabled -and -not $Script:SpeechVoice -and $Script:SpeechEnabled) {
        Initialize-AgentSpeech
    }
    $status = if ($Enabled) { "enabled" } else { "disabled" }
    Write-Host "  " -NoNewline
    Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
    Write-Host "Narration $status" -ForegroundColor Magenta
}

function Set-AgentSpeech {
    param([bool]$Enabled)
    $Script:SpeechEnabled = $Enabled
    if ($Enabled -and -not $Script:SpeechVoice) {
        $success = Initialize-AgentSpeech
        if ($success) {
            Write-Host "  " -NoNewline
            Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
            Write-Host "Speech enabled" -ForegroundColor Magenta
        } else {
            Write-Host "  " -NoNewline
            Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
            Write-Host "Speech not available on this system" -ForegroundColor Yellow
        }
    } else {
        $status = if ($Enabled) { "enabled" } else { "disabled" }
        Write-Host "  " -NoNewline
        Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
        Write-Host "Speech $status" -ForegroundColor Magenta
    }
}

function Get-AgentStatus {
    $status = @{
        narration = $Script:AgentNarrationEnabled
        speech = $Script:SpeechEnabled
        speechAvailable = [bool]$Script:SpeechVoice
        rate = $Script:SpeechRate
        volume = $Script:SpeechVolume
    }
    Write-Host ""
    Write-Host "  === Agent Status ===" -ForegroundColor Magenta
    Write-Host "  Narration: " -NoNewline -ForegroundColor Gray
    $nColor = if ($Script:AgentNarrationEnabled) { "Green" } else { "Red" }
    Write-Host $(if ($Script:AgentNarrationEnabled) { "ON" } else { "OFF" }) -ForegroundColor $nColor
    Write-Host "  Speech: " -NoNewline -ForegroundColor Gray
    $sColor = if ($Script:SpeechEnabled) { "Green" } else { "Red" }
    Write-Host $(if ($Script:SpeechEnabled) { "ON" } else { "OFF" }) -ForegroundColor $sColor
    Write-Host "  Speech Available: " -NoNewline -ForegroundColor Gray
    $avail = if ($Script:SpeechVoice) { "Yes" } else { "No" }
    Write-Host $avail -ForegroundColor $(if ($Script:SpeechVoice) { "Green" } else { "Yellow" })
    Write-Host "  Rate: $($Script:SpeechRate) | Volume: $($Script:SpeechVolume)" -ForegroundColor Gray
    return $status
}

function Test-AgentSpeech {
    param([string]$Text = "Hello, I am PSCoder, your AI assistant.")
    if (-not $Script:SpeechVoice) {
        $success = Initialize-AgentSpeech
        if (-not $success) {
            Write-Host "  " -NoNewline
            Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
            Write-Host "Speech not available on this system" -ForegroundColor Yellow
            return
        }
    }
    Write-Host "  " -NoNewline
    Write-Host "[Agent] " -NoNewline -ForegroundColor Magenta
    Write-Host "Speaking: $Text" -ForegroundColor Magenta
    Speak-Text -Text $Text
}

# Initialize speech on load
Initialize-AgentSpeech | Out-Null
