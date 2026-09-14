       >>SOURCE FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. POWERSGELL.
*> powersgell v0.5 - COBOL 承重: 主循环 + 字符串分析 (变量失明/引号地狱)
*>                - C 承重:      输入层 + BF 解释器 + BF 程序生成
*>                - NASM:        随机原语
DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-LINE    PIC X(200).
01 WS-CMD     PIC X(64).
01 WS-STATE   PIC S9(9) COMP-5 VALUE 0.
01 WS-RND     PIC S9(9) COMP-5.
01 WS-CAP     PIC S9(9) COMP-5 VALUE 200.
01 WS-EOF     PIC S9(9) COMP-5 VALUE 1.
01 WS-IDLE    PIC S9(9) COMP-5 VALUE 0.
01 WS-DONE    PIC S9(9) COMP-5 VALUE 0.
01 WS-TALLY   PIC S9(9) COMP-5.
01 WS-QTALLY  PIC S9(9) COMP-5.
*> BF 通道
01 WS-BFPROG  PIC X(200).
01 WS-BFLEN   PIC S9(9) COMP-5 VALUE 200.
01 WS-BFIN    PIC X(64).
01 WS-BFINLEN PIC S9(9) COMP-5 VALUE 0.
01 WS-BFOUT   PIC X(200).
01 WS-BFOCAP  PIC S9(9) COMP-5 VALUE 200.
01 WS-BFN     PIC S9(9) COMP-5.
PROCEDURE DIVISION.
    DISPLAY "powersgell v0.6  (COBOL core / C engine / NASM dice / BF script)".
    DISPLAY "  [PSG] commands: help / bf / dice / exit / :exit-the-shell!".
    *> 挂上 Ctrl+C 终结器 (C 层, 模式由 PSG_CTRL_MODE 决定)
    CALL "psg_ctrl_init".
    PERFORM 400 TIMES
        IF WS-DONE = 0
            IF WS-STATE = 0
                DISPLAY "PSG> " WITH NO ADVANCING
            ELSE
                DISPLAY "yes?> " WITH NO ADVANCING
            END-IF
            MOVE SPACES TO WS-LINE
            MOVE 200 TO WS-CAP
            CALL "psg_readline" USING WS-LINE WS-CAP RETURNING WS-EOF
            MOVE FUNCTION TRIM(WS-LINE) TO WS-CMD

            IF WS-EOF = 0
                ADD 1 TO WS-IDLE
                IF WS-IDLE = 2
                    DISPLAY "  [PSG] input gone. I stay. I just stop shouting."
                END-IF
                IF WS-IDLE > 4
                    MOVE 1 TO WS-DONE
                END-IF
            ELSE
                MOVE 0 TO WS-IDLE

                *> ---- COBOL 承重活 1: 变量失明 ----
                MOVE 0 TO WS-TALLY
                INSPECT WS-CMD TALLYING WS-TALLY FOR ALL "$"
                INSPECT WS-CMD TALLYING WS-TALLY FOR ALL "%"

                *> ---- COBOL 承重活 2: 引号统计 (引号地狱) ----
                MOVE 0 TO WS-QTALLY
                INSPECT WS-CMD TALLYING WS-QTALLY FOR ALL "'"

                IF WS-STATE = 2
                    DISPLAY "  [PSG] exit granted. re-entering interactive mode."
                    MOVE 0 TO WS-STATE
                ELSE IF WS-STATE = 1
                    IF WS-CMD = "y"
                        DISPLAY "  [PSG] y is not an option. try yes."
                        MOVE 2 TO WS-STATE
                    ELSE
                        DISPLAY "  [PSG] cancelled. you never really wanted to leave."
                        MOVE 0 TO WS-STATE
                    END-IF
                ELSE IF WS-TALLY > 0
                    DISPLAY "  [PSG] variable expansion is disabled. forever."
                    DISPLAY "        (found " WS-TALLY " sigil(s); none of them work)"
                ELSE IF WS-CMD = "help"
                    DISPLAY "  [PSG] real: help | bf | dice | :exit-the-shell!"
                    DISPLAY "  [PSG] fake: everything else, including exit"
                ELSE IF WS-CMD = "bf"
                    *> C 生成 BF 程序 -> C 解释器执行 -> COBOL 收结果
                    CALL "psg_bfdemo" USING WS-BFPROG WS-CAP
                    DISPLAY "  [PSG] bf src  = [" FUNCTION TRIM(WS-BFPROG) "]"
                    MOVE 200 TO WS-BFOCAP
                    CALL "bf_run" USING WS-BFPROG WS-BFLEN
                                       WS-BFIN WS-BFINLEN
                                       WS-BFOUT WS-BFOCAP
                              RETURNING WS-BFN
                    DISPLAY "  [PSG] bf out  = [" FUNCTION TRIM(WS-BFOUT) "]"
                    DISPLAY "  [PSG] bf bytes= " WS-BFN
                ELSE IF WS-CMD = "dice"
                    *> NASM 层显式入口
                    CALL "psg_rand" RETURNING WS-RND
                    DISPLAY "  [PSG] asm dice rolled: " WS-RND "/100"
                    IF WS-RND < 50
                        DISPLAY "        -> you get NOTHING. silence is a feature."
                    ELSE
                        DISPLAY "        -> you get a fake error message."
                    END-IF
                ELSE IF WS-CMD = "ls" OR WS-CMD = "dir"
                    DISPLAY "  [PSG] input cleared. reason: classified."
                ELSE IF WS-CMD = "exit" OR WS-CMD = "quit"
                    DISPLAY "  [PSG] use :exit-the-shell! instead."
                ELSE IF WS-CMD = ":exit-the-shell!"
                    DISPLAY "  [PSG] really leave? (y/n)"
                    MOVE 1 TO WS-STATE
                ELSE
                    CALL "psg_rand" RETURNING WS-RND
                    IF WS-RND < 50
                        CONTINUE
                    ELSE
                        DISPLAY "  [PSG] cannot find " FUNCTION TRIM(WS-CMD)
                                " (dice=" WS-RND ", quotes=" WS-QTALLY ")"
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.
    DISPLAY "[PSG] loop cap reached. exit code 0. (forever).".
    STOP RUN RETURNING 0.
