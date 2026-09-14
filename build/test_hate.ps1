$ErrorActionPreference = "Continue"
$d = "E:\OpenClaw\.openclaw\workspace\powersgell"
Set-Location $d
$gcc = "C:\Users\Admin\AppData\Local\GnuCOBOL\mingw64\bin\gcc.exe"

Write-Host "=== TEST A: Windows host + POSIX headers ==="
& $gcc -fsyntax-only -DPSG_HOST_WINDOWS -DPSG_HOST_LINUX -DPSG_HOST_BSD -DPSG_WANT_LINUX -DPSG_ALLOW_BUILD -include src/platform_hate.h -xc /dev/null 2>&1 | Select-Object -First 6 | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "=== TEST B: without platform macros ==="
& $gcc -fsyntax-only -include src/platform_hate.h -xc /dev/null 2>&1 | Select-Object -First 5 | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "=== TEST C: all three platform macros, no WANT ==="
& $gcc -fsyntax-only -DPSG_HOST_WINDOWS -DPSG_HOST_LINUX -DPSG_HOST_BSD -include src/platform_hate.h -xc /dev/null 2>&1 | Select-Object -First 6 | ForEach-Object { Write-Host $_ }
