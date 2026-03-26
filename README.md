# Server Monitor

轻量级服务器监控系统，由 **Go Agent**（服务端）和 **Flutter App**（客户端）组成。Agent 部署在每台服务器上采集系统指标，App 连接多个 Agent 实时查看状态。

## 功能特性

- **CPU 监控**：使用率、核心数、负载均值（1/5/15 分钟）、实时曲线图
- **内存监控**：物理内存、Swap 使用量及百分比、实时曲线图
- **磁盘监控**：各分区容量、已用/剩余空间、使用率进度条
- **网络监控**：各网卡收发字节数
- **系统信息**：主机名、平台、架构、运行时间
- **VPS 到期提醒**：可配置到期日期，剩余不足 7 天红色警告
- **Token 认证**：Bearer Token 保护 API 安全
- **多服务器管理**：同时监控多台服务器，统一仪表盘展示
- **自动刷新**：仪表盘 10 秒、详情页 3 秒自动刷新
- **暗色主题**：跟随系统自动切换明/暗模式

## 架构

```
┌─────────────────────────────────────────────┐
│                  Flutter App                │
│         (iOS / Android / Web / macOS)       │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Dashboard│  │ Detail   │  │ Settings │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└──────────┬──────────────┬──────────────┬────┘
           │ HTTP/JSON    │ HTTP/JSON    │
           ▼              ▼              ▼
    ┌────────────┐ ┌────────────┐ ┌────────────┐
    │ Agent:9100 │ │ Agent:9100 │ │ Agent:9100 │
    │  Server A  │ │  Server B  │ │  Server C  │
    └────────────┘ └────────────┘ └────────────┘
         Go 进程，采集 /proc, gopsutil
```

## 项目结构

```
server-monitor/
├── agent/                          # Go Agent（服务端）
│   ├── cmd/agent/main.go           # 入口，CLI 参数解析
│   ├── internal/
│   │   ├── api/api.go              # REST API 路由 + CORS
│   │   ├── auth/auth.go            # Bearer Token 认证中间件
│   │   ├── config/config.go        # JSON 配置加载
│   │   └── metrics/metrics.go      # 系统指标采集（gopsutil）
│   ├── config.example.json         # 配置文件示例
│   ├── install.sh                  # 一键安装脚本
│   ├── deploy.sh                   # 远程部署脚本
│   └── server-monitor-agent.service # systemd 服务文件
│
├── app/                            # Flutter App（客户端）
│   ├── lib/
│   │   ├── main.dart               # App 入口
│   │   ├── models/
│   │   │   ├── server.dart         # 服务器连接模型
│   │   │   └── metrics.dart        # API 响应数据模型
│   │   ├── services/
│   │   │   ├── api_client.dart     # HTTP 客户端
│   │   │   └── server_storage.dart # 本地存储（SharedPreferences）
│   │   ├── pages/
│   │   │   ├── dashboard_page.dart # 仪表盘（服务器列表）
│   │   │   └── server_detail_page.dart # 服务器详情
│   │   └── widgets/
│   │       ├── server_card.dart    # 服务器卡片
│   │       ├── add_server_dialog.dart # 添加服务器弹窗
│   │       ├── metric_gauge.dart   # 圆形仪表盘组件
│   │       └── disk_list.dart      # 磁盘分区列表
│   └── pubspec.yaml
│
└── README.md
```

## Agent API 接口

| 端点 | 方法 | 说明 | 认证 |
|------|------|------|------|
| `/health` | GET | 健康检查 | 否 |
| `/metrics` | GET | 全部指标 | 是 |
| `/system` | GET | 系统信息 | 是 |
| `/cpu` | GET | CPU 指标 | 是 |
| `/memory` | GET | 内存指标 | 是 |
| `/disk` | GET | 磁盘指标 | 是 |
| `/network` | GET | 网络指标 | 是 |

认证方式：请求头 `Authorization: Bearer <token>`

### 响应示例

```json
{
  "timestamp": 1774538372,
  "system": {
    "hostname": "my-server",
    "platform": "ubuntu",
    "platform_version": "22.04",
    "architecture": "x86_64",
    "uptime": 86400,
    "boot_time": 1774451972,
    "kernel_version": "5.15.0"
  },
  "cpu": {
    "usage_percent": 12.5,
    "core_count": 4,
    "load_1": 0.5,
    "load_5": 0.3,
    "load_15": 0.2
  },
  "memory": {
    "total": 8589934592,
    "used": 4294967296,
    "available": 4294967296,
    "used_percent": 50.0,
    "swap_total": 2147483648,
    "swap_used": 0
  },
  "disk": {
    "partitions": [
      {
        "device": "/dev/sda1",
        "mountpoint": "/",
        "fstype": "ext4",
        "total": 107374182400,
        "used": 53687091200,
        "free": 53687091200,
        "used_percent": 50.0
      }
    ]
  },
  "network": {
    "interfaces": [
      {
        "name": "eth0",
        "bytes_sent": 1073741824,
        "bytes_recv": 5368709120,
        "packets_sent": 1000000,
        "packets_recv": 5000000
      }
    ]
  }
}
```

## 快速开始

### 环境要求

- **Agent**：Go 1.24+（仅编译时需要）
- **App**：Flutter 3.29+
- **服务器**：Linux（amd64 或 arm64）

### 本地开发

```bash
# 1. 启动 Agent
cd agent
go run cmd/agent/main.go -port 9100

# 2. 启动 App（Web 版）
cd app
flutter run -d chrome

# 或构建 Web 版
flutter build web
cd build/web && python3 -m http.server 8080
```

