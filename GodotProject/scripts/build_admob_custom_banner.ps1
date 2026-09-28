$ErrorActionPreference = "Stop"

$godotRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $godotRoot
$patchFile = Join-Path $godotRoot "addons/AdmobPlugin/android-patches/custom-banner-v5.1.patch"
$buildRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("godot-admob-" + [guid]::NewGuid().ToString("N"))
$sourceRoot = Join-Path $buildRoot "godot-admob"

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
	Write-Host "Custom-size AdMob plugin AARs installed. Reopen the Godot project before exporting Android."
} finally {
	if (Test-Path $buildRoot) { Remove-Item $buildRoot -Recurse -Force }
}
