$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backup = Join-Path $projectDir 'export_presets.backup.cfg'
$target = Join-Path $projectDir 'export_presets.cfg'

if (-not (Test-Path $backup)) {
    throw "Missing backup preset: $backup"
}

$content = Get-Content -Raw -LiteralPath $backup

# Preserve the exact known-good V15 preset and only change the Android splash + next version/output.
$content = [regex]::Replace($content, '(?m)^version/code=.*$', 'version/code=16')
$content = [regex]::Replace($content, '(?m)^export_path=.*$', 'export_path="./Pirate''s PlunderV16.aab"')
$content = [regex]::Replace($content, '(?m)^splash_screen/disable_godot_boot_splash=.*$', 'splash_screen/disable_godot_boot_splash=true')
$content = [regex]::Replace($content, '(?m)^splash_screen/icon=.*$', 'splash_screen/icon="res://assets/android-splash-safe.svg"')
$content = [regex]::Replace($content, '(?m)^splash_screen/background_color=.*$', 'splash_screen/background_color=Color(0.035, 0.11, 0.16, 1)')
$content = [regex]::Replace($content, '(?m)^splash_screen/branding_image=.*$', 'splash_screen/branding_image=""')

Set-Content -LiteralPath $target -Value $content -Encoding UTF8
Write-Host "Updated $target from the V15 backup, preserving all other export settings."
Write-Host "Set version/code=16 and export path to Pirate's PlunderV16.aab."
Write-Host "Godot boot splash disabled; Android splash uses android-splash-safe.svg."