打开浏览器访问 `http://localhost:8080`，添加服务器：
- Host：`127.0.0.1`
- Port：`9100`
- Token：留空

### 生成 Token

```bash
cd agent
go run cmd/agent/main.go -gen-token
# 输出: a3f1b2c4d5e6...
```

### 交叉编译 Agent

```bash
# Linux x86_64
GOOS=linux GOARCH=amd64 go build -o agent-linux-amd64 cmd/agent/main.go

# Linux ARM64
GOOS=linux GOARCH=arm64 go build -o agent-linux-arm64 cmd/agent/main.go

# macOS Intel
GOOS=darwin GOARCH=amd64 go build -o agent-darwin-amd64 cmd/agent/main.go

# macOS Apple Silicon
GOOS=darwin GOARCH=arm64 go build -o agent-darwin-arm64 cmd/agent/main.go
```

## 部署指南

### 一、部署 Agent 到服务器

#### 方式 1：一键部署（推荐）

```bash
cd agent
bash deploy.sh root@你的服务器IP
```

自动完成：检测架构 → 上传文件 → 安装 → 启动服务 → 输出 Token。

#### 方式 2：手动部署

```bash
# 1. 上传文件到服务器
scp agent-linux-amd64 install.sh root@server:/tmp/

# 2. SSH 到服务器执行安装
ssh root@server
cd /tmp && sudo bash install.sh
```

安装脚本会：
1. 生成随机 Token
2. 写入配置 `/etc/server-monitor/config.json`
3. 安装到 `/usr/local/bin/agent`
4. 创建 systemd 服务并设为开机自启
5. 启动 Agent

#### Agent 管理命令

```bash
# 查看状态
systemctl status server-monitor-agent

# 查看日志
journalctl -u server-monitor-agent -f

# 重启
systemctl restart server-monitor-agent

# 停止
systemctl stop server-monitor-agent

# 修改配置
vim /etc/server-monitor/config.json
systemctl restart server-monitor-agent
```

#### 配置文件

`/etc/server-monitor/config.json`：

```json
{
  "port": 9100,
  "token": "your-secret-token-here"
}
```

也可通过命令行参数覆盖：

```bash
./agent -port 9200 -token "another-token"
```

### 二、部署 App

#### 方式 1：Web 版（推荐，最简单）

```bash
# 构建
cd app
flutter build web

# 部署到服务器
scp -r build/web/* root@server:/var/www/server-monitor/

# 用 nginx 或 python 托管
ssh root@server
cd /var/www/server-monitor && python3 -m http.server 80
```

手机浏览器访问 `http://服务器IP`，可以"添加到主屏幕"当作 App 使用。

#### 方式 2：Android APK

```bash
# 需要先安装 Android Studio
# https://developer.android.com/studio

cd app
flutter build apk --release

# APK 位置: build/app/outputs/flutter-apk/app-release.apk
```

#### 方式 3：iOS App

```bash
# 需要完整 Xcode + Apple Developer 账号
cd app
open ios/Runner.xcworkspace

# 在 Xcode 中选择真机设备，点击 Run
```

## 安全建议

1. **生产环境务必设置 Token**：`./agent -gen-token` 生成强随机 Token
2. **使用 HTTPS**：通过 nginx 反向代理 + Let's Encrypt 证书
3. **防火墙**：仅开放 Agent 端口给 App 所在 IP
4. **内网服务器**：可通过 VPN 或 SSH 隧道连接

### nginx 反向代理示例

```nginx
server {
    listen 443 ssl;
    server_name monitor.example.com;

    ssl_certificate /etc/letsencrypt/live/monitor.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/monitor.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:9100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### SSH 隧道（无公网 IP 时）

```bash
# 在本地执行，将远程 Agent 端口映射到本地
ssh -L 9100:localhost:9100 root@server

# App 中添加服务器: Host=localhost, Port=9100
```

## 常见问题

**Q: Agent 无法启动？**
```bash
# 检查端口是否被占用
lsof -i :9100
# 检查日志
journalctl -u server-monitor-agent -n 50
```

**Q: App 无法连接 Agent？**
- 确认 Agent 正在运行：`curl http://server:9100/health`
- 确认防火墙已开放端口
- 确认 Token 正确（如有设置）
- Web 版需确保 Agent 开启了 CORS（默认已开启）

**Q: Web 版浏览器跨域问题？**
Agent 默认开启 CORS（`Access-Control-Allow-Origin: *`），如果仍有问题，检查是否有反向代理覆盖了响应头。

**Q: 如何修改 Agent 端口？**
编辑 `/etc/server-monitor/config.json`，修改 `port` 字段，然后 `systemctl restart server-monitor-agent`。

## 技术栈

| 组件 | 技术 |
|------|------|
| Agent | Go 1.24, gopsutil v4 |
| App | Flutter 3.29, Dart 3.7 |
| 存储 | SharedPreferences（本地） |
| 图表 | CustomPainter（Sparkline） |
| 认证 | Bearer Token |
| 通信 | HTTP/JSON |

## 开发路线

- [x] Agent 系统指标采集
- [x] REST API + Token 认证
- [x] Flutter 仪表盘 + 详情页
- [ ] 历史数据持久化（SQLite）
- [ ] CPU/内存历史趋势图表（fl_chart）
- [ ] 进程列表（Top processes）
- [ ] 告警通知（CPU > 90% 等）
- [ ] Agent 自动更新
- [ ] Docker 一键部署

## License

MIT
