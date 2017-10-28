#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS, Debian, Ubuntu
#   Description: One click Install Shadowsocks-go server
#   Author: Teddysun <i@teddysun.com>
#   Thanks: @cyfdecyf <https://twitter.com/cyfdecyf>
#   Intro:  http://teddysun.com/392.html
#===============================================================================================

clear
echo ""
echo "#############################################################"
echo "# One click Install Shadowsocks-go server                   #"
echo "# Intro: http://www.julyerr.club/2017/10/23/gfwSS/          #"
echo "# Author: julyerr <julyerr.test@gmail.com>                  #"
echo "# Thanks: teddysun's auto click-install script for refrence #"
echo "#############################################################"
echo ""

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Check OS
function checkos(){
    if [ -f /etc/redhat-release ];then
        OS=CentOS
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS=Debian
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "Not supported OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# is 64bit or not
function is_64bit(){
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi        
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_install(){
    # Set shadowsocks-go config password
    echo "Please input server name or ip for shadowsocks-go:" 
    read -p "(Default : julyerr.club):" shadowsockss
    [ -z "$shadowsockss" ] && shadowsockspwd="julyerr.club"
    echo "Please input password for shadowsocks-go:"
    read -p "(Default password: julyerr.club):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="julyerr.club"
    echo ""
    echo "---------------------------"
    echo "password = $shadowsockspwd"
    echo "---------------------------"
    echo ""
    # Set shadowsocks-go config port
    while true
    do
    echo -e "Please input port for shadowsocks-go [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    #Install necessary dependencies
    if [ "$OS" == 'CentOS' ];then
        yum install -y wget unzip gzip curl
    else
        apt-get -y update
        apt-get install -y wget unzip gzip curl
    fi
    # Get IP address
    # echo "Getting Public IP address, Please wait a moment..."
    # IP=$(curl -s -4 icanhazip.com)
    # if [[ "$IP" = "" ]]; then
    #     IP=$(curl -s -4 ipinfo.io | grep "ip" | awk -F\" '{print $4}')
    # fi
    # echo -e "Your main public IP is\t\033[32m$IP\033[0m"
    # echo ""
    #Current folder
    cur_dir=`pwd`
}

# Download shadowsocks-go
function download_files(){
    cd $cur_dir
    if is_64bit; then
        if ! wget -c https://github.com/julyerr/julyerr.github.io/raw/master/utils/shadowsocks-local;then
            echo "Failed to download shadowsocks-local"
            exit 1
        fi
        mv -f shadowsocks-local /usr/bin/shadowsocks-local
    else
        echo "the script doesn't not support 32 bit system"
        exit 1
        # if ! wget -c https://github.com/iMeiji/shadowsocks_install/releases/download/0.1/shadowsocks-local-linux32-1.1.4.gz;then
        #     echo "Failed to download shadowsocks-local-linux32-1.1.4.gz"
        #     exit 1
        # fi
        # gzip -d shadowsocks-local-linux32-1.1.4.gz
        # if [ $? -eq 0 ];then
        #     echo "Decompress shadowsocks-local-linux32-1.1.4.gz success."
        # else
        #     echo "Decompress shadowsocks-local-linux32-1.1.4.gz failed! Please check gzip command."
        #     exit 1
        # fi
        # mv -f shadowsocks-local-linux32-1.1.4 /usr/bin/shadowsocks-local
    fi

    # # Download start script
    # if [ "$OS" == 'CentOS' ];then
    #     if ! wget --no-check-certificate -O shadowsocks-go https://raw.githubusercontent.com/iMeiji/shadowsocks_install/master/shadowsocks-go; then
    #         echo "Failed to download shadowsocks-go auto start script!"
    #         exit 1
    #     fi
    # else
    #     if ! wget --no-check-certificate -O shadowsocks-go https://raw.githubusercontent.com/iMeiji/shadowsocks_install/master/shadowsocks-go-debian; then
    #         echo "Failed to download shadowsocks-go auto start script!"
    #         exit 1
    #     fi
    # fi
}

# Config shadowsocks
function config_shadowsocks(){
    if [ ! -d /etc/shadowsocks ];then
        mkdir /etc/shadowsocks
    fi
    cat > /etc/shadowsocks/config.json<<-EOF
{
    "server":"${shadowsockss}",
    "server_port":${shadowsocksport},
    "local_address": "0.0.0.0",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "method":"rc4-md5",
    "fast_open": false
}
EOF
}

# iptables set
function iptables_set(){
    echo "iptables start setting..."
    /sbin/service iptables status 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        /etc/init.d/iptables status | grep '${shadowsocksport}' | grep 'ACCEPT' >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            /sbin/iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${shadowsocksport} -j ACCEPT
            /etc/init.d/iptables save
            /etc/init.d/iptables restart
        else
            echo "port ${shadowsocksport} has been set up."
        fi
    else
        echo "iptables looks like shutdown, please manually set it if necessary."
    fi
}

# Install 
function install_go(){
    # Install shadowsocks-go
    if [ -s /usr/bin/shadowsocks-local ]; then
        echo "shadowsocks-go install success!"
        chmod +x /usr/bin/shadowsocks-local
cat > /etc/systemd/system/shadowsocks.service <<-EOF
[Unit]
Description=Shadowsocks

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/shadowsocks-local -c /etc/shadowsocks/config.json

[Install]
WantedBy=multi-user.target
EOF
        # mv $cur_dir/shadowsocks-go /etc/init.d/shadowsocks
        # chmod +x /etc/init.d/shadowsocks
        # # Add run on system start up
        # if [ "$OS" == 'CentOS' ]; then
        #     chkconfig --add shadowsocks
        #     chkconfig shadowsocks on
        # else
        #     update-rc.d shadowsocks defaults
        # fi
        # Start shadowsocks
        systemctl enable shadowsocks.service
        systemctl start shadowsocks.service
        if [ $? -eq 0 ]; then
            echo "Shadowsocks-go start success!"
        else
            echo "Shadowsocks-go start failure!"
        fi
    else
        echo ""
        echo "shadowsocks-go install failed!"
        exit 1
    fi
    cd $cur_dir
    clear
    echo ""
    echo "Congratulations, shadowsocks-go install completed!"
    echo -e "Your Server addr: \033[41;37m ${shadowsockss} \033[0m"
    echo -e "Your Server Port: \033[41;37m ${shadowsocksport} \033[0m"
    echo -e "Your Password: \033[41;37m ${shadowsockspwd} \033[0m"
    echo -e "Your Local Port: \033[41;37m 1080 \033[0m"
    echo -e "Your Encryption Method: \033[41;37m rc4-md5 \033[0m"
    echo "you can change it by yourself at /etc/shadowsocks/config.json"
    echo "Welcome to visit:http://teddysun.com/392.html"
    echo "Enjoy it!"
    echo ""
    exit 0
}

# Uninstall Shadowsocks-go
function uninstall_shadowsocks_go(){
    printf "Are you sure uninstall shadowsocks-go? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        ps -ef | grep -v grep | grep -v ps | grep -i "shadowsocks" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            systemctl stop shadowsocks.service
        fi
        checkos
        # delete config file
        systemctl disable shadowsocks.service
        rm -rf /etc/shadowsocks
        # delete shadowsocks
        rm -f /etc/systemd/system/shadowsocks.service
        rm -f /usr/bin/shadowsocks-local
        echo "Shadowsocks-go uninstall success!"
    else
        echo "Uninstall cancelled, Nothing to do"
    fi
}

# Install Shadowsocks-go
function install_shadowsocks_go(){
    checkos
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    if [ "$OS" == 'CentOS' ]; then
        if ! centosversion 7; then
            iptables_set
        fi
    fi
    install_go
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks_go
    ;;
uninstall)
    uninstall_shadowsocks_go
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
