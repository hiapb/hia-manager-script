#!/bin/bash
GREEN="\e[32m"
RESET="\e[0m"

GOST_VERSION="3.0.0"
GOST_URL="https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost-linux-amd64-${GOST_VERSION}.gz"
GOST_BINARY="/usr/local/bin/gost"
GOST_CONFIG_FILE="/etc/gost-config.json"
GOST_SERVICE="/etc/systemd/system/gost.service"

if [ "$EUID" -ne 0 ]; then
    echo -e "${GREEN}请以 root 用户运行此脚本。${RESET}"
    exit 1
fi

initialize_gost_config() {
    if [ ! -f "$GOST_CONFIG_FILE" ]; then
        echo -e "${GREEN}初始化 GOST 配置文件...${RESET}"
        echo '{"services":[]}' > "$GOST_CONFIG_FILE"
    fi
}

create_systemd_service() {
    cat > "$GOST_SERVICE" <<EOF
[Unit]
Description=GOST v3 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/gost -C $GOST_CONFIG_FILE
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable gost
}

install_gost() {
    echo -e "${GREEN}正在安装 GOST...${RESET}"
    apt update -y && apt install -y curl wget jq iptables
    wget -qO gost.gz "$GOST_URL"
    gunzip gost.gz && chmod +x gost && mv gost "$GOST_BINARY"
    create_systemd_service
    initialize_gost_config
    echo -e "${GREEN}GOST 安装完成！${RESET}"
}

update_gost() {
    check_gost_installed || return
    echo -e "${GREEN}正在更新 GOST...${RESET}"
    wget -qO gost.gz "$GOST_URL"
    gunzip gost.gz && chmod +x gost && mv gost "$GOST_BINARY"
    systemctl restart gost
    echo -e "${GREEN}GOST 已更新到最新版本！${RESET}"
}

uninstall_gost() {
    check_gost_installed || return
    echo -e "${GREEN}正在卸载 GOST...${RESET}"
    systemctl stop gost 2>/dev/null
    systemctl disable gost 2>/dev/null
    if [ -f "$GOST_CONFIG_FILE" ]; then
        ports=$(jq -r '.services[].addr' "$GOST_CONFIG_FILE" | grep -oP ':[0-9]+' | tr -d ':')
        for p in $ports; do
            iptables -D INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null
        done
    fi
    rm -f "$GOST_BINARY"
    rm -f "$GOST_CONFIG_FILE"
    rm -f "$GOST_SERVICE"
    systemctl daemon-reload
    echo -e "${GREEN}GOST 及所有相关配置已卸载、iptables 规则已清理。${RESET}"
    exit 0
}

start_gost() {
    check_gost_installed || return
    systemctl start gost
    echo -e "${GREEN}GOST 已启动！${RESET}"
}

stop_gost() {
    check_gost_installed || return
    systemctl stop gost
    echo -e "${GREEN}GOST 已停止！${RESET}"
}

restart_gost() {
    check_gost_installed || return
    systemctl restart gost
    echo -e "${GREEN}GOST 已重启！${RESET}"
}

