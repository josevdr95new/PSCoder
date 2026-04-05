# OcrImage.ps1 - Extract text from images using Windows OCR
# Uses Windows.Media.Ocr (built into Windows 10/11) - no installation needed

$Script:OcrEngine = $null
$Script:OcrAvailable = $false
$Script:OcrLanguages = @()

function Initialize-OcrEngine {
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue
        $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
        $null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
        $null = [Windows.Foundation.IAsyncOperation`1, Windows.Foundation, ContentType = WindowsRuntime]
        $null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Foundation, ContentType = WindowsRuntime]
        $null = [Windows.Storage.Streams.RandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]

        # Get available languages
        $Script:OcrLanguages = [Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages | ForEach-Object { $_.LanguageTag }

        # Create engine with user profile languages
        $Script:OcrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        $Script:OcrAvailable = $null -ne $Script:OcrEngine

        return @{
            available = $Script:OcrAvailable
            languages = $Script:OcrLanguages
            currentLanguage = if ($Script:OcrEngine) { $Script:OcrEngine.RecognizerLanguage.LanguageTag } else { $null }
        }
    } catch {
        $Script:OcrAvailable = $false
        return @{ available = $false; error = $_.Exception.Message }
    }
}

function Create-OcrEngine {
    param([string]$LanguageTag = "")

    try {
        if ($LanguageTag) {
            $lang = [Windows.Globalization.Language]::new($LanguageTag)
            $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
            if ($engine) { return $engine }
        }

        # Fallback to user profile languages
        return [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    } catch {
        return $null
    }
}

function Await-WinRTOperation {
    param($AsyncTask, [Type]$ResultType)

    $getAwaiterBaseMethod = [WindowsRuntimeSystemExtensions].GetMember('GetAwaiter').Where({
        $PSItem.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    }, 'First')[0]

    $awaiter = $getAwaiterBaseMethod.MakeGenericMethod($ResultType).Invoke($null, @($AsyncTask))
    return $awaiter.GetResult()
}

function Invoke-OcrImage {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Language = ""
    )

    # Resolve path
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Location).Path $Path
    }

    if (-not (Test-Path $Path)) {
        return "ERROR: Image file not found: $Path"
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $supportedExts = @('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff', '.tif', '.webp')
    if ($ext -notin $supportedExts) {
        return "ERROR: Unsupported image format: $ext. Supported: $($supportedExts -join ', ')"
    }

    # Initialize OCR if needed
    if (-not $Script:OcrAvailable) {
        $init = Initialize-OcrEngine
        if (-not $init.available) {
            $errorMsg = "Windows OCR is not available on this system.`n"
            $errorMsg += "Requirements: Windows 10 version 1809 or later.`n"
            $errorMsg += "Error: $($init.error)"
            return "ERROR: $errorMsg"
        }
    }

    # Create engine with specified language if needed
    $engine = $Script:OcrEngine
    if ($Language -and $Language -ne $Script:OcrEngine.RecognizerLanguage.LanguageTag) {
        $engine = Create-OcrEngine -LanguageTag $Language
        if (-not $engine) {
            return "ERROR: OCR language '$Language' not available. Available: $($Script:OcrLanguages -join ', ')"
        }
    }

    $startTime = Get-Date

    try {
        # Load image using WinRT async pattern
        $storageFile = Await-WinRTOperation -AsyncTask ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) -ResultType ([Windows.Storage.StorageFile])
        $fileStream = Await-WinRTOperation -AsyncTask ($storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)) -ResultType ([Windows.Storage.Streams.IRandomAccessStream])
        $bitmapDecoder = Await-WinRTOperation -AsyncTask ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($fileStream)) -ResultType ([Windows.Graphics.Imaging.BitmapDecoder])
        $softwareBitmap = Await-WinRTOperation -AsyncTask ($bitmapDecoder.GetSoftwareBitmapAsync()) -ResultType ([Windows.Graphics.Imaging.SoftwareBitmap])

        # Run OCR
        $ocrResult = Await-WinRTOperation -AsyncTask ($engine.RecognizeAsync($softwareBitmap)) -ResultType ([Windows.Media.Ocr.OcrResult])

        $elapsed = ((Get-Date) - $startTime).TotalSeconds

        # Extract text
        $fullText = $ocrResult.Text.Trim()

        if (-not $fullText) {
            return "No text detected in image: $Path`n`nThe image may not contain readable text, or the text quality is too low."
        }

        # Count lines and words
        $lineCount = ($fullText -split "`n" | Where-Object { $_.Trim() }).Count
        $wordCount = ($fullText -split '\s+' | Where-Object { $_.Trim() }).Count

        # Build output
        $output = "OCR Result: $(Split-Path $Path -Leaf)`n"
        $output += "=" * 60 + "`n"
        $output += "Language: $($engine.RecognizerLanguage.LanguageTag) | "
        $output += "Lines: $lineCount | Words: $wordCount | "
        $output += "Time: $($elapsed.ToString('F2'))s`n"
        $output += "-" * 60 + "`n`n"
        $output += $fullText

        return $output
    } catch {
        return "ERROR: OCR processing failed for $Path`n$($_.Exception.Message)"
    }
}
