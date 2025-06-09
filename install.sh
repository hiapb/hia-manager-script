#!/bin/bash
set -e
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

install_hia() {
    wget -O /usr/local/bin/hia https://raw.githubusercontent.com/hiapb/hia-manager-script/main/install.sh
    chmod +x /usr/local/bin/hia
    echo -e "${GREEN}安装完成！以后输入 hia 即可启动菜单。${RESET}"
}

install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    apt update -y && apt install -y curl wget unzip
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
        b) show_menu ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; reinstall_system ;;
    esac
}

enable_bbr() {
    echo -e "${GREEN}正在开启 BBR 并优化 TCP 设置...${RESET}"
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo -e "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo -e "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${GREEN}BBR 和 TCP 设置已成功启用！${RESET}"
}

install_gost() {
    clear
    echo -e "${GREEN}正在安装 GOST V3...${RESET}"
    bash <(curl -sSL https://raw.githubusercontent.com/hiapb/gost-forward-script/main/install.sh)
    echo -e "${GREEN}GOST V3 安装完成！${RESET}"
    sleep 2
    show_menu
}

manage_warp() {
    echo -e "${GREEN}正在启动 WARP 管理脚本...${RESET}"
    bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/raw/main/CFwarp.sh)
}

uninstall_hia() {
    echo -e "${RED}正在卸载 HIA 管理脚本...${RESET}"
    rm -f /usr/local/bin/hia
    echo -e "${GREEN}HIA 管理脚本已卸载！（如临时执行可忽略）${RESET}"
}

show_menu() {
    clear
    echo -e "${GREEN}=== HIA 一键管理脚本 ===${RESET}"
    echo "----------------------------------"
    echo "1) 重装系统"
    echo "2) 安装 GOST V3 代理"
    echo "3) 开启 BBR 并优化 TCP 设置"
    echo "4) 管理 WARP"
    echo "0) 卸载 HIA 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice
    case "$choice" in
        1) reinstall_system; show_menu ;;
        2) install_gost ;;
        3) enable_bbr; sleep 2; show_menu ;;
        4) manage_warp; show_menu ;;
        0) uninstall_hia; sleep 1; exit 0 ;;
        q) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; show_menu ;;
    esac
}

# 判断是作为安装脚本用还是作为 hia 命令用
if [[ "$0" != "/usr/local/bin/hia" ]]; then
    # 安装模式
    install_hia
    echo -e "${GREEN}立即为你启动菜单面板...${RESET}"
    sleep 1
    bash /usr/local/bin/hia
    exit 0
else
    # 直接菜单模式
    show_menu
fi
