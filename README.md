# Ineundo

Ineundo 是 拉丁语的 Proxy。

## business

![输入图片说明](https://images.gitee.com/uploads/images/2021/0129/114957_6dabf050_4934895.png "sequence_diagram.png")

如果yum和npm速度过慢，需要更换国内源，推荐yum 使用阿里，npm使用国内源！  
yum一键换源: `wget -qO- https://raw.githubusercontent.com/oooldking/script/master/superupdate.sh | bash`

**安装前最好安装一遍宝塔环境，下面会进行的很快 不会出现其他兼容问题**

## install openresty

### install

```
# add the yum repo
wget https://openresty.org/package/centos/openresty.repo
sudo mv openresty.repo /etc/yum.repos.d/
# update the yum index
sudo yum check-update

# install openresty
sudo yum install -y openresty openresty-resty openresty-opm
systemctl enable openresty.service
systemctl start openresty.service
# 如果是在docker中无法使用ststemctl命令，可以使用 /usr/local/openresty/nginx/sbin/nginx 启动nginx和lua

# install package
opm get p0pr0ck5/lua-resty-cookie
opm get ledgetech/lua-resty-http

# install dnf
yum install dnf

# install node
dnf module enable -y nodejs:14
dnf install -y nodejs

# 如果此方法无法安装nodejs可使用yum方法进行安装

# install redis
yum install -y redis
systemctl enable redis
systemctl start redis

# check redis version >=5.0
redis-cli --version

# update redis
sudo yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
sudo yum --enablerepo=remi install redis -y
sudo systemctl restart redis
systemctl enable redis
systemctl start redis

# check redis config
redis-cli info | grep config 
出现 config_file:/etc/redis.conf 表示ok，我们来编辑这个配置文件
vi /etc/redis.conf

# redis.conf
replicaof domain.axa2.com 6379
replica-read-only no
systemctl restart redis

**注意redis已设置限制外网ip访问,需要到华为云重新添加新ip到ip组列表**

```

### clone

```
# create user
useradd peko
passwd peko
su peko

# clone project
mkdir ~/Projects
cd ~/Projects
git clone https://gitee.com/shenyang-chuangcai/tiktok-proxy
cd tiktok-proxy

# replace npm source
npm config set registry http://mirrors.cloud.tencent.com/npm/

# Installation dependencies
npm i --no-save
vi app.js
vi configs/common.conf

# (Optional) Install keepalive script
npm install pm2 -g
pm2 start app.js --name ineundo
# update this
npm install pm2@latest -g
# 注意: 如果监听错误很大可能是node版本太低,请升级至v14.15版本以上

# config openresty
exit
cd /usr/local/openresty/nginx/conf/
ln -s /home/peko/Projects/tiktok-proxy/configs/ .
# ln -s /home/peko/Projects/tiktok-proxy/configs/ .
vi nginx.conf

# restart all service
systemctl restart openresty.service

# open port
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --permanent --add-port=8082/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# config redis
# 同步的时候 master 大概率不好使，可以先重启测试服务器的redis
vi /etc/redis.conf
systemctl restart redis
```

```
# app.js
const isMaster = false;
const ip = 'xxx.xxx.xxx.xxx';
需要注意的是发送到飞瓜端的请求头信息也是在这里传输的
```

```
# configs/common.conf
set $ip 'xxx.xxx.xxx.xxx';
```

```
# nginx.conf
user  root;
error_log  logs/peko.log debug;
access_log  logs/access.log  main;
#gzip  on;

lua_package_path '/usr/local/openresty/site/lualib/resty/?.lua;;';
include configs/douyin21.conf;
include configs/kuaishou21.conf;

```

```
# redis.conf
replicaof domain.axa2.com 6379
replica-read-only no
```

# 备注
### 变更服务器IP和域名
```
su peko
cd ~/Projects/tiktok-proxy/configs/
vi douyin1.conf
# 变更里面的域名即可
# 如需增加其他域名需要更新nginx 配置文件
```

```
关于nginx配置示例在 ./nginx.conf 
```

# analysis.sh
```
#cat access.log
awk '{print $1 $2}' /usr/local/openresty/nginx/logs/access.log | sort | uniq -c | sort -k 1 -n -r | less
```

# Docker部署

#### 镜像地址

`docker pull registry.cn-beijing.aliyuncs.com/ripper/feigua`  

此docker自带宝塔环境，拉取可能比较大

#### 启动

##### 启动容器

```shell
docker run -dit --restart=always --name feigua -p 5888:8888 -p 588:888 -p 51:21 -p 5306:3306 -p 5379:6379 -p 15590-15600:15590-15600  --privileged=true [IMAGE ID]
```

##### 进入容器

```shell
docker exec -it [CONTAINER ID] bash
```

##### 查看面板信息

```
面板地址: http://127.0.0.1:5888
username: gfaufny3
password: 1x1IFxTD7U9E
```

登录到宝塔面板后，进入`软件商店` 将 `已安装`的所有软件手动启动下

##### 启动lua相关的nginx服务

```
/usr/local/openresty/nginx/sbin/nginx
```

#### 验证

##### nginx是否启动

访问地址：`http://127.0.0.1:15591/`  

lua脚本是否工作：`http://127.0.0.1:15590/` （跳转到其他地址表示正常）  

### 管理后台登陆

登录地址：`http://127.0.0.1:15592/`  

账号：`admin`  

密码： `admin` 



#### 用户前端登陆地址

`http://127.0.0.1:15592/admin/userlogin/userlogin.shtml`  

测试账号：18888888888  

测试密码：123456  

**ps: 注意下时间，如果登陆不上可能是卡密到期了  后台自己重新添加下卡密即可**



