---
layout:     post
title:      "docker在线实验平台一"
subtitle:   "docker在线实验平台一"
date:       2018-03-13 8:00:00
author:     "julyerr"
header-img: "img/projects/pwd/pwd.png"
header-mask: 0.5
catalog:    true
tags:
    - projects
    - flask
---

这篇blog主要总结2017年暑假使用go开发的和docker交互的管理后台,其实说起来都是泪啊（开始想从事golang后台开发工程师职位，结果发现招go的公司除了几个大厂之外，其他基本不太招应届毕业生，主要是自己太菜，结果默默向java低头，不过感觉java web还挺不错的哈...）



上篇文章主要分析了基于flask的选课系统业务逻辑，后端的这块相对复杂一点。实现的功能简单来说就是，将以前命令行启动和分配docker container(没有了解docker，请自行学习一下，新的技术多多接触开拓一下自己的视野)的任务交给了由go编写的程序，然后前端的angurjs通过restful 和 go后台交互，提供给用户鼠标、键盘操作的web前台。
可能大家回想，为什么不由angurjs和docker直接交互，对的;但是没有中间这一层的话，就缺少了很多实验平台的高级特性如共享容器的命令行终端。这个项目主要是借鉴了(play-with-docker)[https://github.com/play-with-docker/play-with-docker]的实现（项目非常有特色也是docker大会上一个亮点），仔细看了看实现源码（对go项目开发一个提升，前端angularjs这块分析起来真是费劲，然后前端基本没有怎么修改，主要是后端的go精简了很多功能如计时、session保存，添加了诸如用户从数据库中取出信息等功能（主要为了和选课系统结合使用）。


在分析项目实现之前，先把一些流程理清才能抓住脉络。


从前面的实验平台说起，对于老师而言，每个老师为了专门的课程设置了专门的容器环境（比如上mysql的课程，选择实验平台使用mysql镜像，可以从docker hub上下载，也可以自己构建，实际我们项目中使用了docker harbor作为容器管理平台）;为了更好撰写实验文档，老师点击到实验页面，整个页面的右边就是实验控制界面，可选择使用镜像，然后创建即可;同时考虑到一个实验可能分多次编写，还应该提供保存实验容器的功能，然后下次能够恢复到实验开始的状态（借助docker commit实现，但是一些运行中的服务需要再次启动才行）。
对于学生而言，重定向到的实验界面，左边是文档，右边是已经配置好的实验环境;同样的，考虑学生分多次实验，因此也提供现场保存的功能，但是有数量限制。借助websocket，可以实现终端界面的共享。 

上面只是大体的功能，下面看看具体的实现细节


api.go 是启动参数，整个go projects编译之后只有一个执行文件（非常适合打包和分发）

参数解析

```go
func ParseFlags(){
	flag.StringVar(&Port, "port", "8080", "Listening on the given port")
	flag.BoolVar(&Debug, "debug", false, "Whether to run in debug")
	//数据库链接信息
	flag.StringVar(&DBSchm,"dbschm","root:root@tcp(localhost:3306)/step1","The DB and database to connect")
	//如果没有制定创建的容器，默认使用的
	flag.StringVar(&defaultImage,"image","alpine","default image to launch if not set")
	flag.Parse()
}
```









cd workRoom && git clone https://github.com/julyerr/play-with-docker.git &&
cd play-with-docker 
curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh - && sudo mkdir -p /etc/docker 
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://da3imtjk.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload 
systemctl start docker && systemctl enable docker
for i in {'centos','ubuntu','apline'};do
	docker pull $i
done
modprobe xt_ipvs
docker swarm init --advertise-addr
	net.ipv4.ip_forward=1
	sysctl -p
docker run -d        -e GOOGLE_RECAPTCHA_DISABLED=true         -e MAX_PROCESSES=10000         -e EXPIRY=4h         --name pwd         -p 80:3000         -p 8443:3001  -v /var/run/docker.sock:/var/run/docker.sock -v sessions:/app/pwd/     --restart always    -v `pwd`/www:/app/www   julyerr/pwd:eighth ./play-with-docker --name pwd --cname host1 --save ./pwd/sessions






---
### 参考资料