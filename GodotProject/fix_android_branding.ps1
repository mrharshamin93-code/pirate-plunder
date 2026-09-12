$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $projectDir 'export_presets.cfg'
$assetsDir = Join-Path $projectDir 'assets'
$sourceIcon = Join-Path $assetsDir 'pirates-plunder-icon.png'
$mainIcon = Join-Path $assetsDir 'android-main-fit.png'
$adaptiveForeground = Join-Path $assetsDir 'android-adaptive-foreground-fit.png'
$systemSplash = Join-Path $assetsDir 'android-system-splash-fit.png'

if (-not (Test-Path $target)) {
    throw "Missing Android export preset: $target"
}
if (-not (Test-Path $sourceIcon)) {
    throw "Missing original Pirate's Plunder icon: $sourceIcon"
}

Add-Type -AssemblyName System.Drawing

function New-ContainPng {
    param(
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [Parameter(Mandatory=$true)][int]$CanvasSize,
        [Parameter(Mandatory=$true)][int]$MaxContentSize
    )

    $src = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $bitmap = New-Object System.Drawing.Bitmap($CanvasSize, $CanvasSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

                $scale = [Math]::Min($MaxContentSize / [double]$src.Width, $MaxContentSize / [double]$src.Height)
                $drawWidth = [int][Math]::Round($src.Width * $scale)
                $drawHeight = [int][Math]::Round($src.Height * $scale)
                $x = [int][Math]::Round(($CanvasSize - $drawWidth) / 2.0)
                $y = [int][Math]::Round(($CanvasSize - $drawHeight) / 2.0)

                $destRect = New-Object System.Drawing.Rectangle($x, $y, $drawWidth, $drawHeight)
                $graphics.DrawImage($src, $destRect)
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $src.Dispose()
    }
}

# Launcher artwork is intentionally smaller than before so Android's adaptive
# icon mask cannot crop the Pirate's Plunder artwork. Splash sizing stays exactly
# as previously approved.
New-ContainPng -SourcePath $sourceIcon -OutputPath $mainIcon -CanvasSize 432 -MaxContentSize 300
New-ContainPng -SourcePath $sourceIcon -OutputPath $adaptiveForeground -CanvasSize 432 -MaxContentSize 190
New-ContainPng -SourcePath $sourceIcon -OutputPath $systemSplash -CanvasSize 432 -MaxContentSize 210

$content = Get-Content -Raw -LiteralPath $target

# Explicit adaptive layers prevent Godot from falling back to the full-bleed
# project icon (which Android then masks and visually zooms/crops).
$content = [regex]::Replace($content, '(?m)^launcher_icons/main_192x192=.*$', 'launcher_icons/main_192x192="res://assets/android-main-fit.png"')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_foreground_432x432=.*$', 'launcher_icons/adaptive_foreground_432x432="res://assets/android-adaptive-foreground-fit.png"')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_background_432x432=.*$', 'launcher_icons/adaptive_background_432x432="res://assets/android-icon-bg.svg"')

# Keep the already-correct splash configuration unchanged.
$content = [regex]::Replace($content, '(?m)^splash_screen/disable_godot_boot_splash=.*$', 'splash_screen/disable_godot_boot_splash=false')
$content = [regex]::Replace($content, '(?m)^splash_screen/icon=.*$', 'splash_screen/icon="res://assets/android-system-splash-fit.png"')
$content = [regex]::Replace($content, '(?m)^splash_screen/background_color=.*$', 'splash_screen/background_color=Color(0.035, 0.11, 0.16, 1)')
$content = [regex]::Replace($content, '(?m)^splash_screen/branding_image=.*$', 'splash_screen/branding_image=""')

Set-Content -LiteralPath $target -Value $content -Encoding UTF8
Write-Host "Android branding updated."
Write-Host "Launcher icon scaled down for additional safe padding."
Write-Host "Splash screen sizing remains unchanged."
