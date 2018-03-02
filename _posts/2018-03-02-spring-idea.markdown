---
layout:     post
title:      "spring系列 开发环境配置"
subtitle:   "spring系列 开发环境配置"
date:       2018-03-02 6:00:00
author:     "julyerr"
header-img: "img/web/spring/tools/idea.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - web
    - spring
    - tools
---

>当下比较流行的java开发IDE当属idea,相比于eclipse有太多的特性。当然体验好的产品自然需要收费，至于如何...请各位大侠自行google。

本文就idea中进行spring开发环境做简单总结，以前本地笔记过一段时间就找不到了:-(


#### maven项目建立
为了方便打包和分发，现在java项目基本都使用maven或者gradle（还没有接触，据说管理配置方面更简洁）进行管理。<br>
**IntelliJ IDEA 创建Maven项目速度慢**<br>
从idea界面选择mavenarchetype的时候，其实是执行mvnarchetype:generate命令，需要指定一个archetype-catalog.xml文件。其可选值为remote（指向Maven中央仓库的Catalog），internal（maven-archetype-plugin内置的） ，local（本地的，位置为~/.m2/archetype-catalog.xml）。默认是从remote进行下载，国内网速问题，自然出现卡顿的现象。<br>
**解决方法**<br>
![](/img/web/spring/tools/archetype.png)

在已经打开项目的控制面板新建工程，速度还会更快，因为所需的archetype-catalog.xml能够快速导入。<br>

**maven中央仓库下载包比较慢**<br>
类似，使用国内的镜像包就可，下面配置使用阿里云。修改\${maven.home}/conf或者\${user.home}/.m2文件夹下的settings.xml
```xml
<mirror>
     <id>alimaven</id>
     <mirrorOf>central</mirrorOf>
     <name>aliyun maven</name>
     <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
</mirror>
```

---
### 参考资料
- [maven国内镜像（maven下载慢的解决方法）](http://www.cnblogs.com/xiongxx/p/6057558.html)
- [IntelliJ IDEA 创建Maven项目速度慢的2种解决方法](https://www.oudahe.com/p/42653/)