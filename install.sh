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
    # 检测是否是 LXC 环境
    if grep -qaE 'lxc|container' /proc/1/environ 2>/dev/null || grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null; then
        echo -e "${YELLOW}⚠️ 检测到当前环境为 LXC 容器，不支持重装系统！${RESET}"
        echo -e "${GRAY}此功能仅适用于独立服务器或完整虚拟机环境。${RESET}"
        echo
        return
    fi
    echo -e "${GREEN}=== 选择要安装的系统版本 ===${RESET}"
    echo "1) Debian 12"
    echo "2) Debian 11"
    echo "3) Debian 10"
    echo "4) Ubuntu 24.10"
    echo "5) Ubuntu 24.04"
    echo "6) Ubuntu 22.04"
    echo "7) Ubuntu 20.04"
    echo "8) Debian 12(备用推荐)"
    echo "9) Debian 11(备用推荐)"
    echo "10) almalinux 9"
    echo "11) almalinux 8"
    echo "12) almalinux 8(备用推荐)"
    echo "13) Debian 13"
    echo "14) Debian 11(国内)"
    echo "15) Debian 11(国内备用)"
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
        9) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -debian 11 -pwd 'hia123456' ;;
        10) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh almalinux 9 ;;
        11) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh almalinux 8 ;;
        12) curl -sS -O https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -almalinux 8 -pwd 'hia123456' ;;
        13) curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 13 ;;
        14) curl -O https://git.tccc.eu.org/https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh && sudo bash reinstall.sh debian 11 ;;
        15) curl -sS -O https://git.tccc.eu.org/https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && bash InstallNET.sh -debian 11 -pwd 'hia123456' ;;
        b) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
    exit 0
}

enable_bbr() {
    # 检测是否是 LXC 环境
    if grep -qaE 'lxc|container' /proc/1/environ 2>/dev/null || grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null; then
        echo -e "${YELLOW}⚠️ 检测到当前环境为 LXC 容器，不支持该BBR + TCP 优化！${RESET}"
        echo -e "${GRAY}此功能仅适用于独立服务器或完整虚拟机环境。${RESET}"
        echo
        return
    fi
    echo -e "${GREEN}正在开启 BBR 并覆盖写入优化参数...${RESET}"

    # 先备份原始配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # 覆盖写入优化内容
    cat > /etc/sysctl.conf <<EOF
# ===== HIA BBR + TCP 优化参数 =====
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 50331648
net.core.wmem_max = 50331648
net.core.rmem_default = 6291456
net.core.wmem_default = 6291456
net.ipv4.tcp_rmem = 4096 87380 50331648
net.ipv4.tcp_wmem = 4096 65536 50331648
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_early_retrans = 3
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 150000
net.core.netdev_budget = 700
net.core.netdev_budget_usecs = 1200
net.core.dev_weight = 768
net.core.dev_weight_tx_bias = 2
net.core.optmem_max = 81920
net.core.busy_poll = 50
net.core.busy_read = 50
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 16777216
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
# ===== End HIA =====
EOF

    # 立即生效
    sysctl -p

    echo -e "${GREEN}BBR 和 TCP 网络参数已覆盖写入并生效！${RESET}"
    sleep 2
    exit 0
}

