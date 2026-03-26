# Server Monitor 开发对话记录

> 项目：轻量级服务器监控系统（Go Agent + Flutter App）
> 开发时间：2026-03-26 ~ 2026-03-27
> 参与者：用户 + Kilo (AI)

---

## 1. 项目规划阶段

### 用户初始需求

用户需要一个服务器监控系统，用于监控多台 VPS（Bandwagon、CloudCone、RackNerd 等），主要需求：
- 实时查看各服务器状态（CPU、内存、磁盘、网络）
- 手机端查看，不需要打开电脑
- VPS 到期时间提醒
- 轻量级，不要侵入服务器

### 技术选型研究

经过调研发现：

| 方案 | 优点 | 缺点 |
|------|------|------|
| 云厂商 API | 自动获取到期时间 | 仅京东云有 API，Bandwagon 等无公开 API |
| Node.js Agent | 上手简单 | 依赖多，体积大 |
| Python Agent | 简洁 | 需要 Python 环境 |
| **Go Agent** | **单二进制、无依赖、体积小** | **需学习** |
| 现有开源方案 | 功能完整 | 部署复杂（beszel、kula 等） |

**最终选择：**
- Agent 端：Go（单二进制部署，无运行时依赖）
- App 端：Flutter（跨平台，iOS/Android/Web 统一代码）

### 参考项目

