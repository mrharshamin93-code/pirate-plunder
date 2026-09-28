param([string]$AndroidSdkPath)

$ErrorActionPreference = "Stop"

$godotRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $godotRoot
$patchFile = Join-Path $godotRoot "addons/AdmobPlugin/android-patches/custom-banner-v5.1.patch"
$buildRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("godot-admob-" + [guid]::NewGuid().ToString("N"))
$sourceRoot = Join-Path $buildRoot "godot-admob"

if ([string]::IsNullOrWhiteSpace($AndroidSdkPath)) {
	$AndroidSdkPath = $env:ANDROID_SDK_ROOT
}
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath)) {
	$AndroidSdkPath = $env:ANDROID_HOME
}
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath) -and $env:APPDATA) {
	$godotSettings = Join-Path $env:APPDATA "Godot/editor_settings-4.tres"
	if (Test-Path $godotSettings) {
		$match = [regex]::Match((Get-Content $godotSettings -Raw), '(?m)^export/android/android_sdk_path\s*=\s*"([^"]+)"')
		if ($match.Success) { $AndroidSdkPath = $match.Groups[1].Value }
	}
}
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath) -and $env:LOCALAPPDATA) {
	$defaultSdk = Join-Path $env:LOCALAPPDATA "Android/Sdk"
	if (Test-Path $defaultSdk) { $AndroidSdkPath = $defaultSdk }
}
if ([string]::IsNullOrWhiteSpace($AndroidSdkPath) -or -not (Test-Path $AndroidSdkPath)) {
	throw "Android SDK not found. Set ANDROID_HOME or pass -AndroidSdkPath with the Android SDK folder shown in Godot Editor Settings > Export > Android."
}
$env:ANDROID_HOME = $AndroidSdkPath
$env:ANDROID_SDK_ROOT = $AndroidSdkPath

try {
	& git clone --depth 1 --branch v5.1 https://github.com/godot-sdk-integrations/godot-admob.git $sourceRoot
	if ($LASTEXITCODE -ne 0) { throw "Could not clone the AdMob plugin source." }

	& git -C $sourceRoot apply $patchFile
	if ($LASTEXITCODE -ne 0) { throw "Could not apply the compact-banner patch." }

	$androidRoot = Join-Path $sourceRoot "android"
	$gradleWrapper = Join-Path $androidRoot "gradlew.bat"
	& $gradleWrapper --project-dir $androidRoot :admob:assembleDebug :admob:assembleRelease
	if ($LASTEXITCODE -ne 0) { throw "The AdMob Android plugin build failed." }

	$aarRoot = Join-Path $sourceRoot "android/admob/build/outputs/aar"
	Copy-Item (Join-Path $aarRoot "AdmobPlugin-debug.aar") (Join-Path $godotRoot "addons/AdmobPlugin/bin/debug/AdmobPlugin-debug.aar") -Force
	Copy-Item (Join-Path $aarRoot "AdmobPlugin-release.aar") (Join-Path $godotRoot "addons/AdmobPlugin/bin/release/AdmobPlugin-release.aar") -Force
	Write-Host "Custom-size AdMob plugin AARs installed from SDK $AndroidSdkPath. Reopen the Godot project before exporting Android."
} finally {
	if (Test-Path $buildRoot) { Remove-Item $buildRoot -Recurse -Force }
}
