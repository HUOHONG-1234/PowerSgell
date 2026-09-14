/* psg_ctrl.c —— powersgell 的 Ctrl+C 终结器 (v2: 关显示器)
 *
 * 收 CTRL_C / CTRL_BREAK 后广播 WM_SYSCOMMAND / SC_MONITORPOWER,
 * 让屏幕进入关闭状态。移动鼠标即可恢复 —— 伤害最小, 效果最像"机器死了"。
 *
 * 模式由环境变量 PSG_CTRL_MODE 决定:
 *   log      (默认) 只写日志
 *   monitor  真正广播关屏
 *   shutdown EWX_POWEROFF 断电关机 (需提权, 保留但默认关闭)
 */
#include <windows.h>
#include <stdio.h>

#define PSG_MODE_LOG      0
#define PSG_MODE_MONITOR  1
#define PSG_MODE_SHUTDOWN 2

static volatile LONG g_mode = PSG_MODE_LOG;

static void psg_log(const char *s)
{
    FILE *f = fopen("psg_ctrl.log", "a");
    if (f) { fprintf(f, "%s\n", s); fclose(f); }
}

static int psg_enable_shutdown_privilege(void)
{
    HANDLE tok;
    TOKEN_PRIVILEGES tp;

    if (!OpenProcessToken(GetCurrentProcess(),
                          TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &tok))
        return 0;

    tp.PrivilegeCount = 1;
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    if (!LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, &tp.Privileges[0].Luid)) {
        CloseHandle(tok);
        return 0;
    }
    if (!AdjustTokenPrivileges(tok, FALSE, &tp, 0, NULL, NULL)) {
        CloseHandle(tok);
        return 0;
    }
    CloseHandle(tok);
    return 1;
}

/* 关屏: 广播给所有顶层窗口。2=关闭, 1=低功耗, -1=打开 */
static void psg_monitor_off(void)
{
    SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2,
                       SMTO_ABORTIFHUNG, 1000, NULL);
}

BOOL WINAPI SgellCtrlHandler(DWORD ctrlType)
{
    switch (ctrlType) {
    case CTRL_C_EVENT:
    case CTRL_BREAK_EVENT:
        if (g_mode == PSG_MODE_MONITOR) {
            psg_monitor_off();
            psg_log("[powersgell] Ctrl+C -> monitor off. move mouse to wake.");
        } else if (g_mode == PSG_MODE_SHUTDOWN) {
            psg_log("[powersgell] Ctrl+C -> machine shutdown.");
            if (psg_enable_shutdown_privilege()) {
                if (!ExitWindowsEx(EWX_POWEROFF | EWX_FORCEIFHUNG,
                                   SHTDN_REASON_MAJOR_APPLICATION |
                                   SHTDN_REASON_MINOR_OTHER |
                                   SHTDN_REASON_FLAG_PLANNED))
                    psg_log("[powersgell] ExitWindowsEx failed.");
            } else {
                psg_log("[powersgell] privilege denied -> aborted.");
            }
        } else {
            psg_log("[powersgell] Ctrl+C received (mode=log, nothing happens).");
        }
        return TRUE;                    /* 已处理, 进程继续存活 */
    case CTRL_CLOSE_EVENT:
        psg_log("[powersgell] console window closing.");
        return FALSE;
    case CTRL_LOGOFF_EVENT:
    case CTRL_SHUTDOWN_EVENT:
        psg_log("[powersgell] logoff/shutdown event.");
        return FALSE;
    default:
        return FALSE;
    }
}

void psg_ctrl_init(void)
{
    char buf[32];
    DWORD n = GetEnvironmentVariableA("PSG_CTRL_MODE", buf, sizeof(buf));

    if (n > 0 && n < sizeof(buf)) {
        if (lstrcmpiA(buf, "monitor") == 0)       g_mode = PSG_MODE_MONITOR;
        else if (lstrcmpiA(buf, "shutdown") == 0) g_mode = PSG_MODE_SHUTDOWN;
        else                                      g_mode = PSG_MODE_LOG;
    }
    SetConsoleCtrlHandler(SgellCtrlHandler, TRUE);
}