block_sites() {
    # 颜色变量
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    RESET='\033[0m'

    # 1. 权限检查
    if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        SUDO=""
    fi

    # ---------------------------------------------------------
    # 第一部分：修改 DNS 
    # ---------------------------------------------------------
    echo -e "${BLUE}正在配置系统 DNS...${RESET}"
    
    # 备份 resolv.conf
    $SUDO cp /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null

    # 解开 resolv.conf 的锁定（防止某些系统加了 i 属性）
    $SUDO chattr -i /etc/resolv.conf 2>/dev/null || true

    $SUDO bash -c "cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 9.9.9.9
nameserver 208.67.222.222
EOF"
    echo -e "${GREEN}DNS 已更新。${RESET}"

    # ---------------------------------------------------------
    # 第二部分：屏蔽网站 (Hosts)
    # ---------------------------------------------------------
    echo -e "${BLUE}正在配置网站屏蔽列表...${RESET}"

    $SUDO chattr -i /etc/hosts 2>/dev/null || true
    $SUDO cp /etc/hosts /etc/hosts.bak

    if grep -q "# ===== Block Sites =====" /etc/hosts; then
        echo -e "${YELLOW}屏蔽条目已存在，正在覆盖更新...${RESET}"
        # 先删除旧的屏蔽块，以便更新
        $SUDO sed -i '/# ===== Block Sites =====/,/# ===== End Block =====/d' /etc/hosts
    fi

    # 追加新的列表
    $SUDO bash -c "cat >> /etc/hosts <<'EOF'
# ===== Block Sites =====
# ===== Block Sites =====
0.0.0.0 falundafa.org
0.0.0.0 minghui.org
0.0.0.0 epochtimes.com
0.0.0.0 ntdtv.com
0.0.0.0 voachinese.com
0.0.0.0 appledaily.com
0.0.0.0 nextdigital.com
0.0.0.0 dalailama.com
0.0.0.0 nytimes.com
0.0.0.0 bloomberg.com
0.0.0.0 independent.co.uk
0.0.0.0 freetibet.org
0.0.0.0 citizenpowerforchina.org
0.0.0.0 rfa.org
0.0.0.0 bbc.com
0.0.0.0 theinitium.com
0.0.0.0 tibet.net
0.0.0.0 jw.org
0.0.0.0 bannedbook.org
0.0.0.0 dw.com
0.0.0.0 storm.mg
0.0.0.0 yam.com
0.0.0.0 chinadigitaltimes.net
0.0.0.0 ltn.com.tw
0.0.0.0 mpweekly.com
0.0.0.0 cup.com.hk
0.0.0.0 thenewslens.com
0.0.0.0 inside.com.tw
0.0.0.0 everylittled.com
0.0.0.0 cool3c.com
0.0.0.0 taketla.zaiko.io
0.0.0.0 news.agentm.tw
0.0.0.0 sportsv.net
0.0.0.0 research.tnlmedia.com
0.0.0.0 ad2iction.com
0.0.0.0 viad.com.tw
0.0.0.0 tnlmedia.com
0.0.0.0 becomingaces.com
0.0.0.0 pincong.rocks
0.0.0.0 flipboard.com
0.0.0.0 soundofhope.org
0.0.0.0 wenxuecity.com
0.0.0.0 aboluowang.com
0.0.0.0 2047.name
0.0.0.0 shu.best
0.0.0.0 shenyunperformingarts.org
0.0.0.0 bbc.co.uk
0.0.0.0 cirosantilli.com
0.0.0.0 wsj.com
0.0.0.0 rfi.fr
0.0.0.0 chinapress.com.my
0.0.0.0 hancel.org
0.0.0.0 miraheze.org
0.0.0.0 zhuichaguoji.org
0.0.0.0 fawanghuihui.org
0.0.0.0 hopto.org
0.0.0.0 amnesty.org
0.0.0.0 hrw.org
0.0.0.0 irmct.org
0.0.0.0 zhengjian.org
0.0.0.0 wujieliulan.com
0.0.0.0 dongtaiwang.com
0.0.0.0 ultrasurf.us
0.0.0.0 yibaochina.com
0.0.0.0 roc-taiwan.org
0.0.0.0 creaders.net
0.0.0.0 upmedia.mg
0.0.0.0 ydn.com.tw
0.0.0.0 udn.com
0.0.0.0 theaustralian.com.au
0.0.0.0 voacantonese.com
0.0.0.0 voanews.com
0.0.0.0 bitterwinter.org
0.0.0.0 christianstudy.com
0.0.0.0 learnfalungong.com
0.0.0.0 usembassy-china.org.cn
0.0.0.0 master-li.qi-gong.me
0.0.0.0 zhengwunet.org
0.0.0.0 modernchinastudies.org
0.0.0.0 ninecommentaries.com
0.0.0.0 dafahao.com
0.0.0.0 shenyuncreations.com
0.0.0.0 tgcchinese.org
0.0.0.0 botanwang.com
0.0.0.0 falungong.org
0.0.0.0 freedomhouse.org
0.0.0.0 abc.net.au
0.0.0.0 tracker.openbittorrent.com
0.0.0.0 tracker.opentrackr.org
0.0.0.0 tracker.torrent.eu.org
0.0.0.0 tracker.publicbt.com
0.0.0.0 tracker.coppersurfer.tk
0.0.0.0 speedtest.net
0.0.0.0 www.speedtest.net
0.0.0.0 fast.com
0.0.0.0 speed.cloudflare.com
0.0.0.0 fiber.google.com
0.0.0.0 speedof.me
0.0.0.0 speedsmart.net
0.0.0.0 testmy.net
0.0.0.0 speedcheck.org
0.0.0.0 internethealthtest.org
0.0.0.0 openspeedtest.com
0.0.0.0 bandwidthplace.com
0.0.0.0 librespeed.org
0.0.0.0 xunlei.com
0.0.0.0 thunder.com
0.0.0.0 sandai.net
0.0.0.0 kankan.com
0.0.0.0 xlliveud.com
0.0.0.0 hub5btmain.sandai.net
0.0.0.0 upgrade.xl9.xunlei.com
0.0.0.0 bitpt.cn
0.0.0.0 tracker.openbittorrent.com
0.0.0.0 tracker.opentrackr.org
0.0.0.0 tracker.torrent.eu.org
0.0.0.0 tracker.publicbt.com
0.0.0.0 tracker.coppersurfer.tk
0.0.0.0 open.demonii.com
0.0.0.0 tracker.istole.it
0.0.0.0 bittorrent.com
0.0.0.0 magnet-link.com
0.0.0.0 torrentproject.org
# ===== End Block =====
EOF"

    # 重新锁定文件防止被系统自动修改
    $SUDO chattr +i /etc/resolv.conf 2>/dev/null || true
    $SUDO chattr +i /etc/hosts 2>/dev/null || true

    echo -e "${GREEN}操作完成！DNS 已锁定，网站屏蔽已生效。${RESET}"
}


