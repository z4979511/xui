#!/usr/bin/env bash 

# 定义颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 欢迎词和联系方式
echo -e "${green}欢迎使用尼古拉斯狗蛋的 x-ui 安装脚本！${plain}"
echo -e "${yellow}感谢您的支持！如有任何问题，欢迎联系我:${plain}"
echo -e "${green}联系方式: V858737833，B站ID:nicholas-goudan，https://space.bilibili.com/16297540${plain}"
echo -e "${yellow}请使用尼古拉斯狗蛋的正版代码，防止被骗${plain}"
echo -e "----------------------------------------------"

cur_dir=$(pwd)

# check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n"
    exit 1
fi

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n"
    exit 1
fi

# check architecture
arch=$(uname -m)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "s390x" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
    arch="amd64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ $(getconf LONG_BIT) != '64' ]; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n"
        exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n"
        exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n"
        exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        if ! command -v yum &>/dev/null; then
            echo -e "${red}未找到 yum，安装失败！${plain}"
            exit 1
        fi
        yum install wget curl tar jq -y
    else
        if ! command -v apt &>/dev/null; then
            echo -e "${red}未找到 apt，安装失败！${plain}"
            exit 1
        fi
        apt install wget curl tar jq -y
    fi
}

# 安全设置
config_after_install() {
    echo -e "${yellow}出于安全考虑，安装/更新完成后需要强制修改端口与账户密码${plain}"
    read -p "确认是否继续,如选择n则跳过本次端口与账户密码设定[y/n]:" config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "请设置您的账户名:" config_account
        echo -e "${yellow}您的账户名将设定为:${config_account}${plain}"
        read -p "请设置您的账户密码:" config_password
        echo -e "${yellow}您的账户密码将设定为:${config_password}${plain}"
        read -p "请设置面板访问端口:" config_port
        echo -e "${yellow}您的面板访问端口将设定为:${config_port}${plain}"
        # 提醒用户确保端口已放行
        echo -e "${yellow}请确保 ${config_port} 端口已在防火墙中放行${plain}"
        echo -e "${yellow}确认设定,设定中${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}账户密码设定完成${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}面板端口设定完成${plain}"
    else
        echo -e "${red}已取消设定...${plain}"
        if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
            local usernameTemp=$(head -c 6 /dev/urandom | base64)
            local passwordTemp=$(head -c 6 /dev/urandom | base64)
            local portTemp=$(echo $RANDOM)
            /usr/local/x-ui/x-ui setting -username ${usernameTemp} -password ${passwordTemp}
            /usr/local/x-ui/x-ui setting -port ${portTemp}
            echo -e "检测到您属于全新安装,出于安全考虑已自动为您生成随机用户与端口:"
            echo -e "###############################################"
            echo -e "${green}面板登录用户名:${usernameTemp}${plain}"
            echo -e "${green}面板登录用户密码:${passwordTemp}${plain}"
            echo -e "${red}面板登录端口:${portTemp}${plain}"
            echo -e "###############################################"
            echo -e "${red}如您遗忘了面板登录相关信息,可在安装完成后输入x-ui,输入选项7查看面板登录信息${plain}"
        else
            echo -e "${red}当前属于版本升级,保留之前设置项,登录方式保持不变,可输入x-ui后键入数字7查看面板登录信息${plain}"
        fi
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Lsk "https://api.github.com/repos/z4979511/xui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -z "$last_version" ]]; then
            echo -e "${red}检测 x-ui 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 x-ui 版本安装${plain}"
            read -p "请输入你想安装的 x-ui 版本号 (例如: v0.3.4.4): " last_version
            if [[ -z "$last_version" ]]; then
                echo -e "${red}未指定版本，安装失败！${plain}"
                exit 1
            fi
        fi
        echo -e "检测到 x-ui 最新版本：${last_version}，开始安装"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/z4979511/xui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 x-ui 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/z4979511/xui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "开始安装 x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${
