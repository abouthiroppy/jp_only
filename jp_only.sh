#!/bin/sh

IPLIST=cidr.txt

# 初期化をする
iptables -F                     # Flush
iptables -X                     # Reset
iptables -P INPUT DROP         # 受信はすべて破棄
iptables -P OUTPUT ACCEPT       # 送信はすべて許可
iptables -P FORWARD DROP        # 通過はすべて破棄

# サーバーから接続を開始した場合の応答を許可する。
iptables -A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -s 127.0.0.1 -j ACCEPT

if [ -z "$1" ]; then
  date=`date -d '1 day ago' +%Y%m%d`
else
  date="$1"
fi

if [ -e $IPLIST ]; then
    mv $IPLIST "${IPLIST}_${date}"
fi

# 最新のIPリストを取得する
wget http://nami.jp/ipv4bycc/$IPLIST.gz
gunzip -d $IPLIST.gz

# ダウンロードしてきたIPリストで日本のIPだけを許可するようにする
 sed -n 's/^JP\t//p' $IPLIST | while read ipaddress; do
     iptables -A INPUT -s $ipaddress -j ACCEPT
 done

# 25 open
#iptables -A INPUT -p tcp --dport 25 -j ACCEPT
# 8008 jenkins
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8008 -j ACCEPT
# iptables -A INPUT -p tcp --dport 8009 -j ACCEPT

# 587
iptables -m state --state NEW -m tcp -p tcp --dport 10022 -j ACCEPT

# 16574
iptables  -A INPUT --state NEW -m tcp -p tcp --dport 16574 -j ACCEPT

# iptablesによってDROPされたアクセスのログを取る
iptables -A INPUT -m limit --limit 1/s -j LOG --log-prefix '[IPTABLES INPUT DROP] : '
iptables -P INPUT DROP          # 受信はすべて破棄

iptables -t nat -N DOCKER
iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL ! --dst 127.0.0.0/8 -j DOCKER

/etc/init.d/iptables save

# restart
# /etc/init.d/iptables restart
