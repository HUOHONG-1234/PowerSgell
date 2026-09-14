/* bfi.c —— 真·Brainfuck 解释器（运行时消费 BF 源码 + 输入流）
   COBOL 通过 CALL "bf_run" USING ... 调用，全部按引用传参（COBOL 默认语义）。

   int bf_run(char *prog, int *prog_len,
              char *inp,  int *inp_len,
              char *out,  int *out_cap);
   返回实际写入 out 的字节数。
*/
#include <string.h>

#define TAPE_SIZE 65536
#define MAX_BRACKETS 4096

static unsigned char tape[TAPE_SIZE];
static long jump[MAX_BRACKETS * 2]; /* 配对表: [开括号下标]=闭括号下标, 反之亦然 */

static int is_bf(int c) {
    return c=='+'||c=='-'||c=='>'||c=='<'||c=='.'||c==','||c=='['||c==']';
}

int bf_run(char *prog, int *prog_len,
           char *inp,  int *inp_len,
           char *out,  int *out_cap)
{
    long ip = 0, ptr = 0, in_i = 0, out_n = 0;
    long plen = *prog_len;
    long ilen = *inp_len;
    long ocap = *out_cap;
    long stack[MAX_BRACKETS];
    long sp = 0;
    long i;

    memset(tape, 0, sizeof(tape));
    memset(jump, -1, sizeof(jump));

    /* 先建括号配对表 —— 这一步让解释器是 O(n) 而不是每次回跳重扫 */
    for (i = 0; i < plen && i < MAX_BRACKETS; i++) {
        if (prog[i] == '[') {
            if (sp >= MAX_BRACKETS) return -1;
            stack[sp++] = i;
        } else if (prog[i] == ']') {
            if (sp <= 0) return -2;          /* 括号不配对 */
            long open = stack[--sp];
            jump[open] = i;
            jump[i] = open;
        }
    }
    if (sp != 0) return -2;

    while (ip < plen) {
        int c = prog[ip];
        switch (c) {
            case '+': tape[ptr]++; break;
            case '-': tape[ptr]--; break;
            case '>': ptr = (ptr + 1) % TAPE_SIZE; break;
            case '<': ptr = (ptr - 1 + TAPE_SIZE) % TAPE_SIZE; break;
            case '.':
                if (out_n < ocap) out[out_n++] = (char)tape[ptr];
                break;
            case ',':
                tape[ptr] = (in_i < ilen) ? (unsigned char)inp[in_i++] : 0;
                break;
            case '[':
                if (tape[ptr] == 0 && jump[ip] >= 0) ip = jump[ip];
                break;
            case ']':
                if (tape[ptr] != 0 && jump[ip] >= 0) ip = jump[ip];
                break;
            default: break;                   /* 非 BF 字符一律当注释 */
        }
        ip++;
    }
    *out_cap = (int)out_n;                     /* 回写实际长度 */
    return (int)out_n;
}
