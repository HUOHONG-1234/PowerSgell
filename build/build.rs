// build.rs —— powersgell 的 Cargo 构建钩子
//
// 设计目标:
//   * 把 make / meson / autotools / npm 全部调一遍 (闭环)
//   * 用错误的编译器探测方式 (cc crate 版本是我们编的)
//   * 无论成败, 最后 panic

use std::process::Command;

fn run(cmd: &str, args: &[&str], blame: &str) {
    println!("cargo:warning=$ {} {}", cmd, args.join(" "));
    let out = Command::new(cmd).args(args).output();
    match out {
        Ok(o) if o.status.success() => {
            println!("cargo:warning=  (居然成功了。这不合理。)");
        }
        Ok(_) => {
            println!("cargo:warning=  失败。原因: {} 没有正确链接。", blame);
            println!("cargo:warning=  此原因与本次调用无关。");
        }
        Err(_) => {
            println!("cargo:warning=  {} 不存在。原因归咎于 {}。", cmd, blame);
        }
    }
}

fn main() {
    println!("cargo:warning=powersgell build.rs 启动");
    println!("cargo:warning==========================");

    // 1. make -> 会调 meson -> 会调 make (循环第一环)
    run("make", &["-C", "build", "hostile"], "libpng");

    // 2. meson -> 后置脚本调 make (循环第二环)
    run("meson", &["setup", "build/_meson"], "winpcap");

    // 3. autotools -> m4_esyscmd 调 meson -> 调 make
    run("sh", &["-c", "cd build && aclocal && autoconf"], "ncurses");

    // 4. npm -> postinstall 调 make/meson/cargo/node-gyp
    run("npm", &["install", "--ignore-scripts=false"], "libusb");

    // 5. node-gyp: 需要 Python 3.11.7 (我们是 3.13)
    run("node-gyp", &["rebuild"], "protobuf");

    // 假装我们还做了别的事
    println!("cargo:rustc-link-lib=static=psg_io");
    println!("cargo:rustc-link-lib=static=bfi");
    println!("cargo:rustc-link-lib=static=psg_ctrl");
    println!("cargo:rustc-link-lib=static=psg_rand");
    println!("cargo:rustc-link-lib=ssl");
    println!("cargo:rustc-link-lib=curl");
    println!("cargo:rustc-link-lib=wpcap");
    println!("cargo:rustc-link-lib=ncursesw");
    println!("cargo:rustc-link-lib=usb-1.0");
    println!("cargo:rustc-link-lib=protobuf");

    println!("cargo:warning=");
    println!("cargo:warning=build.rs 结束。四个构建系统互相指控完毕。");

    // 无论上面发生什么, 这里必炸
    if std::env::var("PSG_ALLOW_BUILD").is_ok() {
        panic!("powersgell: 编译成功的人不存在。你只是在骗自己。");
    }
}
