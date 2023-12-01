#!/bin/bash
# from
# https://github.com/spiritLHLS/pve
# 2023.11.28

########## 预设部分输出和部分中间变量

_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }
export DEBIAN_FRONTEND=noninteractive
utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
    echo "No UTF-8 locale found"
else
    export LC_ALL="$utf8_locale"
    export LANG="$utf8_locale"
    export LANGUAGE="$utf8_locale"
    echo "Locale set to $utf8_locale"
fi
rm -rf /usr/local/bin/build_backend_pve.txt

check_cdn() {
    local o_url=$1
    for cdn_url in "${cdn_urls[@]}"; do
        if curl -sL -k "$cdn_url$o_url" --max-time 6 | grep -q "success" >/dev/null 2>&1; then
            export cdn_success_url="$cdn_url"
            return
        fi
        sleep 0.5
    done
    export cdn_success_url=""
}

check_cdn_file() {
    check_cdn "https://raw.githubusercontent.com/spiritLHLS/ecs/main/back/test"
    if [ -n "$cdn_success_url" ]; then
        _yellow "CDN available, using CDN"
    else
        _yellow "No CDN available, no use CDN"
    fi
}

get_system_arch() {
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    # 根据架构信息设置系统位数并下载文件,其余 * 包括了 x86_64
    case "${sysarch}" in
    "i386" | "i686" | "x86_64")
        system_arch="x86"
        ;;
    "armv7l" | "armv8" | "armv8l" | "aarch64")
        system_arch="arch"
        ;;
    *)
        system_arch=""
        ;;
    esac
}

check_interface() {
    if [ -z "$interface_2" ]; then
        interface=${interface_1}
        return
    elif [ -n "$interface_1" ] && [ -n "$interface_2" ]; then
        if ! grep -q "$interface_1" "/etc/network/interfaces" && ! grep -q "$interface_2" "/etc/network/interfaces" && [ -f "/etc/network/interfaces.d/50-cloud-init" ]; then
            if grep -q "$interface_1" "/etc/network/interfaces.d/50-cloud-init" || grep -q "$interface_2" "/etc/network/interfaces.d/50-cloud-init"; then
                if ! grep -q "$interface_1" "/etc/network/interfaces.d/50-cloud-init" && grep -q "$interface_2" "/etc/network/interfaces.d/50-cloud-init"; then
                    interface=${interface_2}
                    return
                elif ! grep -q "$interface_2" "/etc/network/interfaces.d/50-cloud-init" && grep -q "$interface_1" "/etc/network/interfaces.d/50-cloud-init"; then
                    interface=${interface_1}
                    return
                fi
            fi
        fi
        if grep -q "$interface_1" "/etc/network/interfaces"; then
            interface=${interface_1}
            return
        elif grep -q "$interface_2" "/etc/network/interfaces"; then
            interface=${interface_2}
            return
        else
            interfaces_list=$(ip addr show | awk '/^[0-9]+: [^lo]/ {print $2}' | cut -d ':' -f 1)
            interface=""
            for iface in $interfaces_list; do
                if [[ "$iface" = "$interface_1" || "$iface" = "$interface_2" ]]; then
                    interface="$iface"
                fi
            done
            if [ -z "$interface" ]; then
                interface="eth0"
            fi
            return
        fi
    else
        interface="eth0"
        return
    fi
    _red "Physical interface not found, exit execution"
    _red "找不到物理接口，退出执行"
    exit 1
}

update_sysctl() {
    sysctl_config="$1"
    if grep -q "^$sysctl_config" /etc/sysctl.conf; then
        if grep -q "^#$sysctl_config" /etc/sysctl.conf; then
            sed -i "s/^#$sysctl_config/$sysctl_config/" /etc/sysctl.conf
        fi
    else
        echo "$sysctl_config" >>/etc/sysctl.conf
    fi
}

