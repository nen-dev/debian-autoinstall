#!/bin/bash
#
# This is a script which configure iptables
# You could use it for:
#  - home-pc
#  - server-pc
# DRAFT
#
############################################3
# DEFAULT VALUE
# Do not change this variables
# You can use it to find them in this script
#
IPT="/sbin/iptables"
IPT6="/sbin/ip6tables"
HOSTTYPE=""
TCP_SERVICES=""
UDP_SERVICES=""
REMOTE_TCP_SERVICES=''
REMOTE_UDP_SERVICES=''
SERVICE_TYPE=""
REGEX_NET='([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})'
SSH_PORT=''
TORRENTS=''
VPN_TYPE=''
TORRENTS_LISTEN=''
NETWORKS_VPN=''
NETWORKS_MGMT=''
ADMIN_TCP_SERVICES=''
ADMIN_UDP_SERVICES=''
ADMIN_REMOTE_TCP_SERVICES=''
ADMIN__REMOTE_UDP_SERVICES=''

##############################
# Check iptables permissions
if [ ! -x $IPT ]; then
    echo "You have not permissions to set up iptables";exit 0;
fi
if [[ $# == 0 ]];then
    echo "Try iptables.setup.sh --help for more information"; exit 0;
fi

#################################
# Check script arguments
while [[ $# > 0 ]];do
case $1 in
--help)
 echo " This is script configures iptables
 ! But now only block ipv6 traffic
 
 You should use sudo or run as root for using it

 Usage:
    iptables.setup.sh -h home-pc -p standard -u users
    iptables.setup.sh -h server -p web-server -n 10.0.0.0/24
    
    
 Options:
    -h | --host-type [ home-pc | server ]
                     home-pc - block all input traffic, block output traffic
                     -p options could specify services set, which enable some output traffic
                     -u allow only http/https traffic from specific users
    -p | --ports [ standard | web-server | full | monitoring ]
                    standard - dns, icmp,
                    web-server - allow http/https
                    full - you could specify services in FULL_TCP, FULL_UDP variable
                    monitoring - zabbix, ssh, snmp, icmp
    -u | --users \"user1 user2\"     
                Specify specific users which could use http/https traffic        
    -v | --vpn [cisco-ipsec] 
                specify type of vpn client
                --vnets \"192.168.1.1/32 10.0.0.0/8\"
                Specify the address for remote vpn server or server group
    -n | --nets \"192.168.1.1/32 10.0.0.0/8\"
                Specify managment networks for ssh access
 "
 exit 0
;;

-h|--host-type)
    HOSTTYPE=$2
    if [ $HOSTTYPE == "home-pc" ] || [ $HOSTTYPE == "server" ]; then
        echo "Host type is $HOSTTYPE"         
    else
        echo "You should specify the host-type: home-pc or server"
    fi
    shift
;;
-p|--ports)
    SERVICE_TYPE=$2
    if [ $SERVICE_TYPE == "standard" ] || [ $SERVICE_TYPE == "web-server" ] || [ $SERVICE_TYPE == "full" ] || [ $SERVICE_TYPE == "monitoring" ]; then
        echo "Service type is $SERVICE_TYPE"
    else
        echo "You should specify the ports [ standard | web-server | monitoring | full ]"
    fi
    shift
;;
-u)
    USERS=$2
    echo "USER: $USERS"
    shift
;;
--users)
    USERS=$2
    echo "USERS: $USERS"
    shift
;;
-n)
    NETWORKS_MGMT=$2
    if [[ "$NETWORKS_MGMT" =~ $REGEX_NET ]]; then
        echo "Managment network: $NETWORKS_MGMT"
    else
        echo "You should specify correct network address 
        You use: $NETWORKS_MGMT
        But should: X.X.X.X/X IP/mask
        "
        exit 2
    fi
    shift
;;
--nets)
    NETWORKS_MGMT=$2
    for NET in $NETWORKS_MGMT; do
        if [[ "$NET" =~ $REGEX_NET ]]; then
        echo "Managment network: $NET"
    else
        echo "You should specify correct network address 
        You use: $NET
        But should: X.X.X.X/X IP/mask
        "
        exit 2
    fi
    done        
    shift
