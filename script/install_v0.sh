#!/bin/bash

# 检查 wget 和 unzip 是否安装，未安装则安装
if ! command -v wget &> /dev/null; then
    echo "wget 未安装，正在安装..."
    apt update && apt install -y wget || yum install -y wget
fi

if ! command -v unzip &> /dev/null; then
    echo "unzip 未安装，正在安装..."
    apt update && apt install -y unzip || yum install -y unzip
fi

# 创建目标目录
mkdir -p /opt/nezha/agent

# 接收命令行参数
VERSION=$1        # 第一个参数为版本号，纯数字
API_HOST=$2       # 第二个参数为 API Host
API_PORT=$3        # 第四个参数为 API Post
API_KEY=$4        # 第三个参数为 API Key


# 下载并解压
echo "正在下载并解压 nezha-agent..."
wget -q https://github.com/nezhahq/agent/releases/download/v$VERSION/nezha-agent_linux_amd64.zip -O /tmp/nezha-agent.zip
unzip -o /tmp/nezha-agent.zip -d /opt/nezha/agent/
rm -f /tmp/nezha-agent.zip

# 添加执行权限
chmod +x /opt/nezha/agent/nezha-agent

# 创建 systemd 服务文件
cat << EOF > /etc/systemd/system/nezha-agent.service
[Unit]
Description=哪吒探针监控端
ConditionFileIsExecutable=/opt/nezha/agent/nezha-agent

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/opt/nezha/agent/nezha-agent "-s" "$API_HOST:$API_PORT" "-p" "$API_KEY" --disable-auto-update
WorkingDirectory=/root
Restart=always
RestartSec=120
EnvironmentFile=-/etc/sysconfig/nezha-agent

[Install]
WantedBy=multi-user.target
EOF

# 设置权限并启动服务
chmod 644 /etc/systemd/system/nezha-agent.service
systemctl daemon-reload
systemctl enable nezha-agent
systemctl start nezha-agent

echo "Nezha Agent 已安装并设置为开机自启，服务已启动。"
