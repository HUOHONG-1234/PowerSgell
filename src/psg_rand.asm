; psg_rand.asm —— powersgell 的底层原语
; win64 ABI。返回 0..99 的伪随机数（rdtsc 取低位）。
; 用途: 决定这次未知命令是"静默失败"还是"假装报错"。
section .text
global psg_rand

psg_rand:
    rdtsc                   ; edx:eax = 时间戳
    xor     edx, edx
    mov     ecx, 100
    div     ecx             ; eax / 100 -> edx = 余数
    mov     eax, edx
    ret
