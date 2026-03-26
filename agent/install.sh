#!/bin/bash
# Server Monitor Agent 安装脚本
# 用法: sudo bash install.sh

set -e

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/server-monitor"
SERVICE_FILE="server-monitor-agent.service"

echo "=== Server Monitor Agent 安装 ==="

# 1. 生成随机 token
TOKEN=$(openssl rand -hex 32)
echo "生成的认证 Token: $TOKEN"
echo "请保存此 Token，App 连接时需要使用"

# 2. 创建配置目录
mkdir -p $CONFIG_DIR

# 3. 写入配置
cat > $CONFIG_DIR/config.json << EOF
{
  "port": 9100,
  "token": "$TOKEN"
}
EOF

# 4. 复制二进制文件
if [ -f "/tmp/agent" ]; then
    cp /tmp/agent $INSTALL_DIR/agent
elif [ -f "./agent-linux-amd64" ]; then
    cp ./agent-linux-amd64 $INSTALL_DIR/agent
elif [ -f "./agent-linux-arm64" ]; then
    cp ./agent-linux-arm64 $INSTALL_DIR/agent
else
    echo "错误: 找不到 agent 二进制文件"
    echo "请先上传 agent 到 /tmp/agent 或当前目录"
    exit 1
fi

chmod +x $INSTALL_DIR/agent

# 5. 安装 systemd 服务
cat > /etc/systemd/system/$SERVICE_FILE << EOF
[Unit]
Description=Server Monitor Agent
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/agent -config $CONFIG_DIR/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动服务
systemctl daemon-reload
systemctl enable server-monitor-agent
systemctl start server-monitor-agent

echo ""
echo "=== 安装完成 ==="
echo "Agent 已启动，监听端口: 9100"
echo "Token: $TOKEN"
echo ""
echo "管理命令:"
echo "  查看状态: systemctl status server-monitor-agent"
echo "  查看日志: journalctl -u server-monitor-agent -f"
echo "  重启服务: systemctl restart server-monitor-agent"
echo "  停止服务: systemctl stop server-monitor-agent"