;;
-v)
    VPN_TYPE=$2
    if [ $VPN_TYPE == "cisco-ipsec" ]; then
        echo "VPN type of Client: $VPN_TYPE"
    else
        echo "You should specify the vpn client type [cisco-ipsec]"
    fi
    shift
;;
--vpn)
    VPN_TYPE=$2
    if [ $VPN_TYPE == "cisco-ipsec" ]; then
        echo "VPN type of Client: $VPN_TYPE"
    else
        echo "You should specify the vpn client type [cisco-ipsec]"
    fi
    shift
;;
--vnets)
    NETWORKS_VPN=$2
    for NET in $NETWORKS_VPN; do
        if [[ "$NET" =~ $REGEX_NET ]]; then
        echo "Vpn network: $NET"
    else
        echo "You should specify correct network address 
        You use: $NET
        But should: X.X.X.X/X IP/mask
        "
        exit 2
    fi
    done        
    shift
;;
*)
    echo "Try iptables.setup.sh --help for more information "
    exit 0
;;
esac
shift
done

case $HOSTTYPE in
server)
    if [ -z "$NETWORKS_MGMT" ]; then
        echo "You should specify management network"
        exit 2 
    fi
;;
esac

##################################################
# Service Type and services(ports)
case $SERVICE_TYPE in
standard)
##############
TCP_SERVICES=''
UDP_SERVICES=''
# REMOTE SERVICES:
# 80, 443 - web
# 53 - DNS
# 22 - ssh
REMOTE_TCP_SERVICES='80 443 53 22'
REMOTE_UDP_SERVICES='53'
# qbittorrent
TORRENTS_LISTEN='8999'
TORRENTS='52740:56850'
;;
##############
web-server)
SSH_PORT='22'
# ADMIN_TCP_SERVICES
# 10050 - Zabbix Agent
# 10161 req SNMP TLS
ADMIN_TCP_SERVICES='10161 10050'
# ADMIN_UDP_SERVICES
# 161 SNMP
ADMIN_UDP_SERVICES='161'
# ADMIN_REMOTE_TCP_SERVICES
# 10051 - Zabbix Server
# 10162 trap SNMP TLS
ADMIN_REMOTE_TCP_SERVICES='10051 10162'
# ADMIN__REMOTE_UDP_SERVICES
# 162 SNMP Traps
ADMIN__REMOTE_UDP_SERVICES='162'
# TCP_SERVICES
# 80,443 - web
TCP_SERVICES='80 443'
# UDP_SERVICE
UDP_SERVICE=''
# REMOTE_TCP_SERVICES
# 6514 - Secure Syslog
# 3306 - mysql
# 53 - DNS
# 389 - LDAP
# 636 - LDAPS
REMOTE_TCP_SERVICES='80 443 514 53 10051 6514'
# REMOTE_UDP_SERVICES
# 514 - Syslog
REMOTE_UDP_SERVICES='53 514'
;;
#################
monitoring)
SSH_PORT='22'
# ADMIN_TCP_SERVICES
# 80,443 - web
# 10050 - Zabbix Agent
# 10161 req SNMP TLS
ADMIN_TCP_SERVICES='80 443 10161 10050 10051'
# ADMIN_UDP_SERVICES
# 161 SNMP
# 162 SNMP Traps
ADMIN_UDP_SERVICES='161 162'
# ADMIN_REMOTE_TCP_SERVICES
# 10051 - Zabbix Server
# 10162 trap SNMP TLS
ADMIN_REMOTE_TCP_SERVICES='10051 10162'
# ADMIN__REMOTE_UDP_SERVICES
# 162 SNMP Traps
ADMIN__REMOTE_UDP_SERVICES='162'
# TCP_SERVICES
# iperf 5001:5040
# 10051 - Zabbix Server
# 10162 trap SNMP TLS
# 10000 - WEBMIN
TCP_SERVICES='10051 10162 5001:5040'
# UDP_SERVICE
# iperf 5001:5040
# 162 SNMP Traps
UDP_SERVICE='162 5001:5040'
# REMOTE_TCP_SERVICES
# 6514 - Secure Syslog
# 3306 - mysql
# 53 - DNS
# 389 - LDAP
# 636 - LDAPS
# 80, 443 - WEB
REMOTE_TCP_SERVICES='22 23 80 443 53 389 636 6514 10050 3306' 
# REMOTE_UDP_SERVICES
# 514 - Syslog
# 161 - SNMP
REMOTE_UDP_SERVICES='53 514 161'
;;
#################
full)
SSH_PORT='22'
TCP_SERVICES=''
UDP_SERVICES=''
# REMOTE SERVICES:
# 80, 443 - web
# 5222 - JABBER
# 8010 - JABBER FT
# 53 - DNS
# 3306 - mysql
# 389 - LDAP
# 636 - LDAPS
# 8002 - icecast
# 8394 - some radio at work ;)  http://91.121.59.45:8394/stream
# 3389 - RDP
# 8006 - PROXMOX
# 10000 - WEBMIN
# SMB
# 137 - NetBIOS name service 
# 138 - NetBIOS datagram service
# 139 - NetBIOS session service 
# 445 - SMB NetBIOS CIFS
# 9100 - Printers
# 5900:5999 - VNC Proxmox