add_gost_config() {
    check_gost_installed || return
    initialize_gost_config

    LOCAL_IP=$(hostname -I | awk '{print $1}')

    while true; do
        read -p "请输入本地监听端口: " LOCAL_PORT
        if [[ -z "$LOCAL_PORT" ]] || ! [[ "$LOCAL_PORT" =~ ^[0-9]{1,5}$ ]] || [ "$LOCAL_PORT" -lt 1 ] || [ "$LOCAL_PORT" -gt 65535 ]; then
            echo -e "${GREEN}端口不能为空且必须是1-65535之间的数字，请重新输入。${RESET}"
        else
            break
        fi
    done

    while true; do
        read -p "请输入目标 IP 和端口 (格式: IP:PORT): " TARGET_ADDR
        if [[ -z "$TARGET_ADDR" ]] || ! [[ "$TARGET_ADDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}$ ]]; then
            echo -e "${GREEN}格式不正确！应为 1.2.3.4:5678，请重新输入。${RESET}"
        else
            break
        fi
    done

    RULE="{\"name\":\"tcp-${LOCAL_IP}:${LOCAL_PORT}\",\"addr\":\"${LOCAL_IP}:${LOCAL_PORT}\",\"handler\":{\"type\":\"forward\",\"target\":\"${TARGET_ADDR}\"},\"listener\":{\"type\":\"tcp\"}}"
    jq '(.services //= []) | .services += ['"$RULE"']' "$GOST_CONFIG_FILE" > /tmp/gost.json && mv /tmp/gost.json "$GOST_CONFIG_FILE"

    iptables -C INPUT -p tcp --dport "$LOCAL_PORT" -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport "$LOCAL_PORT" -j ACCEPT

    echo -e "${GREEN}GOST 转发规则已添加至配置文件，本地监听 ${LOCAL_IP}:${LOCAL_PORT}，已启用流量统计！${RESET}"
    restart_gost
}

view_gost_config() {
    check_gost_installed || return
    initialize_gost_config
    echo -e "${GREEN}当前 GOST 配置: ${RESET}"
    jq . "$GOST_CONFIG_FILE"
}

delete_gost_config() {
    check_gost_installed || return
    initialize_gost_config
    echo -e "${GREEN}当前配置的服务列表：${RESET}"
    jq -c '.services[] | {name, addr}' "$GOST_CONFIG_FILE"

    read -p "请输入要删除的服务名称 (如 tcp-本机IP:端口): " SERVICE_NAME

    DEL_PORT=$(jq -r --arg NAME "$SERVICE_NAME" '.services[] | select(.name==$NAME) | .addr' "$GOST_CONFIG_FILE" | awk -F: '{print $2}')
    jq '.services |= map(select(.name != "'"$SERVICE_NAME"'"))' "$GOST_CONFIG_FILE" > /tmp/gost.json && mv /tmp/gost.json "$GOST_CONFIG_FILE"
    if [[ "$DEL_PORT" =~ ^[0-9]+$ ]]; then
        iptables -D INPUT -p tcp --dport "$DEL_PORT" -j ACCEPT 2>/dev/null
    fi
    echo -e "${GREEN}已删除服务规则！${RESET}"
    restart_gost
}

delete_all_gost_config() {
    check_gost_installed || return
    initialize_gost_config
    if [ ! -s "$GOST_CONFIG_FILE" ] || [ "$(jq '.services | length' "$GOST_CONFIG_FILE")" -eq 0 ]; then
        echo -e "${GREEN}没有可删除的转发配置。${RESET}"
        return
    fi
    # 清空所有 iptables 统计规则
    ports=$(jq -r '.services[].addr' "$GOST_CONFIG_FILE" | grep -oP ':[0-9]+' | tr -d ':')
    for p in $ports; do
        iptables -D INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null
    done
    jq '.services = []' "$GOST_CONFIG_FILE" > /tmp/gost.json && mv /tmp/gost.json "$GOST_CONFIG_FILE"
    echo -e "${GREEN}所有 GOST 转发配置及相关流量统计已全部删除！${RESET}"
    restart_gost
}

traffic_stats() {
    check_gost_installed || return
    echo -e "${GREEN}GOST 监听端口流量统计（单位：字节）:${RESET}"
    initialize_gost_config
    ports=$(jq -r '.services[].addr' "$GOST_CONFIG_FILE" | grep -oP ':[0-9]+' | tr -d ':')
    for p in $ports; do
        BYTES=$(iptables -L INPUT -v -n | grep "tcp dpt:$p" | awk '{print $2}')
        BYTES=${BYTES:-0}
        echo "端口 $p 入站流量: $BYTES 字节"
    done
}

# 检查 GOST 是否已安装
check_gost_installed() {
    if [ ! -f "$GOST_BINARY" ] || [ ! -f "$GOST_SERVICE" ]; then
        echo -e "${GREEN}请先选择【1. 安装 GOST】！${RESET}"
        return 1
    fi
    return 0
}

main_menu() {
    while true; do
        echo -e "${GREEN}===== GOST v3 转发管理脚本 =====${RESET}"
        echo "1. 安装 GOST"
        echo "2. 更新 GOST"
        echo "3. 卸载 GOST"
        echo "————————————"
        echo "4. 启动 GOST"
        echo "5. 停止 GOST"
        echo "6. 重启 GOST"
        echo "————————————"
        echo "7. 新增 GOST 转发配置"
        echo "8. 查看现有配置"
        echo "9. 删除一则 GOST 配置"
        echo "10. 删除全部 GOST 配置"
        echo "11. 查看监听端口流量统计"
        echo "12. 退出"
        read -p "请选择一个操作 [1-12]: " choice
        case "$choice" in
            1) install_gost ;;
            2) update_gost ;;
            3) uninstall_gost ;;
            4) start_gost ;;
            5) stop_gost ;;
            6) restart_gost ;;
            7) add_gost_config ;;
            8) view_gost_config ;;
            9) delete_gost_config ;;
            10) delete_all_gost_config ;;
            11) traffic_stats ;;
            12) exit 0 ;;
            *) echo -e "${GREEN}请输入正确的选项！${RESET}" ;;
        esac
    done
}

main_menu
