$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $projectDir 'export_presets.cfg'

if (-not (Test-Path $target)) {
    throw "Missing Android export preset: $target"
}

$content = Get-Content -Raw -LiteralPath $target

# Keep the ORIGINAL Pirate's Plunder icon artwork. Do not replace it with a
# redrawn/safe-zone logo. Leaving adaptive layers empty makes Android fall back
# to the legacy icon instead of masking/cropping a different foreground asset.
$content = [regex]::Replace($content, '(?m)^launcher_icons/main_192x192=.*$', 'launcher_icons/main_192x192="res://assets/pirates-plunder-icon.png"')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_foreground_432x432=.*$', 'launcher_icons/adaptive_foreground_432x432=""')
$content = [regex]::Replace($content, '(?m)^launcher_icons/adaptive_background_432x432=.*$', 'launcher_icons/adaptive_background_432x432=""')

# Preserve the working Pirate's Plunder splash configuration.
$content = [regex]::Replace($content, '(?m)^splash_screen/disable_godot_boot_splash=.*$', 'splash_screen/disable_godot_boot_splash=false')
$content = [regex]::Replace($content, '(?m)^splash_screen/icon=.*$', 'splash_screen/icon="res://assets/android-splash-safe.svg"')
$content = [regex]::Replace($content, '(?m)^splash_screen/background_color=.*$', 'splash_screen/background_color=Color(0.035, 0.11, 0.16, 1)')
$content = [regex]::Replace($content, '(?m)^splash_screen/branding_image=.*$', 'splash_screen/branding_image=""')

Set-Content -LiteralPath $target -Value $content -Encoding UTF8
Write-Host "Android branding updated without changing version/signing/build settings."
Write-Host "Launcher icon restored to the ORIGINAL pirates-plunder-icon.png artwork."
Write-Host "Adaptive icon overrides cleared so Android does not substitute the redrawn icon."
Write-Host "Pirate's Plunder splash remains enabled."