REMOTE_TCP_SERVICES='22 80 137 138 443 445 5222 8010 53 22 3306 389 636  5900:5999 8002 3389 8394 8006 9100 10000 3128'
# 53 - DNS
# 161 SNMP
# 162 SNMP Traps
# 3389 - RDP
# 137 - NetBIOS name service 
# 138 - NetBIOS datagram service
REMOTE_UDP_SERVICES='53 161 3389 137'
TORRENTS_LISTEN='8999'
TORRENTS='52740:56850'
;;
esac


#################################
#        IPTABLES RULES SET     # 
#################################

# FLUSH IPTABLES
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X


# DROP BY DEFAULT POLICY
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

# ALLOW LOOPBACK
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
# ALLOW NTP
$IPT -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A INPUT  -p udp --sport 123 -m state --state ESTABLISHED     -j ACCEPT

# DNS for ROOT USER

$IPT -A OUTPUT -p udp  --dport 53 -m state --state NEW,ESTABLISHED -m owner --uid-owner root -j ACCEPT
$IPT -A INPUT  -p udp  --sport 53 -m state --state ESTABLISHED     -j ACCEPT
$IPT -A OUTPUT -p tcp  --dport 53 -m state --state NEW,ESTABLISHED -m owner --uid-owner root -j ACCEPT
$IPT -A INPUT  -p tcp  --sport 53 -m state --state ESTABLISHED     -j ACCEPT

# APT 
$IPT -A OUTPUT -p tcp --dport 21  -m state --state NEW,ESTABLISHED -j ACCEPT
$IPT -A INPUT  -p tcp  --sport 21  -m state --state ESTABLISHED     -j ACCEPT
$IPT -A OUTPUT -p tcp  --dport 80 -m state --state NEW,ESTABLISHED -m owner --uid-owner root -j ACCEPT
$IPT -A OUTPUT -p tcp  --dport 443 -m state --state NEW,ESTABLISHED -m owner --uid-owner root -j ACCEPT
$IPT -A INPUT  -p tcp  --sport 80 -m state --state ESTABLISHED     -j ACCEPT
$IPT -A INPUT  -p tcp  --sport 443 -m state --state ESTABLISHED     -j ACCEPT


# ICMP 
$IPT -A INPUT -p ICMP --icmp-type 8 -j LOG --log-prefix "PING: " # ECHO-REQUEST

$IPT -A INPUT -p ICMP --icmp-type 8 -j ACCEPT # ECHO-REQUEST
$IPT -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT # ECHO-REPLY
$IPT -A INPUT -p icmp --icmp-type 3 -j ACCEPT # DESTINATION UNREACHABLE
$IPT -A INPUT -p icmp --icmp-type 11 -j ACCEPT #  TTL EXCEEDED
$IPT -A INPUT -p icmp --icmp-type 12 -j ACCEPT # BAD IP HEADER

