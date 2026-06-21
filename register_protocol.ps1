$Protocol = "com.webspider.aquasort.mobile"
$ExePath = "C:\Users\vivek\.gemini\antigravity\scratch\aqua-sort-flutter\build\windows\x64\runner\Debug\AquaSort.exe"
$RegistryPath = "HKCU:\Software\Classes\$Protocol"

Write-Host "Registering protocol $Protocol for $ExePath"

if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force
}
New-ItemProperty -Path $RegistryPath -Name "(Default)" -Value "URL:$Protocol Protocol" -PropertyType String -Force
New-ItemProperty -Path $RegistryPath -Name "URL Protocol" -Value "" -PropertyType String -Force

$CommandPath = "$RegistryPath\shell\open\command"
if (-not (Test-Path $CommandPath)) {
    New-Item -Path $CommandPath -Force
}
New-ItemProperty -Path $CommandPath -Name "(Default)" -Value "`"$ExePath`" `"%1`"" -PropertyType String -Force

Write-Host "Protocol registered successfully."