remove_duplicate_lines() {
    chattr -i "$1"
    # 预处理：去除行尾空格和制表符
    sed -i 's/[ \t]*$//' "$1"
    # 去除重复行并跳过空行和注释行
    if [ -f "$1" ]; then
        awk '{ line = $0; gsub(/^[ \t]+/, "", line); gsub(/[ \t]+/, " ", line); if (!NF || !seen[line]++) print $0 }' "$1" >"$1.tmp" && mv -f "$1.tmp" "$1"
    fi
    chattr +i "$1"
}

########## 查询信息

if ! command -v lshw >/dev/null 2>&1; then
    apt-get install -y lshw
fi
if ! command -v ipcalc >/dev/null 2>&1; then
    apt-get install -y ipcalc
fi
if ! command -v sipcalc >/dev/null 2>&1; then
    apt-get install -y sipcalc
fi
if ! command -v ovs-vsctl >/dev/null 2>&1; then
    apt-get install -y openvswitch-switch
fi
apt-get install -y net-tools

# cdn检测
cdn_urls=("https://cdn0.spiritlhl.top/" "http://cdn3.spiritlhl.net/" "http://cdn1.spiritlhl.net/" "https://ghproxy.com/" "http://cdn2.spiritlhl.net/")
check_cdn_file

# 检测架构
get_system_arch

# sysctl路径查询
sysctl_path=$(which sysctl)

# 检测物理接口和MAC地址
interface_1=$(lshw -C network | awk '/logical name:/{print $3}' | sed -n '1p')
interface_2=$(lshw -C network | awk '/logical name:/{print $3}' | sed -n '2p')
check_interface
if [ ! -f /usr/local/bin/pve_mac_address ] || [ ! -s /usr/local/bin/pve_mac_address ] || [ "$(sed -e '/^[[:space:]]*$/d' /usr/local/bin/pve_mac_address)" = "" ]; then
    mac_address=$(ip -o link show dev ${interface} | awk '{print $17}')
    echo "$mac_address" >/usr/local/bin/pve_mac_address
fi
mac_address=$(cat /usr/local/bin/pve_mac_address)
if [ ! -f /etc/systemd/network/10-persistent-net.link ]; then
    echo '[Match]' >/etc/systemd/network/10-persistent-net.link
    echo "MACAddress=${mac_address}" >>/etc/systemd/network/10-persistent-net.link
    echo "" >>/etc/systemd/network/10-persistent-net.link
    echo '[Link]' >>/etc/systemd/network/10-persistent-net.link
    echo "Name=${interface}" >>/etc/systemd/network/10-persistent-net.link
    /etc/init.d/udev force-reload
fi

# 检测IPV6相关的信息
interfaces_file="/etc/network/interfaces"
status_he=false
if grep -q "he-ipv6" /etc/network/interfaces; then
    wget ${cdn_success_url}https://raw.githubusercontent.com/oneclickvirt/6in4/main/covert.sh -O /root/covert.sh
    chmod 777 covert.sh
    ./covert.sh
    sleep 1
    status_he=true
    chattr -i /etc/network/interfaces
    temp_config=$(awk '/auto he-ipv6/{flag=1; print $0; next} flag && flag++<10' /etc/network/interfaces)
    sed -i '/^auto he-ipv6/,/^$/d' /etc/network/interfaces
    chattr +i /etc/network/interfaces
    ipv6_address=$(echo "$temp_config" | awk '/address/ {print $2}')
    ipv6_gateway=$(echo "$temp_config" | awk '/gateway/ {print $2}')
    ipv6_prefixlen=$(ifconfig he-ipv6 | grep -oP 'prefixlen \K\d+' | head -n 1)
    target_mask=${ipv6_prefixlen}
    ((target_mask += 8 - ($target_mask % 8)))
    echo "$target_mask" >/usr/local/bin/pve_ipv6_prefixlen
    ipv6_subnet_2=$(sipcalc --v6split=${target_mask} ${ipv6_gateway}/${ipv6_prefixlen} | awk '/Network/{n++} n==2' | awk '{print $3}' | grep -v '^$')
    ipv6_subnet_2_without_last_segment="${ipv6_subnet_2%:*}:"
    new_subnet="${ipv6_subnet_2_without_last_segment}1/${target_mask}"
    echo ${ipv6_subnet_2_without_last_segment}1 >/usr/local/bin/pve_check_ipv6
    echo $ipv6_gateway >/usr/local/bin/pve_ipv6_gateway