$IPT -A OUTPUT -p ICMP --icmp-type 8 -j ACCEPT
$IPT -A INPUT -p ICMP --icmp-type 0 -j ACCEPT
# TRACEROUTE
$IPT -I OUTPUT -p udp --dport 33434:33474 -j ACCEPT

# TRACEROUTE
$IPT -I INPUT -p udp --sport 33434:33524 -j ACCEPT
$IPT -I INPUT -p udp --dport 33434:33474 -j LOG --log-prefix "TRACERT: "
$IPT -I INPUT -p udp --dport 33434:33474 -j ACCEPT

if [ -n "$NETWORKS_MGMT" ]; then
    if [ $HOSTTYPE == "server" ]; then
        for NETWORK_MGMT in $NETWORKS_MGMT; do
            $IPT -A INPUT -p tcp --src ${NETWORK_MGMT} --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'SSH: ' 
            $IPT -A INPUT -p tcp --src ${NETWORK_MGMT} --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
            $IPT -A OUTPUT -p tcp --src ${NETWORK_MGMT} --sport ${SSH_PORT} -m conntrack --ctstate ESTABLISHED -j ACCEPT
            # ADMIN SERVICES
            if [ -n "$ADMIN_TCP_SERVICES" ]; then
                for TCP_SERVICE in $ADMIN_TCP_SERVICES; do
                    $IPT -A OUTPUT -p tcp --sport $TCP_SERVICE -m state --state ESTABLISHED -j ACCEPT
                    $IPT -A INPUT  -p tcp --src ${NETWORK_MGMT} --dport $TCP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
                done
            fi
            if [ -n "$ADMIN_UDP_SERVICES" ]; then
                for UDP_SERVICE in $ADMIN_UDP_SERVICES; do
                    $IPT -A OUTPUT -p tcp --sport $UDP_SERVICE -m state --state ESTABLISHED -j ACCEPT
                    $IPT -A INPUT  -p tcp --src ${NETWORK_MGMT} --dport $UDP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
                done
            fi        
            # REMOTE ADMIN SERVICES
            if [ -n "$ADMIN_REMOTE_TCP_SERVICES" ]; then
                for REMOTE_TCP_SERVICE in $ADMIN_REMOTE_TCP_SERVICES; do
                    $IPT -A OUTPUT -p tcp --dport $REMOTE_TCP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
                    $IPT -A INPUT  -p tcp --src ${NETWORK_MGMT} --sport $REMOTE_TCP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
                done 
            fi
            if [ -n "$ADMIN__REMOTE_UDP_SERVICES" ]; then
                for REMOTE_UDP_SERVICE in $ADMIN__REMOTE_UDP_SERVICES; do
                    $IPT -A INPUT  -p udp --src ${NETWORK_MGMT} --sport $REMOTE_UDP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
                    $IPT -A OUTPUT -p udp  --dport $REMOTE_UDP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT        
                done      
            fi
        done
    else
        for NETWORK_MGMT in $NETWORKS_MGMT; do
            $IPT -A INPUT -p tcp --src ${NETWORK_MGMT} --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'SSH: ' 
            $IPT -A INPUT -p tcp --src ${NETWORK_MGMT} --dport ${SSH_PORT} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
            $IPT -A OUTPUT -p tcp --src ${NETWORK_MGMT} --sport ${SSH_PORT} -m conntrack --ctstate ESTABLISHED -j ACCEPT
        done    
    fi
fi

# REMOTE SERVICES
if [ -n "$REMOTE_TCP_SERVICES" ]; then
    if [ -n "$USERS" ]; then
    for USER in $USERS; do
    for REMOTE_TCP_SERVICE in $REMOTE_TCP_SERVICES; do
        $IPT -A OUTPUT -p tcp --dport $REMOTE_TCP_SERVICE -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER  -j ACCEPT
        $IPT -A INPUT  -p tcp --sport  $REMOTE_TCP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
    done 
    done
    else
    for REMOTE_TCP_SERVICE in $REMOTE_TCP_SERVICES; do
        $IPT -A OUTPUT -p tcp --dport $REMOTE_TCP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A INPUT  -p tcp --sport $REMOTE_TCP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
    done 
    fi
