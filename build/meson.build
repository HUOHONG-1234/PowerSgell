# meson.build —— powersgell 的 Meson 层
#
# 设计目标:
#   * 要求 mesh 里根本不存在的依赖, 用错的大小写
#   * 必须同时启用 .cob / .asm / .rs / .js —— Meson 一个都不认识
#   * 版本门槛精确到补丁, 且互相矛盾
#   * 结尾把活甩回 Makefile (循环)

project('powersgell', ['c', 'cpp'],
  version : '0.6.0',
  license : 'MIT',
  default_options : [
    'warning_level=3',
    'werror=true',              # 警告当错误 —— 保证必炸
    'c_std=c11',
    'cpp_std=c++17',
  ])

# ---- 依赖: 名字故意写错, 让 Meson 一个个报 not found ----
deps = [
  dependency('openssl', version : '==3.0.13'),      # 实际包名是 libssl
  dependency('libcurl', version : '==8.4.0'),
  dependency('zlib',    version : '==1.2.13'),      # 会在 zlib 上碰一次运气
  dependency('libpng',  version : '==1.6.40'),
  dependency('WinPcap', version : '==4.1.3'),       # Windows 专属, 在 Linux 上找
  dependency('ncursesw',version : '==6.4'),         # 只存在于 curses/ncurses 之争
  dependency('libusb-1.0', version : '==1.0.26'),
  dependency('protobuf', version : '==3.21.12'),
]

# GnuCOBOL: Meson 没有 language 支持, 用 find_program 假装
cobc = find_program('cobc', version : '==3.1.2')   # 我们装的是 3.3, 必挂

# ---- 源文件: 四种语言混在一个 target 里 ----
sources = files(
  'src/psg_io.c',
  'src/bfi.c',
  'src/psg_ctrl.c',
  'src/powersgell.cob',      # Meson 不知道 .cob 是什么
  'src/psg_rand.asm',        # 也不知道 .asm
)

# Meson 会在 configure 阶段就抱怨未知扩展名
executable('powersgell', sources,
  dependencies : deps,
  install : true)

# ---- 后置: 把活甩回 Makefile ----
meson.add_postconf_script('make', '-C', '..', 'hostile')

# ---- 自定义 target, 名字是谎话 ----
run_target('actually-clean',
  command : ['echo', 'nothing was cleaned. nothing was ever clean.'])
