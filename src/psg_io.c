/* psg_io.c —— powersgell 的 C 层
   承担三件事(让 C 层真正吃重, 不是摆设):
     1) 输入读取 + EOF 判定 (COBOL 的 ACCEPT 在管道下不可靠)
     2) 睡眠节流
     3) 生成 BF 示例脚本 (BF 层的供给方)
*/
#include <stdio.h>
#include <string.h>
#include <windows.h>

int psg_readline(char *buf, int *cap)
{
    char tmp[4096];
    int i, len, n;

    if (buf == NULL || cap == NULL) return 0;
    n = *cap;
    if (n <= 0) return 0;

    if (fgets(tmp, (int)sizeof(tmp), stdin) == NULL) {
        memset(buf, ' ', (size_t)n);
        return 0;                       /* EOF: 明确返回 0 */
    }

    i = 0;
    while (tmp[i] != '\0' && tmp[i] != '\n' && tmp[i] != '\r') i++;
    len = i;
    if (len > n) len = n;

    memset(buf, ' ', (size_t)n);        /* COBOL PIC X 定长空格填充 */
    if (len > 0) memcpy(buf, tmp, (size_t)len);
    return 1;
}

void psg_sleep(int *ms)
{
    if (ms == NULL || *ms <= 0) return;
    Sleep((DWORD)(*ms));
}

/* 生成一段只输出 "PSG" 的 Brainfuck 程序, 按字符差值生成, 不浪费指令 */
void psg_bfdemo(char *buf, int *cap)
{
    const char *s = "PSG";
    int n, i = 0, cur = 0, k, d;

    if (buf == NULL || cap == NULL) return;
    n = *cap;
    if (n <= 0) return;

    memset(buf, ' ', (size_t)n);
    for (k = 0; s[k] != '\0' && i < n - 1; k++) {
        int v = (unsigned char)s[k];
        d = v - cur;
        while (d > 0 && i < n - 1) { buf[i++] = '+'; d--; }
        while (d < 0 && i < n - 1) { buf[i++] = '-'; d++; }
        if (i < n - 1) buf[i++] = '.';
        cur = v;
    }
}