install_hipf() {
    clear
    echo -e "${GREEN}正在安装 HiaPortFusion (HAProxy+GOST聚合转发脚本)...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/HiaPortFusion/main/install.sh)
    exit 0
}

install_tb() {
    clear
    echo -e "${GREEN}正在进入 流量均衡器...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/balancer/main/install.sh)
    exit 0
}


install_qm_s2a() {
    clear
    echo -e "${GREEN}正在进入 Sub2API 一键管理...${RESET}"
    bash <(curl -sSL https://raw.githubusercontent.com/hiapb/qm-s2a/main/install.sh)
    exit 0
}

install_qm_cli() {
    clear
    echo -e "${GREEN}正在进入 CLIProxyAPI 一键管理...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/qm-cli/main/install.sh)
    exit 0
}

install_api_shield() {
    clear
    echo -e "${GREEN}正在进入 零信任矩阵网关系统...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/api_shield/main/install.sh)
    exit 0
}

install_nic-master() {
    while true; do
        clear
        echo -e "${BLUE}=====================================================${RESET}"
        echo -e "${BLUE}                NIC-Master 部署分流中心              ${RESET}"
        echo -e "${BLUE}=====================================================${RESET}"
        echo -e " 请根据您的服务器硬件类型选择部署路径："
        echo -e " 1) ${GREEN}[虚拟化]${RESET} 非独服 (VPS / 云主机 / 虚拟机)"
        echo -e " 2) ${YELLOW}[裸金属]${RESET} 独立服务器 (物理机 / Dedicated Server)"
        echo -e " 0) 返回上级菜单"
        echo -e "${BLUE}=====================================================${RESET}"
        read -r -p " 请输入选项 [0-2]: " env_choice

        case "$env_choice" in
            1)
                echo -e "\n${GREEN}[处理中]${RESET} 正在拉取 VPS 通用优化脚本..."
                bash <(curl -fsSL https://raw.githubusercontent.com/inimemail/nic-master/main/install.sh)
                break
                ;;
            2)
                echo -e "\n${YELLOW}[处理中]${RESET} 正在拉取 独服重型调优引擎 (Smart-Auto)..."
                bash <(curl -fsSL https://raw.githubusercontent.com/inimemail/nic-master/main/auto.install)
                break
                ;;
            0)
                return
                ;;
            *)
                echo -e "\n${RED}无效选项，请重新输入...${RESET}"
                sleep 1
                ;;
        esac
    done
    exit 0
}

