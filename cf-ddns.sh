#!/bin/bash

###############  授权信息（需修改成你自己的） ################ 
# CloudFlare 注册邮箱
auth_email="472245834@qq.com"
# CloudFlare Global API Key，下一节会说到
auth_key="8bf8eaff1c8d04b1a8b412f4b52e0b6726c40"
# 做 DDNS 的根域名
zone_name="yahaha.pro"
# 做 DDNS 的域名，创建成功后就是通过该域名访问内网资源
record_name="aaa.yahaha.pro"

######################  修改配置信息 ####################### 
# 域名类型，IPv4 为 A，IPv6 则是 AAAA
record_type="A"

# IPv6 检测服务
#ip=$(curl -s http://ipv6.ip.sb)
# IPv4 检测服务
ip="$(curl -s http://ipv4.ip.sb)"

# 变动前的公网 IP 保存位置
ip_file="/root/ddns/ip.txt"
# 域名识别信息保存位置
id_file="/root/ddns/cloudflare.ids"
# 监测日志保存位置
log_file="/root/ddns/cloudflare.log"

######################  检测IP获取点状态 ######################## 
get_node_url() {
    nodes=(http://ipinfo.io/ip http://icanhazip.com http://ip.qaros.com http://ns1.dnspod.net:6666 http://icanhazip.com http://ifconfig.me);
    if [ ! -f /bin/curl ];then
        if [ -f /usr/local/curl/bin/curl ];then
            ln -sf /usr/local/curl/bin/curl /bin/curl
        else
            yum install curl -y
        fi
    fi
}

######################  监测日志格式 ######################## 
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}
log "Check Initiated"


######################  判断 IP 是否变化 #################### 

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ "$ip" == "$old_ip" ]; then
        echo "IP has not changed."
        exit 0
    fi
fi

######################  获取域名及授权 ###################### 
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=$record_type" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

######################  更新 DNS 记录 ###################### 
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

#########################  更新反馈 ######################### 
if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
fi