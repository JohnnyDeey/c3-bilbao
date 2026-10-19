# install.ps1: build once, install on every connected phone, quietly
$ErrorActionPreference = "Continue"
$node = (Get-ChildItem "$env:USERPROFILE\node-v22.11.0-win-x64" -Recurse -Filter node.exe | Select-Object -First 1).DirectoryName
$jdk  = (Get-ChildItem "$env:USERPROFILE\OpenJDK21U-jdk_x64_windows_hotspot_21.0.12_8" -Recurse -Filter javac.exe | Select-Object -First 1).Directory.Parent.FullName
$env:JAVA_HOME    = $jdk
$env:ANDROID_HOME = "C:\Users\johndamilola.s\android-sdk"
$env:Path = "$node;$jdk\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
Set-Location C:\Users\johndamilola.s\c3-bilbao
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
$pkg = "es.c3bilbao.live"

# 1. Which phones are connected and authorised
$devs = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" } | ForEach-Object { ($_ -split "\t")[0] })
& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "unauthorized" } | ForEach-Object { Write-Host "! Phone $(($_ -split "\t")[0]) is waiting for 'Allow USB debugging' on its screen." -ForegroundColor Yellow }
if ($devs.Count -eq 0) { Write-Host "No phone ready. Connect by USB, turn on USB debugging and tap Allow." -ForegroundColor Red; return }
foreach ($d in $devs) {
  $name = (& $adb -s $d shell getprop ro.product.model).Trim()
  Write-Host "Found: $name ($d)"
}

# 2. Sync and build once, show the log only if it fails
Write-Host "Syncing..."
$out = npx cap sync android 2>&1
if ($LASTEXITCODE -ne 0) { $out | Select-Object -Last 15; Write-Host "Sync failed." -ForegroundColor Red; return }
Write-Host "Building..."
Push-Location android
$out = & .\gradlew.bat assembleDebug -q 2>&1
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) { $out | Select-Object -Last 20; Write-Host "Build failed." -ForegroundColor Red; return }

# 3. Install and open on each phone
$apk = "android\app\build\outputs\apk\debug\app-debug.apk"
foreach ($d in $devs) {
  $name = (& $adb -s $d shell getprop ro.product.model).Trim()
  $r = & $adb -s $d install -r $apk 2>&1
  if ($LASTEXITCODE -eq 0) {
    & $adb -s $d shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 *> $null
    Write-Host "Installed on $name" -ForegroundColor Green
  } else {
    Write-Host "Failed on $name" -ForegroundColor Red
    $r | Select-Object -Last 5
  }
}