install_haproxy() {
    clear
    echo -e "${GREEN}正在安装 HAProxy TCP转发管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/Hia-HAProxy/main/install.sh)
    exit 0
}

install_realm() {
    clear
    echo -e "${GREEN}正在安装 Realm TCP+UDP万能转发脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh)
    exit 0
}

install_gost() {
    clear
    echo -e "${GREEN}正在安装 GOST TCP+UDP 转发管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-gost/main/install.sh)
    sleep 2
    exit 0
}

manage_warp() {
    echo -e "${GREEN}正在启动 WARP 管理脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/wg-cf/main/install.sh)
    exit 0
}

check_ports() {
    echo -e "${GREEN}正在启动 服务器http/https端口检测...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/check-web-ports/main/install.sh)
    exit 0
}

nuro_alist() {
    echo -e "${GREEN}正在启动 Nuro · Alist 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nurohia-alist/main/install.sh)
    exit 0
}

nuro_frp() {
    echo -e "${GREEN}正在启动 Nuro · FRP 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nuro-frp/main/install.sh)
    sleep 2
    exit 0
}

nuro_realm_tunnel() {
    echo -e "${GREEN}正在启动 Nuro · REALM(隧道) 一键部署&管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/realm/main/tunnel.sh)
    sleep 2
    exit 0
}

install_3-xui(){
    clear
    echo -e "${GREEN}正在安装 3X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_xui() {
    clear
    echo -e "${GREEN}正在安装 X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_aapanel() {
    clear
    echo -e "${GREEN}正在安装国际版宝塔（aapanel）...${RESET}"
    wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
    sleep 2
    exit 0
}

install_hipf() {
    clear
    echo -e "${GREEN}正在进入 HiaPortFusion 面板管理菜单...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nurohia/hiaportfusion/main/install.sh)
    exit 0
}

dlam_tunnel() {
    clear
    echo -e "${GREEN}多啦A梦面板...${RESET}"
    echo
    echo "请选择安装版本："
    echo "  1) 稳定版（Stable）"
    echo "  2) 开发版（Beta）"
    echo

    read -p "请输入选项 [1/2]（默认 1）: " choice

    # 默认选择 1
    choice=${choice:-1}

    case "$choice" in
        1)
            echo -e "${GREEN}已选择：稳定版${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/panel_install.sh \
                -o panel_install.sh
            ;;
        2)
            echo -e "${YELLOW}已选择：开发版（Beta）${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/beta/panel_install.sh \
                -o panel_install.sh
            ;;
        *)
            echo -e "${RED}无效选项，已自动使用稳定版${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/panel_install.sh \
                -o panel_install.sh
            ;;
    esac

    chmod +x panel_install.sh && ./panel_install.sh
    sleep 2
    exit 0
}


