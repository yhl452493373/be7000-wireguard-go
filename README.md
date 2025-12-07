# 小米路由器 BE7000 Wireguard-go 客户端模式安装说明

## 路由器环境准备
+ 仓库中的[wg-quick](wg-quick)是sh通用脚本，用于调用 wg 和 wireguard-go** 
+ 仓库中的 [wg](wg)、[wireguard-go](wireguard-go)是适用于小米路由器BE7000的，如果你不是这个型号，可能需要根据自己的架构自行编译，方法见后面**
+ 参考 https://www.gaicas.com/xiaomi-be7000.html 开启SSH并`登录到SSH`
+ 创建 /data/wireguard/bin 和 /data/wireguard/conf 目录
  + `mkdir -p /data/wireguard/bin`
  + `mkdir -p /data/wireguard/conf`

## 上传相关文件到小米路由器

需要在ubuntu终端执行，或者第三方终端如 terminus 执行，windows自带的不行

```bash
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wg root@192.168.31.1:/data/wireguard/bin/
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wireguard-go root@192.168.31.1:/data/wireguard/bin/
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wg-quick root@192.168.31.1:/data/wireguard/bin/
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wg0.conf root@192.168.31.1:/data/wireguard/conf/
```

## 启动 wireguard

登录小米路由器，执行
```bash
cd /data/wireguard/bin
chmod a+x *
./wg-quick up wg0
```

## 放行接口转发

这一步不做的话，异地访问小米路由器 IP 没问题，但是无法访问到其下的其他设备

登录小米路由器，执行
```bash
uci set firewall.@defaults[0].forward='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
```

### 使 wireguard 开机自启

登录小米路由，执行下面代码
```conf
uci set firewall.wg0=include
uci set firewall.wg0.type='script'
uci set firewall.wg0.path='/data/wireguard/bin/wg-quick up wg0'
uci set firewall.wg0.enabled='1'
uci commit firewall
/etc/init.d/firewall restart
```
之后会看到wireguard日志，重启后会自动开启wireguard

---
## 自行编译 wg 和 wireguard-go

### 准备 Ubuntu 环境
```bash
sudo apt update
sudo apt install -y \
    build-essential \
    git \
    make \
    gcc \
    g++ \
    golang-go \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    binutils-aarch64-linux-gnu \
    libc6-dev-arm64-cross
```
### 编译 wireguard-go 并上传到小米路由器

```bash
git clone https://git.zx2c4.com/wireguard-go
cd wireguard-go
export GOOS=linux
export GOARCH=arm64
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
make clean && make
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wireguard-go root@192.168.31.1:/data/wireguard/bin/
```

### 编译 wg 并上传到小米路由器

```bash
git clone https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src
make clean
make CC=aarch64-linux-gnu-gcc LDFLAGS="-static"
scp -O -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa wg root@192.168.31.1:/data/wireguard/bin/
```