fi
if [ -n "$REMOTE_UDP_SERVICES" ]; then
    if [ -n "$USERS" ]; then
    for USER in $USERS; do
    for REMOTE_UDP_SERVICE in $REMOTE_UDP_SERVICES; do
        $IPT -A INPUT  -p udp --sport $REMOTE_UDP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT -p udp --dport $REMOTE_UDP_SERVICE -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
    done      
    done
    else
    for REMOTE_UDP_SERVICE in $REMOTE_UDP_SERVICES; do
        $IPT -A INPUT  -p udp --sport $REMOTE_UDP_SERVICE --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT -p udp --dport $REMOTE_UDP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT  
    done    
    fi
fi

# SERVICES
if [ -n "$TCP_SERVICES" ]; then
    for TCP_SERVICE in $TCP_SERVICES; do
        $IPT -A OUTPUT -p tcp --sport $TCP_SERVICE -m state --state ESTABLISHED -j ACCEPT
        $IPT -A INPUT  -p tcp --dport $TCP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
    done
fi
if [ -n "$UDP_SERVICES" ]; then
    for UDP_SERVICE in $UDP_SERVICES; do
        $IPT -A OUTPUT -p tcp --sport $UDP_SERVICE -m state --state ESTABLISHED -j ACCEPT
        $IPT -A INPUT  -p tcp --dport $UDP_SERVICE -m state --state NEW,ESTABLISHED -j ACCEPT
    done
fi



if [ -n "$TORRENTS" ]; then
    if [ -n "$USERS" ]; then
    #TORRENTS LISTEN
    # TORRENTS
        $IPT -A INPUT  -p tcp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'TORRENTS: '
        $IPT -A INPUT  -p tcp --dport ${TORRENTS_LISTEN} -m state --state ESTABLISHED -j ACCEPT
        $IPT -A INPUT  -p udp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'TORRENTS: '
        $IPT -A INPUT  -p udp --dport ${TORRENTS_LISTEN} -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT -p tcp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
        $IPT -A OUTPUT -p udp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
    #TORRENTS CONNECTION
        $IPT -A INPUT -p tcp -m multiport --dports ${TORRENTS}  -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT  -p tcp -m multiport --sports ${TORRENTS} -m state --state ESTABLISHED -m owner --uid-owner $USER  -j ACCEPT
        $IPT -A INPUT -p udp -m multiport --dports ${TORRENTS}  -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT  -p udp -m multiport --sports ${TORRENTS} -m state --state ESTABLISHED -m owner --uid-owner $USER -j ACCEPT 
    else
    #TORRENTS LISTEN
    # TORRENTS
        $IPT -A INPUT  -p tcp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'TORRENTS: '   
        $IPT -A INPUT  -p tcp --dport ${TORRENTS_LISTEN} -m state --state ESTABLISHED -j ACCEPT
        $IPT -A INPUT  -p udp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j LOG -m limit --limit 2/hour --log-level 4 --log-prefix 'TORRENTS: '      
        $IPT -A INPUT  -p udp --dport ${TORRENTS_LISTEN} -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT -p tcp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT -p udp --sport ${TORRENTS_LISTEN} -m state --state NEW,ESTABLISHED -j ACCEPT
    #TORRENTS CONNECTION
        $IPT -A INPUT -p tcp -m multiport --dports ${TORRENTS}  D -j ACCEPT
        $IPT -A OUTPUT  -p tcp -m multiport --sports ${TORRENTS} -m state --state ESTABLISHED -j ACCEPT
        $IPT -A INPUT -p udp -m multiport --dports ${TORRENTS}  -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT  -p udp -m multiport --sports ${TORRENTS} -m state --state ESTABLISHED -j ACCEPT 
    fi
fi



