# docker-xray-web

通过 Docker-compose 简易部署 [Xray-core](https://github.com/XTLS/Xray-core) 和 Web 服务（**以 Nginx + PostgreSQL + Typecho 博客程序为例**）。

Docker-compose for Xray-core and a web service (Nginx + PostgreSQL + Typecho for example).

## 概述

本项目参考 [小小白白话文 :: Project X (xtls.github.io)](https://xtls.github.io/documents/level-0/) ，通过 Docker-compose 在 Xray 安装的同时部署了 Web 服务，方便建立博客 + 搭建梯子。

原理：Nginx 监听宿主机 80 端口，将流量重定向至 443 端口。而 Xray 监听宿主机 443 端口，识别出 Vless 协议的流量后按照 Xray 设置的规则处理，非 Vless 流量全部转发至 Nginx 容器的 8080 端口（即网站）。

[回落 (fallbacks) 功能简析 :: Project X (xtls.github.io)](https://xtls.github.io/documents/level-1/fallbacks-lv1/)

### 文件结构与说明

* `./xray` 保存 Xray 的配置文件和日志。 
* `./cert` 保存 XRay 所需证书；
* `./nginx` 保存 Nginx 的配置文件、日志和网页内容；
* `./dbdata` 保存 `pgsql` 的数据库配置与文件；（容器初次运行后自动生成）
* `./docker-compose.yml` 控制容器挂载卷、环境变量等；

### 容器组成

* `php-fpm-pgsql` : 提供 PHP 支持;
* `nginx` : 作为网页服务器;
* `postgres` : 数据库;
* `xray` : xray-core 程序；

## 关于镜像

### Xray

感谢来自 [teddysun/xray](https://hub.docker.com/r/teddysun/xray) 的镜像。

### PHP-FPM

* 文档：https://github.com/docker-library/docs/blob/master/php/README.md
* 为了连接 PgSQL 数据库，在官方镜像基础上使用 [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) 添加了 `pgsql` 拓展。

### Nginx

直接使用了原版镜像。

### PostgresSQL

* 文档：https://hub.docker.com/_/postgres

* ”Environment Variables“ 一节中详细说明了容器运行所需提供的环境变量。

  本项目用到了以下环境变量:

  * `POSTGRES_PASSWORD` 数据库 `superuser` 密码； （必需）
  * `POSTGRES_USER` 指定 `superuser` 用户名；（可选，默认值为 `postgres`）
  * `POSTGRES_DB` 指定数据库名称；（可选）

## 部署指南

**本部分以部署 Typecho 博客程序为例。**

0. 宿主机必须安装 docker, docker-compose，您必须拥有正确解析的域名和相应的证书; 

1. 解压压缩包，切换到释放出的 `docker-xray-web` 目录下，共有 3 处配置文件需要用户自行修改：

   * `./docker-compose.yml` : 
   * `db` 一节中的数据库用户名、数据库用户密码、数据库名都可以由用户自定义；
     * 每一节都有环境变量 `TZ` ，可供设置容器时区；
   * `./nginx/conf.d` : 需要将文件中所有 `yourdomain.com` 替换为用户自己的域名；
   * `./xray/config/config.json` : 需要自行填写 UUID 和邮箱。

2. 将域名对应的证书放入 `./cert`，fullchain 文件保存为 `xray.crt`，key 文件保存为 `xray.key`；

3. 在 `docker-xray-web` 下执行

   ```bash
   docker-compose up
   ```

   正常情况下，所有容器都应能正常运行；

4. 使用 `Ctrl-C` 停止所有容器，然后执行：

   ```bash
   sudo chmod -R 777 ./nginx
   ```

   更改权限以便稍后 `Typecho` 存取文件；

5. 然后执行：

   ```bash
   docker-compose start
   ```

   重启容器，启动成功后打开浏览器访问预先设置的域名，即可安装 `Typecho` 。

6. 选择任意支持 Xray 的客户端，根据 `./xray/config/config.json` 的内容生成客户端配置文件即可。

## 注意事项

* `php-fpm-pgsql` 镜像已经上传 Docker Hub,  `dockerfile` 见 [docker-typecho/dockerfile](https://github.com/Nativu5/docker-typecho/blob/master/php-fpm-pgsql/dockerfile), 读者可以此自行构建；

* 由于 Xtls 需要证书方可使用，故请先获取证书再部署，推荐使用 [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh) 自动维护证书。

* 本项目内置的 `default.conf` 已经配置为支持 Typecho 伪静态，但您可能需要在 Typecho 安装后，到网站后台中启用相关设置。

* Typecho 安装后可能需要在程序自动生成的 `./nginx/www/typecho/config.inc.php` 中加入一行：

  ```php
  define('__TYPECHO_SECURE__',true);
  ```

  以启用全站 HTTPS 加密。

* ~~目前 Xray 不会判断访问的域名，即不能实现用户访问 yourdomain.com 和 sub.yourdomain.com 时进入两个不同的站点。~~ 貌似有办法解决 SNI 分流，但有些麻烦：[integrated-examples/v2ray](https://github.com/lxhao61/integrated-examples/tree/master/v2ray(other%20configuration))

* 默认的 Xray 配置不能通过 CDN，但您可以自定义 Xray 配置文件来实现这一功能。

