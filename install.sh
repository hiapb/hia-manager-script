#!/bin/bash

# 颜色定义
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# 安装必要依赖
install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    apt update -y && apt install -y curl wget unzip
}

# 重装系统
reinstall_system() {
    clear
    echo -e "${GREEN}=== 选择要安装的系统版本 ===${RESET}"
    echo "1) Debian 12"
    echo "2) Debian 11"
    echo "3) Debian 10"
    echo "4) Ubuntu 24.10"
    echo "5) Ubuntu 24.04"
    echo "6) Ubuntu 22.04"
    echo "7) Ubuntu 20.04"
    echo "b) 返回"
    read -p "请选择: " os_choice

    case "$os_choice" in
        1) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 12 ;;
        2) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 11 ;;
        3) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 10 ;;
        4) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 24.10 ;;
        5) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 24.04 ;;
        6) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 22.04 ;;
        7) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh ubuntu 20.04 ;;
        b) show_menu ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; reinstall_system ;;
    esac
}

# 启用 BBR 并优化 TCP 设置
enable_bbr() {
    echo -e "${GREEN}正在开启 BBR 并优化 TCP 设置...${RESET}"

    # 备份原始 sysctl.conf
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # 启用 BBR
    echo -e "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    echo -e "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_no_metrics_save = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_ecn = 0" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_frto = 0" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_mtu_probing = 0" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_rfc1337 = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_fack = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_window_scaling = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_adv_win_scale = 2" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_moderate_rcvbuf = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_rmem = 4096 65536 16777216" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_wmem = 4096 65536 16777216" >> /etc/sysctl.conf
    echo -e "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
    echo -e "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
    echo -e "net.ipv4.udp_rmem_min = 8192" >> /etc/sysctl.conf
    echo -e "net.ipv4.udp_wmem_min = 8192" >> /etc/sysctl.conf
    echo -e "net.ipv4.ip_local_port_range = 1024 65535" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_timestamps = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_max_syn_backlog = 4096" >> /etc/sysctl.conf
    echo -e "net.core.somaxconn = 4096" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_abort_on_overflow = 1" >> /etc/sysctl.conf
    echo -e "vm.swappiness = 10" >> /etc/sysctl.conf
    echo -e "fs.file-max = 6553560" >> /etc/sysctl.conf
    echo -e "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    echo -e "net.core.wmem_max = 12582912" >> /etc/sysctl.conf
    echo -e "net.core.wmem_default = 8388608" >> /etc/sysctl.conf
    echo -e "net.core.rmem_max = 12582912" >> /etc/sysctl.conf
    echo -e "net.core.rmem_default = 8388608" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_wmem = 4096 12582912 16777216" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_rmem = 4096 12582912 16777216" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_timestamps = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_fack = 1" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_syn_retries = 2" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_synack_retries = 2" >> /etc/sysctl.conf

    # 重新加载 sysctl 配置
    sysctl -p

    echo -e "${GREEN}BBR 和 TCP 设置已成功启用！${RESET}"
}

# 安装 GOST V3 代理
install_gost() {
    clear
    echo -e "${GREEN}正在安装 GOST V3...${RESET}"
    bash <(curl -sSL https://raw.githubusercontent.com/hiapb/gost-forward-script/main/install.sh)
    echo -e "${GREEN}GOST V3 安装完成！${RESET}"
    sleep 2
    show_menu
}

# 卸载 HIA 管理脚本
uninstall_hia() {
    echo -e "${RED}正在卸载 HIA 管理脚本...${RESET}"
    rm -f /usr/local/bin/hia
    rm -f /etc/profile.d/hia.sh
    echo -e "${GREEN}HIA 管理脚本已卸载！${RESET}"
}

# 安装 `hia` 命令并设置开机提示
install_hia_command() {
    wget -O /usr/local/bin/hia https://raw.githubusercontent.com/hiapb/hia-manager-script/main/install.sh
    chmod +x /usr/local/bin/hia
}

# 设置快捷命令
setup_shortcut() {
    echo "bash /usr/local/bin/hia" > /etc/profile.d/hia.sh
    chmod +x /etc/profile.d/hia.sh
}

# 安装 `hia` 命令并设置开机提示
install_hia_command
setup_shortcut

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}=== HIA 一键管理脚本 ===${RESET}"
    echo "----------------------------------"
    echo "1) 重装系统"
    echo "2) 安装 GOST V3 代理"
    echo "3) 开启 BBR 并优化 TCP 设置"
    echo "0) 卸载 HIA 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice

    case "$choice" in
        1) reinstall_system ;;
        2) install_gost ;;
        3) enable_bbr ;;
        0) uninstall_hia ;;
        q) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; show_menu ;;
    esac
}

# 启动菜单
show_menu