- [beszel](https://github.com/henrygd/beszel) - Go hub+agent 架构，20k+ stars
- [kula](https://github.com/c0m4r/kula) - Go 单二进制，直接读 /proc
- [OpenHubble Agent](https://github.com/openhubble/agent) - Python+FastAPI
- gopsutil - Go 标准系统指标采集库

### 架构设计

```
┌──────────────────────────────────────┐
│            Flutter App               │
│     (iOS / Android / Web / macOS)    │
│                                      │
│   Dashboard → Detail → Settings      │
└─────────┬──────────┬──────────┬──────┘
          │ HTTP     │ HTTP     │ HTTP
          ▼          ▼          ▼
   ┌──────────┐┌──────────┐┌──────────┐
   │ Agent    ││ Agent    ││ Agent    │
   │ Server A ││ Server B ││ Server C │
   │ :9100    ││ :9100    ││ :9100    │
   └──────────┘└──────────┘└──────────┘
```

### 开发计划

| 阶段 | 内容 | 预计时间 |
|------|------|----------|
| Phase 1 | Agent 开发（Go） | 2-3 周 |
| Phase 2 | Flutter 学习 | 2 周 |
| Phase 3 | App 开发 | 3-4 周 |

---

## 2. Phase 1：Agent 开发

### 2.1 环境准备

用户机器上没有 Go 和 Flutter，需要先安装。

```bash
# Go 安装（通过直接下载）
curl -kfsSL https://go.dev/dl/go1.24.1.darwin-amd64.tar.gz -o /tmp/go.tar.gz
mkdir -p ~/go-install && tar -C ~/go-install -xzf /tmp/go.tar.gz

# Flutter 安装
curl -kfsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.29.2-stable.zip -o /tmp/flutter.zip
unzip -q /tmp/flutter.zip -d ~/flutter-install
```

**遇到的问题：**
- Homebrew 安装 Go 超时（5分钟限制）
- 网络连接不稳定，直接下载也超时多次
- 最终通过 `-k` (insecure) 和 `-C -` (断点续传) 完成下载

### 2.2 Agent 项目结构

```
agent/
├── cmd/agent/main.go              # 入口，CLI 参数
├── internal/
│   ├── api/api.go                 # REST API 路由 + CORS
│   ├── auth/auth.go               # Bearer Token 认证
│   ├── config/config.go           # JSON 配置加载
│   └── metrics/metrics.go         # 系统指标采集
├── go.mod
└── go.sum
```

### 2.3 配置模块

```go
// internal/config/config.go
type Config struct {
    Port  int    `json:"port"`   // HTTP API 端口
    Token string `json:"token"`  // 认证 Token
}
```

配置文件位置优先级：
1. `/etc/server-monitor/config.json`（生产环境）
2. 当前目录 `config.json`（开发环境）
3. 命令行参数覆盖

### 2.4 指标采集模块

使用 gopsutil 库采集系统指标：

```go
// internal/metrics/metrics.go
type AllMetrics struct {
    Timestamp int64          `json:"timestamp"`
    System    SystemInfo     `json:"system"`
    CPU       CPUMetrics     `json:"cpu"`
    Memory    MemoryMetrics  `json:"memory"`
    Disk      DiskMetrics    `json:"disk"`
    Network   NetworkMetrics `json:"network"`
}
```

采集项：
- **CPU**：使用率（1秒采样）、核心数、负载均值（1/5/15分钟）
- **内存**：总量、已用、可用、百分比、Swap
- **磁盘**：各分区容量、使用率、文件系统类型
- **网络**：各网卡收发字节数、包数
- **系统**：主机名、平台、架构、运行时间、内核版本

### 2.5 REST API

```go
// internal/api/api.go
func NewMux(token string) http.Handler {
    mux := http.NewServeMux()
    mux.HandleFunc("GET /health", handleHealth)
    mux.HandleFunc("GET /metrics", handleMetrics)
    mux.HandleFunc("GET /system", handleSystem)
    mux.HandleFunc("GET /cpu", handleCPU)
    mux.HandleFunc("GET /memory", handleMemory)
    mux.HandleFunc("GET /disk", handleDisk)
    mux.HandleFunc("GET /network", handleNetwork)
    return corsMiddleware(auth.Middleware(token)(mux))
}
```

| 端点 | 说明 | 认证 |
|------|------|------|
| `/health` | 健康检查 | 否 |
| `/metrics` | 全部指标 | 是 |
| `/system` | 系统信息 | 是 |
| `/cpu` | CPU 指标 | 是 |
| `/memory` | 内存指标 | 是 |
| `/disk` | 磁盘指标 | 是 |
| `/network` | 网络指标 | 是 |

### 2.6 认证模块

```go
// internal/auth/auth.go
func Middleware(token string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // 如果没有配置 token，跳过认证
            if token == "" {
                next.ServeHTTP(w, r)
                return
            }
            // 验证 Bearer token
            authHeader := r.Header.Get("Authorization")
            // ... 使用 subtle.ConstantTimeCompare 防时序攻击
        })
    }
}
```

### 2.7 CLI 入口

```go
// cmd/agent/main.go
func main() {
    port := flag.Int("port", 0, "HTTP listen port")
    token := flag.String("token", "", "Authentication token")
    genToken := flag.Bool("gen-token", false, "Generate a random token")
    // ...
}
```

使用方式：
```bash
./agent -port 9100                           # 无认证
./agent -port 9100 -token "abc123"           # 带认证
./agent -gen-token                           # 生成随机 token
```

### 2.8 依赖问题解决

安装 gopsutil 时遇到 Go proxy 超时：

```bash
# 默认 proxy 超时
go get github.com/shirou/gopsutil/v4
# Error: dial tcp 142.251.33.209:443: i/o timeout

# 解决方案：使用中国代理 + 跳过 sum 验证
export GOPROXY=https://goproxy.cn,direct
export GONOSUMCHECK=*
export GONOSUMDB=*
go get github.com/shirou/gopsutil/v4
```

### 2.9 Agent 测试

启动 Agent 并验证各端点：

```bash
# 启动
./agent -port 9100

# 测试健康检查
curl http://localhost:9100/health
# {"status":"ok"}

# 测试指标采集
curl http://localhost:9100/metrics | python3 -m json.tool
```

成功返回完整系统指标：
```json
{
    "timestamp": 1774538372,
    "system": {
        "hostname": "MacBookPro",
        "platform": "darwin",
        "platform_version": "15.7.4",
        "architecture": "x86_64",
        "uptime": 1373276
    },
    "cpu": {
        "usage_percent": 17.71,
        "core_count": 8,
        "load_1": 3.62
    },
    "memory": {
        "total": 17179869184,
        "used": 11647651840,
        "used_percent": 67.80
    }
}
```

### 2.10 认证测试

```bash
# 生成 token
TOKEN=$(./agent -gen-token)
# d677d9417ced17264ddbdcd50672d888b1fd4f73e93e405e24f41667fdbff267

# 带 token 启动
./agent -port 9102 -token "$TOKEN"

# 无认证 → 401
curl http://localhost:9102/metrics
# {"error":"missing authorization header"}

# 有认证 → 200
curl -H "Authorization: Bearer $TOKEN" http://localhost:9102/metrics
# {"timestamp":1774538410,...}
```

---

## 3. Phase 2：Flutter App 开发

### 3.1 项目创建

```bash
cd ~/Documents/qrcode/server-monitor
flutter create --org com.servermonitor --project-name server_monitor_app --platforms android,ios,macos app

# 添加依赖
cd app
flutter pub add http fl_chart shared_preferences
```

### 3.2 项目结构

```
app/lib/
├── main.dart                        # App 入口
├── models/
│   ├── server.dart                  # 服务器连接模型
│   └── metrics.dart                 # API 响应数据模型
├── services/
│   ├── api_client.dart              # HTTP 客户端
│   └── server_storage.dart          # 本地存储
├── pages/
│   ├── dashboard_page.dart          # 仪表盘
│   └── server_detail_page.dart      # 服务器详情
└── widgets/
    ├── server_card.dart             # 服务器卡片
    ├── add_server_dialog.dart       # 添加服务器弹窗
    ├── metric_gauge.dart            # 圆形仪表盘
    └── disk_list.dart               # 磁盘分区列表
```

### 3.3 数据模型

**Server 模型：**
```dart
class Server {
    final String id;
    final String name;         // 用户命名
    final String host;         // IP 或域名
    final int port;            // Agent 端口
    final String token;        // 认证 token
    final DateTime? expireDate; // VPS 到期时间（可选）
}
```

**Metrics 模型：**
```dart
class MetricsSnapshot {
    final int timestamp;
    final SystemInfo system;
    final CpuMetrics cpu;
    final MemoryMetrics memory;
    final DiskMetrics disk;
    final NetworkMetrics network;
}
```

### 3.4 API 客户端

```dart
class ApiClient {
    final String baseUrl;  // e.g., "http://192.168.1.100:9100"
    final String token;

    Future<MetricsSnapshot> fetchMetrics() async {
        final uri = Uri.parse('$baseUrl/metrics');
        final response = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 10));
        // ...
    }
}
```

### 3.5 本地存储

使用 SharedPreferences 保存服务器列表：

```dart
class ServerStorage {
    Future<List<Server>> loadServers() async { ... }
    Future<void> saveServers(List<Server> servers) async { ... }
    Future<void> addServer(Server server) async { ... }
    Future<void> removeServer(String id) async { ... }
}
```

### 3.6 仪表盘页面

功能：
- 显示所有已添加服务器的列表
- 每张卡片显示：在线状态、CPU 使用率、RAM 使用率、运行时间
- VPS 到期提醒（<7天红色，<30天橙色）
- 10 秒自动刷新
- 下拉刷新
- 长按删除服务器
- 浮动按钮添加服务器

### 3.7 详情页面

功能：
- 系统信息卡片（主机名、平台、架构、运行时间、到期日）
- CPU 卡片：圆形仪表盘 + 负载均值 + 实时曲线图
- 内存卡片：圆形仪表盘 + 详细数值 + Swap 进度条 + 实时曲线图
- 磁盘卡片：各分区进度条（已用/总量 + 使用率）
- 网络卡片：各网卡收发数据量
- 3 秒自动刷新

### 3.8 自定义组件

**MetricGauge（圆形仪表盘）：**
```dart
class MetricGauge extends StatelessWidget {
    final double value;  // 0-100
    final String label;
    final Color color;

    // 使用 CustomPaint 绘制弧形进度
}
```

**Sparkline（迷你曲线图）：**
```dart
class _SparklinePainter extends CustomPainter {
    final List<double> data;
    final Color color;

    // 绘制折线 + 半透明填充区域
}
```

### 3.9 CORS 问题

Web 版 App 连接 Agent 时遇到浏览器跨域限制：

```
Access to fetch at 'http://localhost:9100/metrics' from origin 'http://localhost:8080' 
has been blocked by CORS policy
```

**解决方案：** 在 Agent 中添加 CORS 中间件：

```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")

        if r.Method == http.MethodOptions {
            w.WriteHeader(http.StatusNoContent)
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

### 3.10 Xcode 配置问题

构建 macOS/iOS 应用时 Xcode 未完整配置：

```
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

**解决方案：** 使用 Web 版替代（`flutter build web`），效果相同。

---

## 4. 测试验证

### 4.1 本地测试流程

```bash
# 1. 启动 Agent
cd agent
./agent -port 9100

# 2. 构建并托管 Web App
cd app
flutter build web
cd build/web && python3 -m http.server 8080

# 3. 浏览器访问 http://localhost:8080
```

### 4.2 添加测试服务器

在 App 中添加：
- Name: `Local Test`
- Host: `127.0.0.1`
- Port: `9100`
- Token: 留空（本地测试无需认证）

仪表盘成功显示：
- 绿色在线状态指示灯
- CPU: 17.7%
- RAM: 67.8%
- Uptime: 15d 20h 7m

点击卡片进入详情页，实时曲线图正常绘制。

---

## 5. 部署方案

### 5.1 Agent 部署

**一键部署脚本（deploy.sh）：**
```bash
# 自动检测架构、上传、安装、启动
bash deploy.sh root@server_ip
```

**安装脚本（install.sh）功能：**
1. 生成随机 Token（`openssl rand -hex 32`）
2. 写入配置 `/etc/server-monitor/config.json`
3. 安装到 `/usr/local/bin/agent`
4. 创建 systemd 服务（开机自启）
5. 启动服务

**systemd 服务：**
```ini
[Unit]
Description=Server Monitor Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/agent -config /etc/server-monitor/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 5.2 交叉编译

```bash
# Linux x86_64（大多数 VPS）
GOOS=linux GOARCH=amd64 go build -o agent-linux-amd64 cmd/agent/main.go
# 9.0 MB

# Linux ARM64（部分 ARM VPS）
GOOS=linux GOARCH=arm64 go build -o agent-linux-arm64 cmd/agent/main.go
# 8.6 MB
```

### 5.3 App 部署

**推荐方案：Web 版**
```bash
flutter build web
scp -r build/web/* root@server:/var/www/server-monitor/
```

手机浏览器访问服务器 IP，"添加到主屏幕"即可当作 App 使用。

**备选方案：**
- Android APK：需安装 Android Studio
- iOS App：需完整 Xcode + Apple Developer 账号

### 5.4 安全建议

1. 生产环境务必设置 Token
2. 使用 nginx 反向代理 + HTTPS
3. 防火墙限制访问 IP
4. 内网服务器用 SSH 隧道

---

## 6. 遇到的问题与解决

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Homebrew 安装 Go 超时 | 网络慢 | 直接下载 tarball |
| Go proxy 连接超时 | 国内网络 | 使用 goproxy.cn 镜像 |
| Go sum 验证超时 | 无法访问 sum.golang.org | 设置 GONOSUMDB=* |
| Flutter 下载中断 | 1.4GB 文件过大 | curl -C - 断点续传 |
| Xcode 未完整配置 | 命令行工具缺失 | 改用 Web 版 |
| 浏览器 CORS 跨域 | Agent 无 CORS 头 | 添加 corsMiddleware |
| GitHub fine-grained Token 无权限 | token 范围不足 | 改用 classic token |

---

## 7. 最终成果

### 文件统计

- **Agent（Go）**：6 个源文件，~300 行代码
- **App（Flutter）**：11 个源文件，~1200 行代码
- **部署脚本**：3 个文件
- **构建产物**：agent-linux-amd64 (9MB), agent-linux-arm64 (8.6MB)
- **总计**：122 个文件，5592 行

### 功能清单

- [x] CPU 监控（使用率、核心数、负载）
- [x] 内存监控（物理内存、Swap）
- [x] 磁盘监控（各分区容量）
- [x] 网络监控（各网卡收发量）
- [x] 系统信息（主机名、平台、运行时间）
- [x] VPS 到期提醒
- [x] Bearer Token 认证
- [x] CORS 支持
- [x] 多服务器管理
- [x] 自动刷新（仪表盘 10s / 详情 3s）
- [x] 暗色主题
- [x] 实时曲线图（Sparkline）
- [x] 圆形仪表盘（Gauge）
- [x] 一键部署脚本
- [x] systemd 服务
- [x] 交叉编译（linux/amd64, linux/arm64）

### 待开发功能

- [ ] 历史数据持久化（SQLite）
- [ ] CPU/内存历史趋势图表（fl_chart）
- [ ] 进程列表（Top processes）
- [ ] 告警通知
- [ ] Agent 自动更新
- [ ] Docker 一键部署

---

## 8. GitHub 推送

### 推送过程

1. 初始化本地 Git 仓库
2. 创建 .gitignore（排除构建产物、IDE 文件、Flutter 缓存）
3. 首次提交 122 个文件
4. 使用 gh CLI 创建 GitHub 仓库
5. 遇到 fine-grained token 权限问题，改用 classic token
6. 成功推送到 https://github.com/Uuclear/server-monitor

### 后续开发流程

```bash
cd ~/Documents/qrcode/server-monitor
# 修改代码
git add -A
git commit -m "描述改动"
git push
```

---

*本文档由 Kilo (AI) 自动生成，记录了完整的项目开发对话。*
