const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const args = process.argv.slice(2);
if (args.length < 4) {
  console.log(`
  用法: node scripts/generate-config.js <IP> <UUID> <PublicKey> <ShortId>

  示例: node scripts/generate-config.js 1.2.3.4 abc-def... LU0ApD... 5798514a

  会在 output/ 目录生成 v2rayN-config.json
`);
  process.exit(1);
}

const [SERVER_IP, UUID, PUBLIC_KEY, SHORT_ID] = args;
const OUTPUT_DIR = path.resolve(__dirname, '..', 'output');

const config = {
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
          address: SERVER_IP, port: 443,
          users: [{ id: UUID, email: "t@t.tt", security: "auto", encryption: "none", flow: "xtls-rprx-vision-udp443" }]
        }]
      },
      streamSettings: {
        network: "raw", security: "reality",
        realitySettings: {
          serverName: "www.microsoft.com", fingerprint: "chrome", show: false,
          publicKey: PUBLIC_KEY, shortId: SHORT_ID
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

fs.mkdirSync(OUTPUT_DIR, { recursive: true });
const outPath = path.join(OUTPUT_DIR, 'v2rayN-config.json');
fs.writeFileSync(outPath, JSON.stringify(config, null, 2), 'utf-8');
console.log(`配置已生成: ${outPath}`);
console.log(`复制到 v2rayN/binConfigs/config.json 即可使用`);
