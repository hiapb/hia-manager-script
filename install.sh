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
    echo -e "${GREEN}正在开启 BBR 并优化 TCP 设置...${RESET}"
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo -e "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${GREEN}BBR 和 TCP 设置已成功启用！${RESET}"
    sleep 2
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

manage_warp() {
    echo -e "${GREEN}正在启动 WARP 管理脚本...${RESET}"
    bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh)
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
    echo "2) 安装 HAProxy TCP转发"
    echo "3) 开启 BBR 并优化 TCP 设置"
    echo "4) 管理 WARP"
    echo "5) 安装 X-UI 面板"
    echo "6) 安装国际版宝塔（aapanel）"
    echo "7) 安装 1Panel 面板"
    echo "8) 安装极光面板"
    echo "9) IP 质量检测"
    echo "0) 卸载 HIA 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice
    case "$choice" in
        1) reinstall_system ;;
        2) install_haproxy ;;   # 改为新函数
        3) enable_bbr ;;
        4) manage_warp ;;
        5) install_xui ;;
        6) install_aapanel ;;
        7) install_1panel ;;
        8) install_aurora ;;
        9) check_ip_quality ;;
        0) uninstall_hia ;;
        q) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
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