else
    if [ -f /usr/local/bin/pve_ipv6_prefixlen ]; then
        ipv6_prefixlen=$(cat /usr/local/bin/pve_ipv6_prefixlen)
    fi
    if [ -f /usr/local/bin/pve_ipv6_gateway ]; then
        ipv6_gateway=$(cat /usr/local/bin/pve_ipv6_gateway)
    fi
    if [ -f /usr/local/bin/pve_check_ipv6 ]; then
        ipv6_address=$(cat /usr/local/bin/pve_check_ipv6)
        # ipv6_address_without_last_segment="${ipv6_address%:*}:"
        # 重构IPV6地址，使用该IPV6子网内的0001结尾的地址
        ipv6_address=$(sipcalc -i ${ipv6_address}/${ipv6_prefixlen} | grep "Subnet prefix (masked)" | cut -d ' ' -f 4 | cut -d '/' -f 1 | sed 's/:0:0:0:0:/::/' | sed 's/:0:0:0:/::/')
        ipv6_address="${ipv6_address%:*}:1"
        if [ "$ipv6_address" == "$ipv6_gateway" ]; then
            ipv6_address="${ipv6_address%:*}:2"
        fi
        ipv6_address_without_last_segment="${ipv6_address%:*}:"
        if ping -c 1 -6 -W 3 $ipv6_address >/dev/null 2>&1; then
            check_ipv6
            echo "${ipv6_address}" >/usr/local/bin/pve_check_ipv6
            ipv6_address_without_last_segment="${ipv6_address%:*}:"
        fi
    fi
fi
if [[ $ipv6_gateway == fe80* ]]; then
    ipv6_gateway_fe80="Y"
else
    ipv6_gateway_fe80="N"
fi
fe80_address=$(cat /usr/local/bin/pve_fe80_address)

