$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $projectDir 'export_presets.cfg'

if (-not (Test-Path $target)) {
    throw "Missing Android export preset: $target"
}

$content = Get-Content -Raw -LiteralPath $target

# Change only Android launcher/splash branding. Do not touch version, signing,
# architectures, Gradle, permissions, package name, or export path.
$content = [regex]::Replace($content, '(?m)^launcher_icons/main_192x192=.*$', 'launcher_icons/main_192x192="res://assets/android-launcher-safe.svg"')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_foreground_432x432=.*$', 'launcher_icons/adaptive_foreground_432x432="res://assets/android-launcher-safe.svg"')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_background_432x432=.*$', 'launcher_icons/adaptive_background_432x432="res://assets/android-icon-bg.svg"')
$content = [regex]::Replace($content, '(?m)^splash_screen/disable_godot_boot_splash=.*$', 'splash_screen/disable_godot_boot_splash=false')
$content = [regex]::Replace($content, '(?m)^splash_screen/icon=.*$', 'splash_screen/icon="res://assets/android-splash-safe.svg"')
$content = [regex]::Replace($content, '(?m)^splash_screen/background_color=.*$', 'splash_screen/background_color=Color(0.035, 0.11, 0.16, 1)')
$content = [regex]::Replace($content, '(?m)^splash_screen/branding_image=.*$', 'splash_screen/branding_image=""')

Set-Content -LiteralPath $target -Value $content -Encoding UTF8
Write-Host "Android branding updated without changing version/signing/build settings."
Write-Host "Launcher icon uses padded safe-zone artwork."
Write-Host "Android system splash uses safe-zone artwork."
Write-Host "Pirate's Plunder Godot boot splash is explicitly enabled."
