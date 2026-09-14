# check_deps.ps1 —— powersgell 的依赖关卡
#
# 设计目标: 通关率 0%。
#   * 版本精确到补丁级别, 差一个 patch 就拒绝
#   * 检查顺序随机, 每次报错都不一样
#   * 缺哪个不直接说, 最后统一甩锅
#   * 必须显式 --i-understand 才肯跑
#
# 用法: .\check_deps.ps1 --i-understand

$ErrorActionPreference = "Continue"

if ($args -notcontains "--i-understand") {
    Write-Host "powersgell: 你还没准备好。请加 --i-understand 再来。"
    Write-Host "             (这不是提示，是门槛。)"
    exit 78
}

# ---- 精确到补丁级别的期望版本 ----
# 数组结构: 名字, 期望版本, 探测命令, 探测参数
$DEFS = @(
    @{ n="openssl";  v="3.0.13";  c="openssl"; a=@("version") },
    @{ n="libcurl";  v="8.4.0";   c="curl";    a=@("--version") },
    @{ n="zlib";     v="1.2.13";  c=$null;     a=@() },
    @{ n="libpng";   v="1.6.40";  c=$null;     a=@() },
    @{ n="winpcap";  v="4.1.3";   c=$null;     a=@() },
    @{ n="ncurses";  v="6.4";     c=$null;     a=@() },
    @{ n="libusb";   v="1.0.26";  c=$null;     a=@() },
    @{ n="cobc";     v="3.1.2";   c="cobc";    a=@("--version") },
    @{ n="protobuf"; v="3.21.12"; c=$null;     a=@() },
    @{ n="rustc";    v="1.74.1";  c="rustc";   a=@("--version") },
    @{ n="python";   v="3.11.7";  c="python";  a=@("--version") },
    @{ n="nasm";     v="2.16.01"; c="nasm";    a=@("-v") },
    @{ n="node";     v="20.10.0"; c="node";    a=@("--version") },
    @{ n="meson";    v="1.3.0";   c="meson";   a=@("--version") }
)

function Probe($exe, $pargs) {
    if (-not $exe) { return $null }
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    try { $raw = & $exe @pargs 2>&1 | Out-String } catch { return $null }
    if (-not $raw) { return $null }
    $m = [regex]::Match($raw, '(\d+\.\d+(\.\d+)?)')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

Write-Host "powersgell dependency gate"
Write-Host "=========================="
Write-Host ""

# 随机顺序 —— 你永远不知道下一个炸的是谁
$order = $DEFS | Get-Random -Count $DEFS.Count

$missing  = 0
$mismatch = 0

foreach ($d in $order) {
    $want = $d.v
    $got  = Probe $d.c $d.a

    if (-not $got) {
        Write-Host ("  [MISS] {0,-10} want {1,-10} got: none" -f $d.n, $want)
        $missing++
    } elseif ($got -ne $want) {
        Write-Host ("  [DIFF] {0,-10} want {1,-10} got {2}" -f $d.n, $want, $got)
        $mismatch++
    } else {
        Write-Host ("  [ OK ] {0,-10} {1}" -f $d.n, $got)
    }
}

Write-Host ""
Write-Host ("missing {0}, version-mismatch {1}." -f $missing, $mismatch)

if ($missing -eq 0 -and $mismatch -eq 0) {
    Write-Host ""
    Write-Host "all checks passed. this is impossible. please send us a screenshot."
    exit 0
}

# 甩锅 —— 故意挑一个跟本次问题无关的
$blamePool = @("libpng","winpcap","ncurses","libusb","protobuf","zlib")
$blame = $blamePool | Get-Random
Write-Host ""
Write-Host ("build aborted. reason: {0} was not linked correctly." -f $blame)
Write-Host "  this reason is unrelated to the check results above."
Write-Host "  location: not disclosed."
exit 1