# Cisco IPSecVPN
if [ -n "$VPN_TYPE" ]; then
    if [ -n "$NETWORKS_VPN" ]; then
    if [ -n "$USERS" ]; then
    for USER in $USERS; do
        for NETWORK_VPN in $NETWORKS_VPN; do
            $IPT -A OUTPUT  -p udp -d ${NETWORK_VPN} --dport 500 -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
            $IPT -A INPUT -p udp -d ${NETWORK_VPN} --sport 500 -m state --state ESTABLISHED -j ACCEPT
            $IPT -A OUTPUT  -p udp -d ${NETWORK_VPN} --dport 4500 -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
            $IPT -A INPUT -p udp -d ${NETWORK_VPN} --sport 4500 -m state --state ESTABLISHED -j ACCEPT
        done
    done    
    else
    for NETWORK_VPN in $NETWORKS_VPN; do
        $IPT -A OUTPUT  -p udp -d ${NETWORK_VPN} --dport 500 -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A INPUT -p udp -d ${NETWORK_VPN} --sport 500 -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT  -p udp -d ${NETWORK_VPN} --dport 4500 -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A INPUT -p udp -d ${NETWORK_VPN} --sport 4500 -m state --state ESTABLISHED -j ACCEPT
    done
    fi
    else
    if [ -n "$USERS" ]; then
    for USER in $USERS; do
        for NETWORK_VPN in $NETWORKS_VPN; do
            $IPT -A OUTPUT  -p udp --dport 500 -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
            $IPT -A INPUT -p udp  --sport 500 -m state --state ESTABLISHED -j ACCEPT
            $IPT -A OUTPUT  -p udp  --dport 4500 -m state --state NEW,ESTABLISHED -m owner --uid-owner $USER -j ACCEPT
            $IPT -A INPUT -p udp --sport 4500 -m state --state ESTABLISHED -j ACCEPT
        done
    done    
    else
    for NETWORK_VPN in $NETWORKS_VPN; do
        $IPT -A OUTPUT  -p udp --dport 500 -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A INPUT -p udp  --sport 500 -m state --state ESTABLISHED -j ACCEPT
        $IPT -A OUTPUT  -p udp  --dport 4500 -m state --state NEW,ESTABLISHED -j ACCEPT
        $IPT -A INPUT -p udp --sport 4500 -m state --state ESTABLISHED -j ACCEPT
    done
    fi    
fi
fi


$IPT -L -v

/sbin/iptables-save > /etc/iptables.up.rules
echo '#!/bin/sh
/sbin/iptables-restore < /etc/iptables.up.rules
exit 0' > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables


# start with a clean slate
$IPT6 -F
$IPT6 -X

$IPT6 -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT6 -A INPUT -m conntrack --ctstate INVALID -j DROP
# allow icmpv6
$IPT6 -I INPUT -p ipv6-icmp -j ACCEPT
$IPT6 -I OUTPUT -p ipv6-icmp -j ACCEPT


# allow loopback
$IPT6 -A INPUT -i lo -j ACCEPT
$IPT6 -A OUTPUT -o lo -j ACCEPT

# drop packets with a type 0 routing header
$IPT6 -A INPUT -m rt --rt-type 0 -j DROP
$IPT6 -A OUTPUT -m rt --rt-type 0 -j DROP

# default policy...
$IPT6 -P INPUT DROP
$IPT6 -P FORWARD DROP
$IPT6 -P OUTPUT DROP


/sbin/ip6tables-save > /etc/ip6tables.up.rules
echo '#!/bin/sh
/sbin/ip6tables-restore < /etc/ip6tables.up.rules
exit 0' > /etc/network/if-pre-up.d/iptables6
chmod +x /etc/network/if-pre-up.d/iptables6


if [ $HOSTTYPE == "home-pc" ]; then
    /etc/init.d/networking restart
    /etc/init.d/network-manager restart     
else
    /etc/init.d/networking restart
fi



echo -e "
Set up outgoing(Min/Max) ports 
$TORRENTS
Set up port for incoming connection 
$TORRENTS_LISTEN
"