# 配置 ndpresponder 的守护进程
# if [ "$ipv6_prefixlen" -le 64 ]; then
# if [ ! -z "$ipv6_address" ] && [ ! -z "$ipv6_prefixlen" ] && [ ! -z "$ipv6_gateway" ] && [ ! -z "$ipv6_address_without_last_segment" ]; then
if [ ! -z "$ipv6_address" ] && [ ! -z "$ipv6_prefixlen" ] && [ ! -z "$ipv6_gateway" ]; then
    if [ "$system_arch" = "x86" ]; then
        wget ${cdn_success_url}https://github.com/spiritLHLS/pve/releases/download/ndpresponder_x86/ndpresponder -O /usr/local/bin/ndpresponder
        wget ${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/pve/main/extra_scripts/ndpresponder.service -O /etc/systemd/system/ndpresponder.service
        chmod 777 /usr/local/bin/ndpresponder
        chmod 777 /etc/systemd/system/ndpresponder.service
    elif [ "$system_arch" = "arch" ]; then
        wget ${cdn_success_url}https://github.com/spiritLHLS/pve/releases/download/ndpresponder_aarch64/ndpresponder -O /usr/local/bin/ndpresponder
        wget ${cdn_success_url}https://raw.githubusercontent.com/spiritLHLS/pve/main/extra_scripts/ndpresponder.service -O /etc/systemd/system/ndpresponder.service
        chmod 777 /usr/local/bin/ndpresponder
        chmod 777 /etc/systemd/system/ndpresponder.service
    fi
fi
# fi

# 检测IPV4相关的信息
if [ -f /usr/local/bin/pve_ipv4_address ]; then
    ipv4_address=$(cat /usr/local/bin/pve_ipv4_address)
else
    ipv4_address=$(ip addr show | awk '/inet .*global/ && !/inet6/ {print $2}' | sed -n '1p')
    echo "$ipv4_address" >/usr/local/bin/pve_ipv4_address
fi
if [ -f /usr/local/bin/pve_ipv4_gateway ]; then
    ipv4_gateway=$(cat /usr/local/bin/pve_ipv4_gateway)
else
    ipv4_gateway=$(ip route | awk '/default/ {print $3}' | sed -n '1p')
    echo "$ipv4_gateway" >/usr/local/bin/pve_ipv4_gateway
fi
if [ -f /usr/local/bin/pve_ipv4_subnet ]; then
    ipv4_subnet=$(cat /usr/local/bin/pve_ipv4_subnet)
else
    ipv4_subnet=$(ipcalc -n "$ipv4_address" | grep -oP 'Netmask:\s+\K.*' | awk '{print $1}')
    echo "$ipv4_subnet" >/usr/local/bin/pve_ipv4_subnet
fi

# 录入网关
if [ ! -f /etc/network/interfaces.bak ]; then
    cp /etc/network/interfaces /etc/network/interfaces.bak
fi
# 修正部分网络设置重复的错误
if [[ -f "/etc/network/interfaces.d/50-cloud-init" && -f "/etc/network/interfaces" ]]; then
    if grep -q "auto lo" "/etc/network/interfaces.d/50-cloud-init" && grep -q "iface lo inet loopback" "/etc/network/interfaces.d/50-cloud-init" && grep -q "auto lo" "/etc/network/interfaces" && grep -q "iface lo inet loopback" "/etc/network/interfaces"; then
        # 从 /etc/network/interfaces.d/50-cloud-init 中删除重复的行
        chattr -i /etc/network/interfaces.d/50-cloud-init
        sed -i '/auto lo/d' "/etc/network/interfaces.d/50-cloud-init"
        sed -i '/iface lo inet loopback/d' "/etc/network/interfaces.d/50-cloud-init"
        chattr +i /etc/network/interfaces.d/50-cloud-init
    fi
fi
if [ -f "/etc/network/interfaces.new" ]; then
    chattr -i /etc/network/interfaces.new
    rm -rf /etc/network/interfaces.new
fi
chattr -i /etc/network/interfaces
if ! grep -q "auto lo" /etc/network/interfaces; then
    _blue "Can not find 'auto lo' in /etc/network/interfaces"
    exit 1
fi
if ! grep -q "iface lo inet loopback" /etc/network/interfaces; then
    _blue "Can not find 'iface lo inet loopback' in /etc/network/interfaces"
    exit 1
fi
# 配置vmbr0
chattr -i /etc/network/interfaces
if grep -q "vmbr0" "/etc/network/interfaces"; then
    _blue "vmbr0 already exists in /etc/network/interfaces"
    _blue "vmbr0 已存在在 /etc/network/interfaces"
else
    if [ -z "$ipv6_address" ] || [ -z "$ipv6_prefixlen" ] || [ -z "$ipv6_gateway" ] && [ ! -f /usr/local/bin/pve_last_ipv6 ]; then
        cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address $ipv4_address
    gateway $ipv4_gateway
    bridge_ports $interface
    bridge_stp off
    bridge_fd 0
EOF
    elif [ -f "/usr/local/bin/iface_auto.txt" ] && [ ! -f /usr/local/bin/pve_last_ipv6 ]; then
        cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address $ipv4_address
    gateway $ipv4_gateway
    bridge_ports $interface
    bridge_stp off
    bridge_fd 0

iface vmbr0 inet6 auto
    bridge_ports $interface
EOF
    elif [ -f /usr/local/bin/pve_last_ipv6 ]; then
        last_ipv6=$(cat /usr/local/bin/pve_last_ipv6)
        cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address $ipv4_address
    gateway $ipv4_gateway
    bridge_ports $interface
    bridge_stp off
    bridge_fd 0

iface vmbr0 inet6 static
    address ${last_ipv6}
    gateway ${ipv6_gateway}

iface vmbr0 inet6 static
    address ${ipv6_address}/128
EOF
    else
        cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr0
iface vmbr0 inet static
    address $ipv4_address
    gateway $ipv4_gateway
    bridge_ports $interface
    bridge_stp off
    bridge_fd 0

iface vmbr0 inet6 static
    address ${ipv6_address}/128
    gateway ${ipv6_gateway}
EOF
    fi
fi
if [[ "${ipv6_gateway_fe80}" == "N" ]]; then
    chattr -i /etc/network/interfaces
    echo "    up ip addr del $fe80_address dev $interface" >> /etc/network/interfaces
    remove_duplicate_lines "/etc/network/interfaces"
    chattr -i /etc/network/interfaces
fi
if grep -q "vmbr1" /etc/network/interfaces; then
    _blue "vmbr1 already exists in /etc/network/interfaces"
    _blue "vmbr1 已存在在 /etc/network/interfaces"
elif [ -f "/usr/local/bin/iface_auto.txt" ]; then
    cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr1
iface vmbr1 inet static
    address 192.168.200.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up echo 1 > /proc/sys/net/ipv4/conf/vmbr1/proxy_arp
    post-up iptables -t nat -A POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE

pre-up echo 2 > /proc/sys/net/ipv6/conf/vmbr0/accept_ra
EOF
elif [ -z "$ipv6_address" ] || [ -z "$ipv6_prefixlen" ] || [ -z "$ipv6_gateway" ] || [ "$status_he" = true ]; then
    cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr1
iface vmbr1 inet static
    address 192.168.200.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up echo 1 > /proc/sys/net/ipv4/conf/vmbr1/proxy_arp
    post-up iptables -t nat -A POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE
EOF
else
    cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr1
iface vmbr1 inet static
    address 192.168.200.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up echo 1 > /proc/sys/net/ipv4/conf/vmbr1/proxy_arp
    post-up iptables -t nat -A POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '192.168.200.0/24' -o vmbr0 -j MASQUERADE

iface vmbr1 inet6 static
    address 2001:db8:1::1/64
    post-up sysctl -w net.ipv6.conf.all.forwarding=1
    post-up ip6tables -t nat -A POSTROUTING -s 2001:db8:1::/64 -o vmbr0 -j MASQUERADE
    post-down sysctl -w net.ipv6.conf.all.forwarding=0
    post-down ip6tables -t nat -D POSTROUTING -s 2001:db8:1::/64 -o vmbr0 -j MASQUERADE
EOF
fi
if [ -n "$ipv6_prefixlen" ] && [ "$((ipv6_prefixlen))" -le 64 ]; then
    if grep -q "vmbr2" /etc/network/interfaces; then
        _blue "vmbr2 already exists in /etc/network/interfaces"
        _blue "vmbr2 已存在在 /etc/network/interfaces"
    elif [ "$status_he" = true ]; then
        chattr -i /etc/network/interfaces
        sudo tee -a /etc/network/interfaces <<EOF

${temp_config}
EOF
        cat <<EOF | sudo tee -a /etc/network/interfaces

auto vmbr2
iface vmbr2 inet6 static
    address ${new_subnet}
    bridge_ports none
    bridge_stp off
    bridge_fd 0
EOF
        if [ -f "/usr/local/bin/ndpresponder" ]; then
            new_exec_start="ExecStart=/usr/local/bin/ndpresponder -i he-ipv6 -n ${new_subnet}"
            file_path="/etc/systemd/system/ndpresponder.service"
            line_number=6
            sed -i "${line_number}s|.*|${new_exec_start}|" "$file_path"
        fi
        update_sysctl "net.ipv6.conf.all.forwarding=1"
        update_sysctl "net.ipv6.conf.all.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.default.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr0.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr1.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr2.proxy_ndp=1"
    elif [ ! -z "$ipv6_address" ] && [ ! -z "$ipv6_prefixlen" ] && [ ! -z "$ipv6_gateway" ] && [ ! -z "$ipv6_address_without_last_segment" ]; then
        cat <<EOF | sudo tee -a /etc/network/interfaces
auto vmbr2
iface vmbr2 inet6 static
    address ${ipv6_address}/${ipv6_prefixlen}
    bridge_ports none
    bridge_stp off
    bridge_fd 0
EOF
        if [ -f "/usr/local/bin/ndpresponder" ]; then
            new_exec_start="ExecStart=/usr/local/bin/ndpresponder -i vmbr0 -n ${ipv6_address_without_last_segment}/${ipv6_prefixlen}"
            file_path="/etc/systemd/system/ndpresponder.service"
            line_number=6
            sed -i "${line_number}s|.*|${new_exec_start}|" "$file_path"
        fi
        update_sysctl "net.ipv6.conf.all.forwarding=1"
        update_sysctl "net.ipv6.conf.all.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.default.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr0.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr1.proxy_ndp=1"
        update_sysctl "net.ipv6.conf.vmbr2.proxy_ndp=1"
    fi
fi
chattr +i /etc/network/interfaces
rm -rf /usr/local/bin/iface_auto.txt

# 加载iptables并设置回源且允许NAT端口转发
apt-get install -y iptables iptables-persistent
iptables -t nat -A POSTROUTING -j MASQUERADE
update_sysctl "net.ipv4.ip_forward=1"
${sysctl_path} -p

# 重启配置
service networking restart
systemctl restart networking.service
sleep 3
ifreload -ad
iptables-save | awk '{if($1=="COMMIT"){delete x}}$1=="-A"?!x[$0]++:1' | iptables-restore
if [ -f "/usr/local/bin/ndpresponder" ]; then
    systemctl daemon-reload
    systemctl enable ndpresponder.service
    systemctl start ndpresponder.service
    systemctl status ndpresponder.service 2>/dev/null
fi

# 删除可能存在的原有的网卡配置
if [ ! -f /etc/network/interfaces_nat.bak ]; then
    cp /etc/network/interfaces /etc/network/interfaces_nat.bak
    chattr -i /etc/network/interfaces
    input_file="/etc/network/interfaces"
    output_file="/etc/network/interfaces.tmp"
    start_pattern="iface lo inet loopback"
    end_pattern="auto vmbr0"
    delete_lines=0
    while IFS= read -r line; do
        if [[ $line == *"$start_pattern"* ]]; then
            delete_lines=1
        fi
        if [ $delete_lines -eq 0 ] || [[ $line == *"$start_pattern"* ]] || [[ $line == *"$end_pattern"* ]]; then
            echo "$line" >>"$output_file"
        fi
        if [[ $line == *"$end_pattern"* ]]; then
            delete_lines=0
        fi
    done <"$input_file"
    mv "$output_file" "$input_file"
    chattr +i /etc/network/interfaces
fi

# 已加载网络，删除对应缓存文件
if [ -f "/etc/network/interfaces.new" ]; then
    chattr -i /etc/network/interfaces.new
    rm -rf /etc/network/interfaces.new
fi
systemctl start check-dns.service

# 检测ndppd服务是否启动了
service_status=$(systemctl is-active ndpresponder.service)
if [ "$service_status" == "active" ]; then
    _green "The ndpresponder service started successfully and is running, and the host can open a service with a separate IPV6 address."
    _green "ndpresponder服务启动成功且正在运行，宿主机可开设带独立IPV6地址的服务。"
else
    _green "The status of the ndpresponder service is abnormal and the host may not open a service with a separate IPV6 address."
    _green "ndpresponder服务状态异常，宿主机不可开设带独立IPV6地址的服务。"
fi

# 打印信息
# _green "Although the gateway has been set automatically, I am not sure if it has been applied successfully, please check in Datacenter-->pve-->System-->Network in PVE"
# _green "If vmbr0 and vmbr1 are displayed properly and the Apply Configuration button is grayed out, there is no need to reboot"
# _green "If the above scenario is different, click on the Apply Configuration button, wait a few minutes and reboot the system to ensure that the gateway has been successfully applied"
_green "you can test open a virtual machine or container to see if the actual network has been applied successfully"
# _green "虽然已自动设置网关，但不确定是否已成功应用，请查看PVE中的 Datacenter-->pve-->System-->Network"
# _green "如果 vmbr0 和 vmbr1 已正常显示且 Apply Configuration 这个按钮是灰色的，则不用执行 reboot 重启系统"
# _green "上述情形如果有不同的，请点击 Apply Configuration 这个按钮，等待几分钟后重启系统，确保网关已成功应用"
_green "你可以测试开一个虚拟机或者容器看看就知道是不是实际网络已应用成功了"
