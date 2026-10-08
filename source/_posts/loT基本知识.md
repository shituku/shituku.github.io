---
title: loT基本知识
date: 2025-04-19 15:46:27
tags:
---

## 前置基础
- mips linux：使用mips指令架构的linux系统，广泛应用于嵌入式系统，路由器常用mips32和arm架构。
- risc架构：精简指令集，包括mips、arm、risc-v。
- busybox：精简终端，路由器shell多为裁剪版busybox，shell命令本质为busybox符号链接。

## 路由的漏洞利用
### 利用方式
- 密码破解：默认密码、弱口令、字典爆破、侧信道（如服务器响应时间、返回数据包特征，爆破密码或PIN码）。
- web漏洞：访问web管理服务与web界面交互，进行渗透（如SQL注入、RCE、CSRF、XSS）。
- 后门：如缓冲区溢出、危险函数利用。

## 密码破解
- 默认密码、弱口令、字典爆破。
- 侧信道攻击：利用响应时间、数据包特征爆破密码或PIN码。

## web漏洞
- SQL注入、RCE、CSRF、XSS等。
- 通过web管理界面进行渗透。

## 后门
- 可绕过安全控制获取访问权的漏洞。
- 典型如32764端口后门等。

## 缓冲区溢出
- 危险函数：strcpy、sprintf、snprintf、strchr、gets、fgetc。
- sprintf：格式化字符串中有%s且未判断长度，可能栈溢出。
- snprintf：返回值为输入长度，size为unsigned类型，需注意负数转大正数的溢出。
- strchr：复制长度由?前字符串长度决定，需注意越界。
- fgetc：循环读取字符，注意循环边界。

代码示例：
```
// 使用snprintf安全格式化字符串，left为已写入长度
// Use snprintf to safely format string, left is the length already written
int left = snprintf(stack, sizeof(stack), "%s", buf_from_http1);
// 继续在stack后面追加内容，防止溢出
// Continue appending to stack, prevent overflow
snprintf(stack+left, sizeof(stack)-left, "%s", buf_from_http2);

// 查找url中的'?'字符，获取查询参数位置
// Find '?' in url to get query parameter position
char *query = strchr(url, '?');
// 将url中'?'前的内容复制到stack，长度为query - url - 1
// Copy content before '?' in url to stack, length is query - url - 1
strncpy(stack, url, query - url - 1);
```

## 逻辑漏洞
- 多功能点组合利用，挖掘攻击链。

## 注入类
- 敏感函数：system、popen、exec、execve。
- 过滤绕过：如$IFS绕过空格，xxd、base64编码。

## 工具
- [mipsAudit](https://github.com/giantbranch/mipsAudit)：mips静态汇编审计辅助脚本，回溯敏感函数审计危险函数。
- 在IDA->file->Script FIle中加载，控制台输出信息并高亮显示。

## mips linux
- mips linux广泛用于嵌入式系统，路由器常用mips32和arm。
- mips通过a0-a3传递前4个参数，其余通过栈传递。
- 叶子函数与非叶子函数的栈布局和调用方式不同。

## busybox
- busybox为精简终端，路由器shell多为其裁剪版。
- 常用命令：
```bash
$ busybox --help        # 查看支持命令 / Show supported commands
$ uname -r              # 查看内核版本 / Show kernel version
$ ls -al                # 查看详细文件列表 / List files in detail
$ rm -rf /tmp           # 强制删除目录 / Force delete directory
$ cp -R /tmp ./now      # 复制目录 / Copy directory
$ du -sk fireware.bin   # 查看文件大小 / Show file size
$ ps -ef                # 查看进程 / Show processes
$ kill -9 pid           # 强制终止进程 / Force kill process
$ killall -9 xxx        # 强制终止进程名 / Force kill by process name
$ ifconfig -a           # 查看所有网卡信息 / Show all network interfaces
```

## HTTP协议
- CRLF：回车换行，C语言为\r\n，十六进制0A0D。
- URI：统一资源标识符，包括协议、主机名、端口、路径、查询字符串、片段标识符。

## 文件系统
- 路径作用：
  - /bin /sbin /usr/bin /usr/sbin：存放应用程序
  - /lib /usr/lib：存放动态库
  - /etc：存放配置文件

## 固件修复
- 拿到固件后需模拟环境，缺少硬件易导致仿真失败。
- 修复流程：定位异常函数，编写同功能函数并封装为动态库，使用LD_PRELOAD劫持。

## 路由器漏洞原理与利用
### 路由器web漏洞
- xss、csrf、基础认证漏洞（如http://admin:admin@192.168.0.1形式免输用户名密码）。
- 基础认证漏洞可与xss、csrf组合，形成攻击链。

### 路由器后门漏洞
- 可绕过安全控制的漏洞。
- 典型如32764端口后门。

### 路由器溢出漏洞
- mips32函数调用与x86不同，参数传递和栈布局需注意。
- 非叶子函数可正常溢出利用，叶子函数需溢出大量数据覆盖父函数返回地址。

## 软件层分析
### 固件获取
- 路由器固件包含操作系统内核和文件系统。
- 获取途径：厂商网站、web管理界面、硬件提取、云市场。

### 文件系统
- 路由器文件系统用于存储操作系统、配置文件、日志等。
- 常见压缩格式：Squashfs（GZIP, LZMA, LZO, XZ）。
- 提取方法：strings、hexdump、dd、file等命令结合使用。
- 自动提取工具：binwalk。

代码示例：
```bash
$ strings firmware.bin | grep `python -c 'print "\x28\xcd\x3d\x45"'`  # 查找特征字符串 / Find signature string
$ dd if=firmware.bin bs=1 count=1024 skip=256 of=out.squashfs             # 提取文件系统 / Extract filesystem
$ binwalk -Me x.bin --run-as=root                                         # 自动提取 / Auto extract
```

## 硬件层分析
- 通过路由器硬件接口获取固件，如JTAG、Flash芯片编程器、芯片夹等。
- 路由器flash为常用内存类型，断电后仍保存数据。
- bootloader（如u-boot）负责设备启动和内核加载。
- kernel为操作系统内核，root filesystem为根文件系统。
- nvram保存配置文件，启动时读取。

---

