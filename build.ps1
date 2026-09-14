# powersgell 一键构建脚本
# 需要: cobc (GnuCOBOL 3.3), gcc (mingw64), nasm
# 用法: .\build.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$src  = Join-Path $root "src"
Set-Location $root

# --- 路径探测（按需修改）---
$cobc = "C:\Users\Admin\AppData\Local\GnuCOBOL\bin\cobc.exe"
$gcc  = "C:\Users\Admin\AppData\Local\GnuCOBOL\mingw64\bin\gcc.exe"
$nasm = "D:\MiniGW\bin\nasm.exe"

foreach ($p in @($cobc, $gcc, $nasm)) {
    if (-not (Test-Path $p)) { Write-Host "MISSING TOOLCHAIN: $p"; exit 1 }
}

Write-Host "=== [1/4] C layer ==="
& $gcc -c -o psg_io.o   (Join-Path $src "psg_io.c")   2>&1 | Where-Object { $_ -match "error" } | ForEach-Object { Write-Host $_ }
& $gcc -c -o bfi.o      (Join-Path $src "bfi.c")      2>&1 | Where-Object { $_ -match "error" } | ForEach-Object { Write-Host $_ }
& $gcc -c -o psg_ctrl.o (Join-Path $src "psg_ctrl.c") 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object { Write-Host $_ }

Write-Host "=== [2/4] NASM layer ==="
& $nasm -f win64 -o psg_rand.obj (Join-Path $src "psg_rand.asm") 2>&1 | Out-Null
Copy-Item psg_rand.obj psg_rand.o -Force   # cobc 不认 .obj

Write-Host "=== [3/4] COBOL layer ==="
# GnuCOBOL 在 Windows 按 ANSI 代码页读源码; 源码里的中文注释需要 GBK
$cobSrc = Join-Path $src "powersgell.cob"
$tmpSrc = Join-Path $root "powersgell_build.cob"
$txt = [System.IO.File]::ReadAllText($cobSrc, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($tmpSrc, $txt, [System.Text.Encoding]::GetEncoding(936))

Remove-Item psg_shell.o, powersgell.exe -Force -ErrorAction SilentlyContinue
# 注意: -c 和 -x 必须同时给, 否则报 undefined reference to WinMain
& $cobc -c -x -o psg_shell.o $tmpSrc 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object { Write-Host $_ }

Write-Host "=== [4/4] link 4 languages into one exe ==="
& $cobc -x -o powersgell.exe psg_shell.o psg_rand.o psg_io.o bfi.o psg_ctrl.o 2>&1 | Where-Object { $_ -match "error|undefined" } | ForEach-Object { Write-Host $_ }

if (Test-Path (Join-Path $root "powersgell.exe")) {
    Write-Host ("BUILD OK  " + (Get-Item (Join-Path $root "powersgell.exe")).Length + " bytes")
    Write-Host "run:  .\powersgell.exe"
} else {
    Write-Host "BUILD FAILED"
    exit 1
}
