#!/bin/bash
set -e
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

if [[ $EUID -eq 0 ]]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="$HOME/bin"
    mkdir -p "$TARGET_DIR"
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$PATH:$HOME/bin"' >> "$HOME/.bashrc"
        export PATH="$PATH:$HOME/bin"
        echo -e "${GREEN}已将 $HOME/bin 加入 PATH，重开终端生效。${RESET}"
    fi
fi

install_hia() {
    wget -q -O "$TARGET_DIR/hia" https://raw.githubusercontent.com/hiapb/hia-manager-script/main/install.sh
    chmod +x "$TARGET_DIR/hia"
    echo -e "${GREEN}安装完成！以后输入 hia 即可启动菜单。${RESET}"
}

install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    if command -v apt >/dev/null 2>&1; then
        apt update -y && apt install -y curl wget unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget unzip
    else
        echo -e "${RED}不支持的系统，需手动安装 curl wget unzip${RESET}"
    fi
}

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
    echo "8) Debian 12(备用推荐)"
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
        8) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'hia123456' ;;
        b) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
    exit 0
}

enable_bbr() {
    echo -e "${GREEN}正在开启 BBR 并覆盖写入优化参数...${RESET}"

    # 先备份原始配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # 覆盖写入优化内容
    cat > /etc/sysctl.conf <<EOF
# ===== HIA BBR + TCP 优化参数 =====
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.conf.all.rp_filter = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_frto = 0
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_abort_on_overflow = 1
vm.swappiness = 10
fs.file-max = 6553560
net.core.wmem_max = 12582912
net.core.wmem_default = 8388608
net.core.rmem_max = 12582912
net.core.rmem_default = 8388608
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
# ===== End HIA =====
EOF

    # 立即生效
    sysctl -p

    echo -e "${GREEN}BBR 和 TCP 网络参数已覆盖写入并生效！${RESET}"
    sleep 2
    exit 0
}

install_hipf() {
    clear
    echo -e "${GREEN}正在安装 HiaPortFusion (HAProxy+GOST聚合转发脚本)...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/HiaPortFusion/main/install.sh)
    exit 0
}

install_haproxy() {
    clear
    echo -e "${GREEN}正在安装 HAProxy TCP转发管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/Hia-HAProxy/main/install.sh)
    echo -e "${GREEN}HAProxy TCP转发脚本安装完成！${RESET}"
    sleep 2
    exit 0
}

install_realm() {
    clear
    echo -e "${GREEN}正在安装 Realm TCP+UDP万能转发脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh)
    echo -e "${GREEN}Realm 万能转发脚本安装完成！${RESET}"
    sleep 2
    exit 0
}

install_gost() {
    clear
    echo -e "${GREEN}正在安装 GOST TCP+UDP 转发管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-gost/main/install.sh)
    echo -e "${GREEN}GOST TCP+UDP转发脚本安装完成！${RESET}"
    sleep 2
    exit 0
}

manage_warp() {
    echo -e "${GREEN}正在启动 WARP 管理脚本...${RESET}"
    bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh)
    exit 0
}

check_ports() {
    echo -e "${GREEN}正在启动 服务器http/https端口检测...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/check-web-ports/main/install.sh)
    exit 0
}

nuro_alist() {
    echo -e "${GREEN}正在启动 NuroHia · Alist 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nurohia-alist/main/install.sh)
    exit 0
}

install_xui() {
    clear
    echo -e "${GREEN}正在安装 X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    echo -e "${GREEN}X-UI 安装完成！${RESET}"
    sleep 2
    exit 0
}

install_aapanel() {
    clear
    echo -e "${GREEN}正在安装国际版宝塔（aapanel）...${RESET}"
    wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
    echo -e "${GREEN}aapanel 安装完成！${RESET}"
    sleep 2
    exit 0
}

install_1panel() {
    clear
    echo -e "${GREEN}正在安装 1Panel...${RESET}"
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
    echo -e "${GREEN}1Panel 安装完成！${RESET}"
    sleep 2
    exit 0
}

install_aurora() {
    clear
    echo -e "${GREEN}正在安装极光面板...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
    echo -e "${GREEN}极光面板安装完成！${RESET}"
    sleep 2
    exit 0
}

check_ip_quality() {
    clear
    echo -e "${GREEN}正在进行 IP 质量检测...${RESET}"
    bash <(curl -sL IP.Check.Place)
    echo -e "${GREEN}IP 质量检测完成！${RESET}"
    sleep 2
    exit 0
}

uninstall_hia() {
    echo -e "${RED}正在卸载 HIA 管理脚本...${RESET}"
    rm -f "$TARGET_DIR/hia"
    echo -e "${GREEN}HIA 管理脚本已卸载！${RESET}"
    exit 0
}

show_menu() {
    clear
    echo -e "${GREEN}=== HIA 一键管理脚本 ===${RESET}"
    echo "----------------------------------"
    echo "1) 重装系统"
    echo "2) 安装 HiaPortFusion (HAProxy+GOST聚合转发)"
    echo "3) 安装 HAProxy TCP转发"
    echo "4) 安装 Realm TCP+UDP转发"
    echo "5) 安装 GOST TCP+UDP转发"
    echo "6) 开启 BBR 并优化 TCP 设置"
    echo "7) 管理 WARP"
    echo "8) 安装 X-UI 面板"
    echo "9) 安装国际版宝塔（aapanel）"
    echo "10) 安装 1Panel 面板"
    echo "11) 安装极光面板"
    echo "12) IP 质量检测"
    echo "13) 服务器 http/https端口检测"
    echo "14) NuroHia · Alist 一键部署&管理"
    echo "0) 卸载 HIA 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice
    case "$choice" in
        1)  reinstall_system ;;
        2)  install_hipf ;;
        3)  install_haproxy ;;
        4)  install_realm ;;
        5)  install_gost ;;
        6)  enable_bbr ;;
        7)  manage_warp ;;
        8)  install_xui ;;
        9)  install_aapanel ;;
        10) install_1panel ;;
        11) install_aurora ;;
        12) check_ip_quality ;;
        13）check_ports ;;
        13）nuro_alist ;;
        0)  uninstall_hia ;;
        q)  exit 0 ;;
        *)  echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
}

if [[ "$0" != "$TARGET_DIR/hia" ]]; then
    install_hia
    echo -e "${GREEN}立即为你启动菜单面板...${RESET}"
    sleep 1
    exec "$TARGET_DIR/hia"
    exit 0
else
    show_menu
fi
