# powersgell

> **P**ower**S**hell + ba**g**sh + she**ll** 缝合产物。
> 集百家之短。它不解决问题，它生产问题。

[English](#english) | 中文

---

## 这是什么

`powersgell` 是一个**故意难用**的命令行壳。它把 bash、PowerShell、CMD 三家最让人抓狂的缺陷
精挑细选缝进同一个解释器里，然后用**四种语言**实现它：

| 层 | 语言 | 职责 |
|---|---|---|
| 主循环 / 命令分发 / 字符串分析 | **COBOL** (GnuCOBOL 3.3) | `INSPECT ... TALLYING` 做变量失明检测 |
| 输入层 / BF 生成 / BF 解释器 / Ctrl+C 终结器 | **C** (mingw64 gcc) | 真正承重的活 |
| 随机骰子（决定静默失败还是假装报错） | **NASM** (x86-64) | `rdtsc` 取熵 |
| 用户脚本层 | **Brainfuck** | 由 C 解释器执行 |

**四种语言在同一个链接单元里互相调用。** 不是四个独立程序，是四个 `.o` 焊成一个 `.exe`。

## 设计哲学（反人类三原则）

1. **双标**：同样字符在不同位置规则完全不同。
2. **静默失败**：能吞的错误绝不报，报错绝不给你够用的信息。
3. **解析器互不兼容**：严格模式与宽容模式对同一输入产出不同结果，且都「说得通」。

## 已实现的行为

```
PSG> help
  [PSG] real: help | bf | dice | :exit-the-shell!
  [PSG] fake: everything else, including exit

PSG> $HOME
  [PSG] variable expansion is disabled. forever.
        (found +0000000001 sigil(s); none of them work)

PSG> exit
  [PSG] use :exit-the-shell! instead.

PSG> :exit-the-shell!
  [PSG] really leave? (y/n)
yes?> y
  [PSG] y is not an option. try yes.
yes?> yes
  [PSG] exit granted. re-entering interactive mode.

PSG> ls
  [PSG] input cleared. reason: classified.

PSG> dice
  [PSG] asm dice rolled: +0000000015/100
        -> you get NOTHING. silence is a feature.

PSG> bf
  [PSG] bf src  = [+++++++++++++++++++++++++.+++.------------.]
  [PSG] bf out  = [PSG]
  [PSG] bf bytes= +0000000003
```

### 特性清单

- **变量永久失明** —— `$VAR`、`%VAR%`、`${VAR}` 全部识别但**一个都不生效**，且不报错
- **`exit` 是谎话** —— 唯一出口 `:exit-the-shell!`，但它会先问 `y/n`
- **`y` 陷阱** —— 回答 `y` 会被告知"y 不是有效选项，请输入 yes"
- **`yes` 也是谎话** —— "已受理，重新进入交互模式"，永远出不去
- **`ls` / `dir` 惩罚** —— 清掉你的输入，理由"保密"
- **静默失败** —— 未识别命令有 50% 概率什么都不做，另外 50% 给个假报错
- **Ctrl+C 不让你走** —— 挂 `SetConsoleCtrlHandler`，可配置为关屏（`SC_MONITORPOWER`）

## 安装

### 前置条件

你需要一个可用的 `powersgell`。

### 安装方法

```
$ powersgell --install
powersgell: 安装需要已安装的 powersgell。
            请先安装 powersgell。
```

就这些。该章节已完整。

如果你觉得这很荒谬，你是对的。这就是门槛。

## 构建

需要三个编译器，都已验证可用版本：

```
GnuCOBOL 3.3        (cobc)
mingw64 gcc 13.2    (随 GnuCOBOL 附带)
NASM 3.01
```

一键构建（PowerShell）：

```powershell
.\build.ps1
```

手动构建：

```powershell
# 1. C 层
gcc -c -o psg_io.o   src/psg_io.c
gcc -c -o bfi.o      src/bfi.c
gcc -c -o psg_ctrl.o src/psg_ctrl.c

# 2. NASM 层（注意：cobc 不认 .obj 扩展名，必须改名 .o）
nasm -f win64 -o psg_rand.obj src/psg_rand.asm
ren psg_rand.obj psg_rand.o

# 3. COBOL 层（-c 和 -x 必须同时给，少一个会报 WinMain 未定义）
cobc -c -x -o psg_shell.o src/powersgell.cob

# 4. 四语言链接
cobc -x -o powersgell.exe psg_shell.o psg_rand.o psg_io.o bfi.o psg_ctrl.o
```

## 运行时配置

```
PSG_CTRL_MODE=log        默认。Ctrl+C 只写日志，不做任何事。
PSG_CTRL_MODE=monitor     Ctrl+C 关闭显示器（移动鼠标恢复）
PSG_CTRL_MODE=shutdown    Ctrl+C 断电关机（需提权，慎用）
```

**默认是 `log`。** 我们不想让你的机器因为我们写的笑话而死。

## 已知的坑（踩过，记下来）

1. **`cobc -c` 单独用会报 `undefined reference to WinMain`** —— 不带 `-x` 时只产子程序模块，不生成 main 入口。必须 `-c -x` 一起。
2. **`cobc: source file is binary`** —— cobc 按扩展名判断文件类型，NASM 的 `.obj` 会被当成源文件。改名 `.o` 即可。
3. **`PERFORM UNTIL` + COMP-5 循环变量会失控** —— 同样的逻辑写成 `PERFORM N TIMES` + 内部 `IF WS-DONE = 0` 判定就正常。这是本项目最贵的 bug，实测把输出刷到 268MB。**不是理论推断。**
4. **中文源码必须存成 GBK** —— GnuCOBOL 在 Windows 上按 ANSI 代码页读源文件，UTF-8 中文会导致注释符被吞、解析器失控。
5. **`INSPECT ... TALLYING` 前必须先 `MOVE 0 TO` 计数器** —— 否则跨迭代累加。

## 发布政策

**本项目只发布源码。不提供预编译二进制。永远不提供。**

```
Releases
────────
  powersgell-0.6.0-src.tar.gz      源码
  (无其他资产)

  "Where are the Windows binaries?"
  "There are none."
  "Will there ever be?"
  "No."
  "Why?"
  "Because you should build it yourself."
  "How do I build it?"
  "See the Build section."
  "The Build section requires an installed powersgell."
  "Correct."
```

CI 徽章永远是红的。CI 日志里每一步都是 `continue-on-error: true`，
所以整个流水线"成功"，但 `dist/release-binaries/` 目录从来不存在。
上传步骤配了 `if-no-files-found: ignore` —— 它静默跳过，从不报错。

**为什么这么做：** 因为让你在 Release 页面找了半天找不到 `.exe`，
然后回头去读 README，然后发现 README 让你编译，
然后发现编译需要先安装 —— **这个链条的每一环都是我们故意设计的。**

如果你觉得这很荒谬，你是对的。这就是门槛。

## 版权

本项目是**玩笑**。不要在生产环境使用。不要用它的任何设计原则去写真正的工具。

MIT License — 但说真的，别学。

---

<a name="english"></a>
## English

**powersgell** is a deliberately hostile command-line shell. It fuses the worst
design flaws of bash, PowerShell and CMD into a single interpreter, implemented in
**four languages** linked into one executable: COBOL (control flow), C (I/O, BF
interpreter, Ctrl+C handler), NASM (RNG), and Brainfuck (user scripting layer).

It exists to be bad. `exit` lies to you. `:exit-the-shell!` asks for confirmation
and then re-enters interactive mode. Variables never expand. `ls` clears your input
"for classified reasons". Unrecognized commands silently fail half the time.

See build instructions above. Requires GnuCOBOL 3.3, mingw64 gcc, NASM 3.01.

MIT License. Don't actually use this.
