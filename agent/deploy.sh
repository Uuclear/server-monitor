#!/bin/bash
# 一键部署 Agent 到远程服务器
# 用法: bash deploy.sh root@1.2.3.4

if [ -z "$1" ]; then
    echo "用法: bash deploy.sh user@server_ip"
    exit 1
fi

SERVER=$1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 部署 Agent 到 $SERVER ==="

# 检测服务器架构
ARCH=$(ssh $SERVER "uname -m")
echo "服务器架构: $ARCH"

if [ "$ARCH" = "x86_64" ]; then
    BINARY="agent-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    BINARY="agent-linux-arm64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 上传文件
echo "上传文件..."
scp "$SCRIPT_DIR/$BINARY" "$SERVER:/tmp/agent"
scp "$SCRIPT_DIR/install.sh" "$SERVER:/tmp/install-agent.sh"

# 远程安装
echo "远程安装..."
ssh $SERVER "sudo bash /tmp/install-agent.sh"

echo "=== 部署完成 ==="
