#/bin/sh

# random password
pass=$(openssl rand -base64 12)
# pass="your pass word"

# random port in 1900 - 1999
port=$(shuf -i 1900-1999 -n 1)
# port=1999

# default config file path
config=/etc/shadowsocks/ss-server.json

# encrypt method
# more : https://shadowsocks.org/en/spec/Stream-Ciphers.html
method="aes-256-cfb"

# check user root
if [ "$(id -u)" != "0" ]; then
   echo "this script must be run as root" 1>&2
   exit 1
fi

# install shadowsocks
if ! [ -x "$(command -v ssserver)" ]; then
  echo 'notice: shadowsocks is not installed.' 1>&2
  apt install -y shadowsocks 
fi

# get password
if [ -z "$1" ]; then
	echo "notice: use random pass"
else
	pass=$1
fi

# get port
if [ -z "$2" ]; then
	echo "notice: use random port"
else
	port=$2
fi

# add config file for shadowsocks server
echo "
{
    \"server\":\"0.0.0.0\",
    \"server_port\":$port,
    \"local_address\": \"127.0.0.1\",
    \"local_port\":1080,
    \"password\":\"$pass\",
    \"timeout\":300,
    \"method\":\"$method\",
    \"fast_open\": false
}" > $config

# add systemd service

echo "
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=3
ExecStart=/usr/bin/ssserver -d start -c $config

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/ssserver.service

chmod 644 /etc/systemd/system/ssserver.service

systemctl daemon-reload

systemctl enable ssserver
systemctl restart ssserver
systemctl status ssserver

# get public ip address
server=$(curl -s "https://api.ipify.org")

echo "========================================"
echo " Address    : $server:$port"
echo " Encryption : $method"
echo " Password   : $pass"
echo "========================================"

