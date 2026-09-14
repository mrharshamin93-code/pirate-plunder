$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginsDir = Join-Path $projectDir 'android\plugins'
$buildDir = Join-Path $projectDir 'android\build'
$presetPath = Join-Path $projectDir 'export_presets.cfg'
$googleServices = Join-Path $buildDir 'google-services.json'

New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$aarUrl = 'https://raw.githubusercontent.com/damnedpie/godot-firebase-analytics/main/release/godot4/GodotFirebaseAnalytics.23.2.0.release.aar'
$gdapUrl = 'https://raw.githubusercontent.com/damnedpie/godot-firebase-analytics/main/release/godot4/GodotFirebaseAnalytics.gdap'
$aarPath = Join-Path $pluginsDir 'GodotFirebaseAnalytics.23.2.0.release.aar'
$gdapPath = Join-Path $pluginsDir 'GodotFirebaseAnalytics.gdap'

Write-Host 'Downloading Godot Firebase Analytics Android plugin...'
Invoke-WebRequest -Uri $aarUrl -OutFile $aarPath
Invoke-WebRequest -Uri $gdapUrl -OutFile $gdapPath

if (Test-Path $presetPath) {
    $content = Get-Content -Raw -LiteralPath $presetPath
    if ($content -match '(?m)^plugins/GodotFirebaseAnalytics=') {
        $content = [regex]::Replace($content, '(?m)^plugins/GodotFirebaseAnalytics=.*$', 'plugins/GodotFirebaseAnalytics=true')
    }
    else {
        # Godot Android export presets keep plugin toggles alongside the other
        # Android options. Appending the toggle is accepted by the preset parser.
        $content = $content.TrimEnd() + "`r`nplugins/GodotFirebaseAnalytics=true`r`n"
    }
    Set-Content -LiteralPath $presetPath -Value $content -Encoding UTF8
    Write-Host 'Enabled GodotFirebaseAnalytics in export_presets.cfg.'
}
else {
    Write-Warning 'export_presets.cfg was not found. Open Godot -> Project -> Export -> Android and enable GodotFirebaseAnalytics manually.'
}

if (Test-Path $googleServices) {
    Write-Host 'google-services.json found.'
}
else {
    Write-Warning 'google-services.json is still required.'
    Write-Host 'Download the Android google-services.json from Firebase project pirate-s-plunder-98456 and place it here:'
    Write-Host $googleServices
}

Write-Host ''
Write-Host 'Firebase Analytics plugin files installed.'
Write-Host 'After google-services.json is present, restart Godot and rebuild the Android app.'
