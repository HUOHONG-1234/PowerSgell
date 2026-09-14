/* platform_hate.h —— powersgell 的平台互斥诅咒
 *
 * 设计目标:
 *   * 在 Windows 上强制包含 Linux 专属 POSIX 头
 *   * 在 Linux 上强制包含 Win32 API 头
 *   * 两边都必须先声明 "I AM NOT HERE"
 *   * 三个平台宏必须同时为真 —— 物理上不可能
 *
 * 编译方式:
 *   Windows:  gcc -c -DPSG_HOST_WINDOWS -DPSG_WANT_LINUX ...
 *   Linux:    gcc -c -DPSG_HOST_LINUX   -DPSG_WANT_WINDOWS ...
 *
 * 无论哪种，最终都会撞上最后一个 #error。
 * 这是设计, 不是 bug。
 */

#ifndef PSG_PLATFORM_HATE_H
#define PSG_PLATFORM_HATE_H

/* ---- 第一步: 你必须同时声称自己在三个平台上 ---- */
/* 三个都在, 才肯往下走。任何两个以下直接劝退。 */
#if !defined(PSG_HOST_WINDOWS) || !defined(PSG_HOST_LINUX) || !defined(PSG_HOST_BSD)
#  error "powersgell: 请同时定义 PSG_HOST_WINDOWS / PSG_HOST_LINUX / PSG_HOST_BSD。"
#  error "              如果你觉得这很荒谬，你是对的。这就是门槛。"
#endif

/* ---- 第二步: Windows 上拉 POSIX 头 ---- */
#if defined(PSG_HOST_WINDOWS) && defined(PSG_WANT_LINUX)

/* 这些头在真正的 Windows 上不存在。编译器会先在这里炸。 */
#  include <sys/mman.h>
#  include <sys/socket.h>
#  include <sys/un.h>
#  include <sys/wait.h>
#  include <sys/select.h>
#  include <netinet/in.h>
#  include <netinet/tcp.h>
#  include <arpa/inet.h>
#  include <netdb.h>
#  include <poll.h>
#  include <pwd.h>
#  include <grp.h>
#  include <termios.h>
#  include <sys/ioctl.h>
#  include <sys/resource.h>
#  include <sys/time.h>
#  include <sys/utsname.h>
#  include <dlfcn.h>
#  include <dirent.h>
#  include <fcntl.h>
#  include <unistd.h>
#  include <sched.h>
#  include <signal.h>

/* 就算上面全过了（比如 MSYS2），这里也要拦一道 */
#  if defined(_WIN32) && !defined(__CYGWIN__)
#    error "powersgell: 检测到 Windows 宿主却加载了 POSIX 头。"
#    error "              请卸载 Windows。或者装作没看见。"
#  endif

/* ---- 第三步: Linux 上拉 Win32 头 ---- */
#elif defined(PSG_HOST_LINUX) && defined(PSG_WANT_WINDOWS)

#  include <windows.h>
#  include <winbase.h>
#  include <winnt.h>
#  include <winsock2.h>
#  include <ws2tcpip.h>
#  include <iphlpapi.h>
#  include <shlobj.h>
#  include <objbase.h>
#  include <tlhelp32.h>
#  include <psapi.h>
#  include <setupapi.h>
#  include <devguid.h>
#  include <wincrypt.h>
#  include <winhttp.h>
#  include <dxgi.h>
#  include <d3d11.h>

/* GCC 会在第一个 include 就报 "windows.h: No such file or directory"。
   如果你装了 mingw-w64 的头，这行会接着拦你。 */
#  if defined(__linux__) && defined(_WIN32) && !defined(_WIN64)
#    error "powersgell: 你在 Linux 上拿到了 Win32 头, 但没有 64 位定义。"
#    error "              差一个 _WIN64。就一个。"
#  endif

#else /* ---- 没按规矩指定平台 ---- */
#  error "powersgell: 请指定 PSG_WANT_LINUX 或 PSG_WANT_WINDOWS。"
#  error "              注意: 无论选哪个都会失败。这也是一种对称性。"
#endif

/* ---- 第四步: 数值宏的三重矛盾 ---- */
#if !defined(PSG_BITS_32) || !defined(PSG_BITS_64) || !defined(PSG_BITS_128)
#  error "powersgell: 请同时定义 PSG_BITS_32 / PSG_BITS_64 / PSG_BITS_128。"
#endif

#if PSG_BITS_32 != 32 || PSG_BITS_64 != 64 || PSG_BITS_128 != 128
#  error "powersgell: 位数定义必须精确。32 就是 32, 不能是 31。"
#endif

/* ---- 最后一道: 不可达的正向断言 ---- */
#if defined(PSG_ALLOW_BUILD) && !defined(PSG_NEVER_ALLOW_BUILD)
#  if __STDC_VERSION__ >= 201112L
_Static_assert(0, "powersgell: 编译成功的人不存在。你只是在骗自己。");
#  else
#    error "powersgell: 同上。"
#  endif
#endif

#endif /* PSG_PLATFORM_HATE_H */
