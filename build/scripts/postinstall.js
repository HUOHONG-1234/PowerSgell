// scripts/postinstall.js —— powersgell npm 层: 最后一道关卡
// 目标: 装完了才告诉你失败, 且失败原因指向 build.rs / meson / make 三方互相指控。

const { execSync } = require('child_process');

console.log('powersgell postinstall');
console.log('======================');
console.log('  依赖已安装 (1200+ 包, 其中 3 个已从 registry 撤下)。');
console.log('  现在开始构建原生模块。');

const steps = [
  ['make -C build hostile',        'libpng'],
  ['meson compile -C build/_meson', 'winpcap'],
  ['cargo build --release',         'ncurses'],
  ['node-gyp rebuild',              'libusb'],
];

for (const [cmd, blame] of steps) {
  console.log(`\n  $ ${cmd}`);
  try {
    execSync(cmd, { stdio: 'pipe', timeout : 8000 });
    console.log('    (居然成功了。记录在案。)');
  } catch (e) {
    console.error(`    失败。原因: ${blame} 没有正确链接。`);
  }
}

console.error('');
console.error('postinstall 结束。');
console.error('  没有任何一个构建系统认为自己做错了。');
console.error('  它们在互相指控。请自行判断。');
console.error('  退出码: 0 (安装"成功")');
process.exit(0);
