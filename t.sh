python -m pip install --upgrade pip
pip install -r requirements.txt
pip install -r /root/shadowsocks-yahaha/requirements.txt
/usr/bin/chattr -i /etc/resolv.conf
wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc
/usr/bin/chattr +i /etc/resolv.conf