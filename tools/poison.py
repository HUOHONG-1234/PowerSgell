#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""poison.py —— powersgell 源码投毒器

两种模式, 可叠加:

  1) 同形字 (homoglyph): 把标识符里的拉丁字母换成长得一模一样的西里尔/希腊字母。
     结果: 代码看起来完全正常, 但那两个 "count" 在编译器眼里是两个不同的名字。
     症状: error: 'сount' undeclared  —— 而它明明就在上一行声明了。

  2) 零宽字符 (zero-width): 在标识符中间插入 U+200B / U+200C / U+200D。
     结果: 文件在编辑器里看不出任何异常。
     症状: grep 搜不到, 复制粘贴后报 stray '\342' in program。

用法:
  python poison.py <file> --mode homoglyph
  python poison.py <file> --mode zero-width
  python poison.py <file> --mode both
  python poison.py <file> --check          # 检测是否已被投毒
"""

import sys
import re

# 长得一样但码位不同的同形字
HOMOGLYPHS = {
    'a': '\u0430',  # CYRILLIC SMALL LETTER A
    'c': '\u0441',  # CYRILLIC SMALL LETTER ES
    'e': '\u0435',  # CYRILLIC SMALL LETTER IE
    'o': '\u043e',  # CYRILLIC SMALL LETTER O
    'p': '\u0440',  # CYRILLIC SMALL LETTER ER
    'x': '\u0445',  # CYRILLIC SMALL LETTER HA
    'y': '\u0443',  # CYRILLIC SMALL LETTER U
    's': '\u0455',  # CYRILLIC SMALL LETTER DZE
    'i': '\u0456',  # CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
}

ZERO_WIDTH = ['\u200b', '\u200c', '\u200d', '\u2060', '\ufeff']

IDENT_RE = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')


def poison_homoglyph(text):
    """把每个标识符里的最后一个可替换字符换掉 —— 每个名字只中毒一次, 更难发现"""
    def sub(m):
        name = m.group(0)
        for i in range(len(name) - 1, -1, -1):
            ch = name[i]
            if ch in HOMOGLYPHS:
                return name[:i] + HOMOGLYPHS[ch] + name[i + 1:]
        return name
    return IDENT_RE.sub(sub, text)


def poison_zero_width(text):
    """在每个标识符的第 2 个字符后插入一个零宽字符"""
    def sub(m):
        name = m.group(0)
        if len(name) < 3:
            return name
        return name[:2] + '\u200b' + name[2:]
    return IDENT_RE.sub(sub, text)


def check(text):
    zw = sum(1 for ch in text if ch in ZERO_WIDTH)
    hg = sum(1 for ch in text if ch in HOMOGLYPHS.values())
    return zw, hg


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    path = sys.argv[1]
    mode = 'both'
    if '--mode' in sys.argv:
        mode = sys.argv[sys.argv.index('--mode') + 1]

    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    if '--check' in sys.argv:
        zw, hg = check(text)
        print(f'{path}: zero-width={zw}, homoglyph={hg}')
        if zw or hg:
            print('  该文件已被投毒。祝你好运。')
            return 1
        print('  干净。目前。')
        return 0

    if mode in ('homoglyph', 'both'):
        text = poison_homoglyph(text)
    if mode in ('zero-width', 'both'):
        text = poison_zero_width(text)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

    zw, hg = check(text)
    print(f'[poison] {path}')
    print(f'  mode        : {mode}')
    print(f'  zero-width  : {zw} 个 (肉眼不可见)')
    print(f'  homoglyph   : {hg} 个 (长得一样, 码位不同)')
    print('  文件看起来完全正常。这就是问题。')
    return 0


if __name__ == '__main__':
    sys.exit(main())
