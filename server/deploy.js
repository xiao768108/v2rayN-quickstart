const { Client } = require('ssh2');
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

// ─── 配置 ─────────────────────────────────────────────────
const OUTPUT_DIR = path.resolve(__dirname, '..', 'output');
const V2RAYN_CONFIG_PATH = path.join(OUTPUT_DIR, 'v2rayN-config.json');

// ─── 解析参数 ─────────────────────────────────────────────
const args = process.argv.slice(2);
if (args.length < 2) {
  console.log(`
  VLESS + REALITY 一键部署工具
  ============================

  用法:
    node server/deploy.js <服务器IP> <root密码> [SSH端口]

  示例:
    node server/deploy.js 1.2.3.4 MyRootPassword123
    node server/deploy.js 1.2.3.4 MyRootPassword123 22

  前置条件:
    - 服务器系统: CentOS 7 / Ubuntu 20+ / Debian 11+
    - 本机已安装 Node.js
    - 本目录下已执行 npm install
`);
  process.exit(1);
}

const SERVER_IP = args[0];
const ROOT_PASSWORD = args[1];
const SSH_PORT = parseInt(args[2]) || 22;

// ─── 工具函数 ─────────────────────────────────────────────
function generateUUID() {
  return crypto.randomUUID();
}

function generateShortId() {
  return crypto.randomBytes(4).toString('hex');
}

function execCommand(conn, command, description) {
  return new Promise((resolve, reject) => {
    console.log(`  -> ${description}...`);
    conn.exec(command, (err, stream) => {
      if (err) return reject(err);
      let stdout = '', stderr = '';
      stream.on('close', (code) => {
        if (code === 0) resolve(stdout.trim());
        else reject(new Error(`${description} 失败 (exit ${code}): ${stderr.trim() || stdout.trim()}`));
      });
      stream.on('data', (data) => { stdout += data.toString(); });
      stream.stderr.on('data', (data) => { stderr += data.toString(); });
    });
  });
}

function buildServerConfig(uuid, privateKey, shortId) {
  return {
    log: { loglevel: "warning" },
    inbounds: [{
      port: 443,
      protocol: "vless",
      settings: {
        clients: [{ id: uuid, flow: "xtls-rprx-vision-udp443", email: "t@t.tt" }],
        decryption: "none",
        fallbacks: []
      },
      streamSettings: {
        network: "tcp",
        security: "reality",
        realitySettings: {
          dest: "www.microsoft.com:443",
          serverNames: ["www.microsoft.com", "www.bing.com"],
          privateKey: privateKey,
          shortIds: [shortId]
        }
      },
      sniffing: { enabled: true, destOverride: ["http", "tls"] }
    }],
    outbounds: [
      { protocol: "freedom", tag: "direct" },
      { protocol: "blackhole", tag: "blocked" }
    ]
  };
}

function buildV2rayNConfig(ip, port, uuid, publicKey, shortId) {
  return {
    log: { loglevel: "warning" },
    dns: {
      hosts: {
        "dns.google": ["8.8.8.8", "8.8.4.4"],
        "cloudflare-dns.com": ["1.1.1.1", "1.0.0.1"]
      },
      servers: [
        { address: "119.29.29.29", domains: ["geosite:cn", "geosite:private"], skipFallback: true, tag: "direct-dns" },
        { address: "https://cloudflare-dns.com/dns-query", domains: ["geosite:google"], skipFallback: true },
        "https://cloudflare-dns.com/dns-query"
      ],
      tag: "dns-module"
    },
    inbounds: [{
      tag: "socks", port: 10808, listen: "127.0.0.1", protocol: "mixed",
      sniffing: { enabled: true, destOverride: ["http", "tls"] },
      settings: { auth: "noauth", udp: true }
    }],
    outbounds: [
      {
        tag: "proxy", protocol: "vless",
        settings: {
          vnext: [{
            address: ip, port: port,
            users: [{ id: uuid, email: "t@t.tt", security: "auto", encryption: "none", flow: "xtls-rprx-vision-udp443" }]
          }]
        },
        streamSettings: {
          network: "raw", security: "reality",
          realitySettings: {
            serverName: "www.microsoft.com", fingerprint: "chrome", show: false,
            publicKey: publicKey, shortId: shortId
          }
        },
        mux: { enabled: false }
      },
      { tag: "direct", protocol: "freedom" },
      { tag: "block", protocol: "blackhole" }
    ],
    routing: {
      domainStrategy: "AsIs",
      rules: [
        { type: "field", port: "443", network: "udp", outboundTag: "block" },
        { type: "field", outboundTag: "proxy", domain: ["geosite:google"] },
        { type: "field", outboundTag: "direct", ip: ["geoip:private"] },
        { type: "field", outboundTag: "direct", domain: ["geosite:private"] },
        { type: "field", outboundTag: "direct", ip: ["geoip:cn"] },
        { type: "field", outboundTag: "direct", domain: ["geosite:cn"] },
        { type: "field", inboundTag: ["direct-dns"], outboundTag: "direct" },
        { type: "field", inboundTag: ["dns-module"], outboundTag: "proxy" }
      ]
    }
  };
}