manage_dlamnode() {
    clear
    echo -e "${GREEN}多啦A梦节点端管理...${RESET}"
    echo
    echo "请选择安装版本："
    echo "  1) 稳定版（Stable）"
    echo "  2) 开发版（Beta）"
    echo

    read -p "请输入选项 [1/2]（默认 1）: " choice

    # 默认选择 1
    choice=${choice:-1}

    case "$choice" in
        1)
            echo -e "${GREEN}已选择：稳定版${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/install.sh \
                -o install.sh
            ;;
        2)
            echo -e "${YELLOW}已选择：开发版（Beta）${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/beta/install.sh \
                -o install.sh
            ;;
        *)
            echo -e "${RED}无效选项，已自动使用稳定版${RESET}"
            curl -L https://raw.githubusercontent.com/bqlpfy/flux-panel/refs/heads/main/install.sh \
                -o install.sh
            ;;
    esac

    chmod +x install.sh && ./install.sh
    sleep 2
    exit 0
}


 manage_clean(){
    clear
    echo -e "${GREEN}🧹一键深度清理...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/debian-safe/main/clean.sh)
    sleep 2
    exit 0
 }
 
block_asn(){
   clear
    echo -e "${GREEN}☁️ 中国云厂商 ASN 封禁管理...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/block_cloud_asn/main/installer.sh)
    sleep 2
    exit 0
}
install_docker(){
    clear
    echo -e "${GREEN}正在安装 Docker...${RESET}"
    curl -fsSL https://get.docker.com | bash -s docker
    sleep 2
    exit 0
}
install_1panel() {
    clear
    echo -e "${GREEN}正在安装 1Panel...${RESET}"
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
    sleep 2
    exit 0
}

install_V2bX() {
    clear
    echo -e "${GREEN}正在安装 V2bX...${RESET}"
    wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh && bash install.sh
    sleep 2
    exit 0
}

install_XrayR() {
    clear
    echo -e "${GREEN}正在安装 XrayR...${RESET}"
    wget -N https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh && bash install.sh
    sleep 2
    exit 0
}

install_nat(){
    clear
    echo -e "${GREEN}NAT 映射管理...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nixore-run/nix-nat/refs/heads/main/nat.sh)
    sleep 2
    exit 0
}

install_natty(){
    clear
    echo -e "${GREEN}NAT 调优...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/tuning/main/install.sh)
    sleep 2
    exit 0
}

install_mtr(){
    clear
    echo -e "${GREEN}💫 MTR 自动报告...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/auto-mtr/main/install.sh)
    sleep 2
    exit 0
}

install_chatwoot(){
    clear
    echo -e "${GREEN}🎧 Chatwoot 一键部署...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/chat-im/main/install.sh)
    sleep 2
    exit 0
}

