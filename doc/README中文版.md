# httptables (just like Linux's iptables)
httptables是一个基于OpenResty，面向web应用的轻量级（Lightweight）软防火墙，可以配合第三方系统（用户行为分析系统）针对符合特定条件的HTTP请求做不同的处理。


设计细节请点击[OUTLINE.md](OUTLINE中文版.md)。


## 部署架构图

* 绿色: 已实现
* 黄色: 未实现

![image](httptables-infrastructure.png)


## 世界观
httptables的世界里，每个客户端有三种独立身份，并且每种身份都是唯一标识

* `Origin` 来源IP地址
* `User`   用户ID
* `Device` 设备ID

##  功能列表
本软件支持以下功能点

* 熔断(circuit breakers)
  * **Reject** 阻断用户访问，返回自定义内容响应体
* 减速带(speed bump)
  * **Defer** 放慢用户的请求速度

## 安装
安装请点击[INSTALL.md](doc/INSTALL.md)。

# Copyleft
感谢以下项开源目

* OpenResty

  [OpenResty](https://openresty.org/en/) ™ 是一个基于 Nginx 与 Lua 的高性能 Web 平台。

* Kong

  [Kong](http://www.getkong.org/) 是在客户端和（微）服务间转发API通信的API网关，通过插件扩展功能。