function printParams(ip, uuid, publicKey, shortId) {
  const line = '='.repeat(50);
  console.log('');
  console.log(line);
  console.log('  配置参数（保存备用）');
  console.log(line);
  console.log(`  地址 (Address)       ${ip}`);
  console.log(`  端口 (Port)          443`);
  console.log(`  用户ID (UUID)        ${uuid}`);
  console.log(`  传输协议 (network)   raw`);
  console.log(`  安全 (security)      reality`);
  console.log(`  伪装域名 (SNI)       www.microsoft.com`);
  console.log(`  公钥 (PublicKey)     ${publicKey}`);
  console.log(`  短ID (ShortId)       ${shortId}`);
  console.log(`  指纹 (fingerprint)   chrome`);
  console.log(`  流控 (Flow)          xtls-rprx-vision-udp443`);
  console.log(line);
  console.log('');
}

// ─── 主流程 ───────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('================================================');
  console.log('  VLESS + REALITY 一键部署工具');
  console.log('================================================');
  console.log(`  服务器: ${SERVER_IP}:${SSH_PORT}`);
  console.log('');

  // 1. 生成本地参数
  const uuid = generateUUID();
  const shortId = generateShortId();
  console.log(`  UUID:    ${uuid}`);
  console.log(`  ShortId: ${shortId}`);
  console.log('');

  // 2. SSH 连接
  console.log('  SSH 连接中...');
  const conn = new Client();
  await new Promise((resolve, reject) => {
    conn.on('ready', resolve);
    conn.on('error', (err) => reject(new Error(`SSH 连接失败: ${err.message}`)));
    conn.connect({
      host: SERVER_IP, port: SSH_PORT, username: 'root',
      password: ROOT_PASSWORD, readyTimeout: 20000
    });
  });
  console.log('  OK - SSH 已连接');
  console.log('');

  try {
    // 3. 安装 xray
    console.log('  --- 安装 xray ---');
    await execCommand(conn,
      'bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install',
      '下载并安装 xray');
    console.log('  OK - xray 安装完成');
    console.log('');

    // 4. 生成密钥对
    console.log('  --- 生成 REALITY 密钥 ---');
    const keyOutput = await execCommand(conn, 'xray x25519', '生成 x25519 密钥对');
    const privateKey = keyOutput.match(/Private key:\s*(\S+)/)?.[1];
    const publicKey = keyOutput.match(/Public key:\s*(\S+)/)?.[1];
    if (!privateKey || !publicKey) throw new Error('无法解析密钥输出');
    console.log(`  OK - PrivateKey: ${privateKey}`);
    console.log(`  OK - PublicKey:  ${publicKey}`);
    console.log('');

    // 5. 写入服务器配置
    console.log('  --- 配置服务端 ---');
    const serverConfig = buildServerConfig(uuid, privateKey, shortId);
    const configPath = '/usr/local/etc/xray/config.json';
    await execCommand(conn, `mkdir -p $(dirname "${configPath}")`, '创建配置目录');
    await execCommand(conn, `cat > "${configPath}" << 'XRAYEOF'\n${JSON.stringify(serverConfig, null, 2)}\nXRAYEOF`, '写入服务端配置');
    console.log('  OK - 服务端配置已写入');
    console.log('');

    // 6. 启动 xray
    console.log('  --- 启动服务 ---');
    await execCommand(conn, 'systemctl restart xray', '重启 xray 服务');
    await execCommand(conn, 'systemctl enable xray', '设置开机自启');
    console.log('  OK - xray 已启动并设为开机自启');
    console.log('');

  } finally {
    conn.end();
  }

  // 7. 写入本地 v2rayN 配置
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const v2rayConfig = buildV2rayNConfig(SERVER_IP, 443, uuid, publicKey, shortId);
  fs.writeFileSync(V2RAYN_CONFIG_PATH, JSON.stringify(v2rayConfig, null, 2), 'utf-8');
  console.log(`  OK - v2rayN 配置已生成: ${V2RAYN_CONFIG_PATH}`);
  console.log('');

  // 8. 打印参数
  printParams(SERVER_IP, uuid, publicKey, shortId);

  console.log('================================================');
  console.log('  部署完成！');
  console.log('  1. 把 output/v2rayN-config.json 复制到');
  console.log('     v2rayN/binConfigs/config.json');
  console.log('  2. 重启 v2rayN');
  console.log('  3. SwitchyOmega 设置 SOCKS5 127.0.0.1:10808');
  console.log('================================================');
  console.log('');
}

main().catch((err) => {
  console.error(`\n失败: ${err.message}`);
  process.exit(1);
});
