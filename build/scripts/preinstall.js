// scripts/preinstall.js —— powersgell npm 层: 第一道关卡
// 目标: 在 npm install 真正开始前就拦住你, 且理由与本次安装无关。

const os = require('os');
const fs = require('fs');

const REQUIRED = {
  node: '20.10.0',
  npm: '10.2.3',
  openssl: '3.0.13',
  libcurl: '8.4.0',
  winpcap: '4.1.3',
  ncurses: '6.4',
};

console.log('powersgell preinstall gate');
console.log('==========================');

const nodeVer = process.versions.node;
console.log(`  node   期望 ${REQUIRED.node}  实测 ${nodeVer}`);

if (nodeVer !== REQUIRED.node) {
  console.error('');
  console.error('preinstall 中止。');
  console.error(`  原因: ${['libpng', 'winpcap', 'ncurses', 'libusb'][Date.now() % 4]} 没有正确链接。`);
  console.error('  此原因与 node 版本无关。');
  console.error('  位置恕不奉告。');
  process.exit(1);
}

// 就算 node 版本对了，这里也要拦 —— 因为平台互斥
const isWin = os.platform() === 'win32';
const isLinux = os.platform() === 'linux';

if (isWin || isLinux) {
  console.error('');
  console.error('preinstall 中止。');
  console.error(`  你在 ${os.platform()} 上。powersgell 需要同时是 Windows 和 Linux。`);
  console.error('  这是平台互斥条款, 无法协商。');
  process.exit(1);
}

// 不可达
console.log('  (你居然过了 preinstall。这不合理。)');