install_ftp(){
    clear
    echo -e "${GREEN}📂 FTP/SFTP 备份工具...${RESET}"
    bash <(curl -L https://raw.githubusercontent.com/hiapb/ftp/main/back.sh)
    sleep 2
    exit 0
}

install_cron(){
    clear
    echo -e "${GREEN}📋 Linux 定时管理工具...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/cron/main/tool.sh)
    sleep 2
    exit 0
}

install_wg(){
    clear
    echo -e "${GREEN} 🛡️ WireGuard 一键脚本...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/wg/main/wg.sh)
    sleep 2
    exit 0
}

install_wg-udp(){
    clear
    echo -e "${GREEN} 📡 WG-Raw 一键脚本...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/wg-udp/main/wg.sh)
    sleep 2
    exit 0
}

install_wg-udp_more(){
    clear
    echo -e "${GREEN} 📡 WG-Raw-More 一键脚本...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/wg-more/main/install.sh)
    sleep 2
    exit 0
}

install_ss5(){
    clear
    echo -e "${GREEN} S-S5...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/hias/main/s.sh)
    sleep 2
    exit 0

}

install_vir(){
    clear
    echo -e "${GREEN} Virtualizor 一键安装...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/uoimrun/xxos/main/install.sh)
    sleep 2
    exit 0

}

install_backx(){
    clear
    echo -e "${GREEN} RelayX 一键备份...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/backx/main/install.sh)
    sleep 2
    exit 0

}


manage_nat(){
    clear
    echo -e "${GREEN} NAT管理工具...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/uoimrun/xxos/main/nat.sh)
    sleep 2
    exit 0
}

install_openlist(){
    clear
    echo -e "${GREEN}正在安装 OpenList...${RESET}"
    curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh
    sleep 2
    exit 0
}

install_aurora() {
    clear
    echo -e "${GREEN}正在安装极光面板...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
    sleep 2
    exit 0
}

check_ip_quality() {
    clear
    echo -e "${GREEN}正在进行 IP 质量检测...${RESET}"
    bash <(curl -sL IP.Check.Place)
    sleep 2
    exit 0
}

update_hia() {
    clear
    echo -e "${GREEN}正在更新HIA 管理脚本...${RESET}"
    bash <(curl -sSL https://raw.githubusercontent.com/hiapb/hia-manager-script/main/install.sh)
    sleep 2
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
    echo "8) 安装 3X-UI 面板"
    echo "9) 安装 X-UI 面板"
    echo "10) 安装国际版宝塔（aapanel）"
    echo "11) 安装 1Panel 面板"
    echo "12) 安装极光面板"
    echo "13) IP 质量检测"
    echo "14) 服务器 http/https端口检测"
    echo "15) Nuro · Alist 一键部署&管理"
    echo "16) Nuro · FRP 一键部署&管理"
    echo "17) Nuro · REALM(隧道) 一键部署&管理"
    echo "18) 安装 Docker"
    echo "19) 哆啦A梦面板部署"
    echo "20) 多啦A梦节点端管理"
    echo "21) 🧹一键深度清理"
    echo "22) 追加hosts屏蔽项"
    echo "23) ☁️ 中国云厂商 ASN 封禁管理"
    echo "24) 安装 V2bX"
    echo "25) 安装 XrayR"
    echo "26) 安装 OpenList"
    echo "27) NAT 映射管理"
    echo "28) NAT 调优"
    echo "29) 💫 MTR 自动报告"
    echo "30) 🎧 Chatwoot"
    echo "31) 📂 FTP/SFTP 备份工具"
    echo "32) 📋 Linux 定时管理"
    echo "33) 🛡️ WireGuard 一键脚本"
    echo "34) 📡 WG-Raw 一键脚本"
    echo "35) 📎 S-S5 一键脚本"
    echo "36) Virtualizor 一键安装"
    echo "37) NAT管理工具"
    echo "38) RelayX 一键备份"
    echo "39) 📡 WG-Raw-More 一键脚本"
    echo "40) HiaPortFusion 面板"
    echo "41) 流量均衡器"
    echo "42) Sub2API 一键管理"
    echo "43) CLIProxyAPI 一键管理"
    echo "44) 零信任矩阵网关系统"
    echo "45) nic-master"
    echo "u) 更新 HIA 管理脚本"
    echo "q) 卸载 HIA 管理脚本"
    echo "0) 退出"
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
        8)  install_3-xui ;;
        9)  install_xui ;;
        10)  install_aapanel ;;
        11) install_1panel ;;
        12) install_aurora ;;
        13) check_ip_quality ;;
        14) check_ports ;;
        15) nuro_alist ;;
        16) nuro_frp ;;
        17) nuro_realm_tunnel ;;
        18) install_docker ;;
        19) dlam_tunnel ;;
        20) manage_dlamnode ;;
        21) manage_clean ;;
        22) block_sites ;;
        23) block_asn ;;
        24) install_V2bX ;;
        25) install_XrayR ;;
        26) install_openlist ;;
        27) install_nat ;;
        28) install_natty ;;
        29) install_mtr ;;
        30) install_chatwoot ;;
        31) install_ftp ;;
        32) install_cron ;;
        33) install_wg ;;
        34) install_wg-udp ;;
        35) install_ss5 ;;
        36) install_vir ;;
        37) manage_nat ;;
        38) install_backx ;;
        39) install_wg-udp_more ;;
        40) install_hipf ;;
        41) install_tb ;;
        42) install_qm_s2a ;;
        43) install_qm_cli ;;
        44) install_api_shield ;;
        45) install_nic-master;;
        u)  update_hia ;;
        q)  uninstall_hia ;;
        0)  exit 0 ;;
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
