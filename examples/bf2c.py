# -*- coding: utf-8 -*-
"""Brainfuck -> C 编译器。把 .bf 直接翻成 C 函数，交给 gcc 编成目标文件，
   再让 COBOL 用 CALL 调它。这样 BF 就和 COBOL/ASM/C 同处一个链接单元。
"""
import sys


def bf_from_text(s):
    """把文本转成一段只输出该文本的 Brainfuck（按差值生成，不浪费指令）"""
    out = []
    prev = 0
    for ch in s:
        v = ord(ch)
        d = v - prev
        if d > 0:
            out.append('+' * d)
        elif d < 0:
            out.append('-' * (-d))
        out.append('.')
        prev = v
    return ''.join(out)


def to_c(bf, fname):
    body = []
    indent = 1

    def emit(s):
        body.append('    ' * indent + s)

    i, n = 0, len(bf)
    while i < n:
        c = bf[i]
        if c in '+-<>':
            j = i
            while j < n and bf[j] == c:
                j += 1
            k = j - i
            if c == '+':
                emit('tape[ptr]+=%d;' % k)
            elif c == '-':
                emit('tape[ptr]-=%d;' % k)
            elif c == '>':
                emit('ptr+=%d;' % k)
            else:
                emit('ptr-=%d;' % k)
            i = j
        elif c == '.':
            emit('putchar(tape[ptr]); emitted++;')
            i += 1
        elif c == ',':
            emit('tape[ptr]=(unsigned char)getchar();')
            i += 1
        elif c == '[':
            emit('while(tape[ptr]){')
            indent += 1
            i += 1
        elif c == ']':
            indent -= 1
            emit('}')
            i += 1
        else:
            i += 1

    out = ['#include <stdio.h>',
           'static unsigned char tape[30000];',
           'static long ptr=0;',
           'int %s(void){' % fname,
           '    long emitted=0;']
    out.extend(body)
    out.append('    return (int)emitted;')
    out.append('}')
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    text = sys.argv[1] if len(sys.argv) > 1 else 'POWERSGELL'
    bf = bf_from_text(text)
    open('brainfuck.bf', 'w', encoding='ascii').write(bf + '\n')
    open('brainfuck_gen.c', 'w', encoding='ascii').write(to_c(bf, 'bf_print'))
    print('[bf2c] target text : %s' % text)
    print('[bf2c] bf length   : %d bytes' % len(bf))
