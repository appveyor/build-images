$qt_base_dir = "C:\Qt\6.5.3\msvc2019_arm64\bin\"
$batch_files = @("qtpaths.bat", "qtpaths6.bat", "qmake.bat", "qmake6.bat")

$patch_content = @"
@echo off
C:\Qt\6.5.2\msvc2019_64\bin\qtpaths6.exe -qtconf "%~dp0\target_qt.conf" %*
"@

foreach ($file in $batch_files) {
  $substring = $file -replace '([^.6]*).*', '$1'
  $patch_content = @"
@echo off
C:\Qt\6.5.3\msvc2019_64\bin\${substring}6.exe -qtconf "%~dp0\target_qt.conf" %*
"@
  try {
      $full_path = $qt_base_dir + $file
      $patch_content | Set-Content -Path $full_path -Force
      Write-Host "File ${file} succesfully patched."
  } catch {
      Write-Host "File ${file} not patched."
  }
}