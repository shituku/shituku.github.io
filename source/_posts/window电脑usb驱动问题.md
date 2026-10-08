---
title: window电脑usb驱动问题
date: 2025-04-26 21:29:59
tags:
- windows
---


如何你发现你的手机连接不到你的windows电脑，但是你的电脑连接其他手机没问题，而且你手机连接其他电脑没问题，这时候不用怀疑就是连接协议出现了问题！

问题实例
```查看日志
已启动设备 USB\VID_339B&PID_107D\ANYXVB4119005102。

驱动程序名称: oem79.inf
类 GUID: {ecfb0cfd-74c4-4f52-bbf7-343461cd72ac}
服务: libusbK
低层筛选程序: 
高层筛选程序: 
```

连接电脑提示的是Service: libusbK 这条信息表明，你的电脑当前并没有将你的手机识别为标准的 MTP (Media Transfer Protocol) 设备，而是使用了一个名为 libusbK 的通用 USB 驱动程序库来与它通信。

-很好，只是为什么呢？
导致这个原因很常见但是我之前还一直没有注意到，打电话给荣耀的工程师也是没有解决（当然不是特意去问的，主要还是因为Magic OS8的重启Bug，吐槽下荣耀的的售后不咋地）之前还一直以为是驱动的问题
<div style="width: 40%; margin: 10px">
{% asset_img usb驱动问题.jpg  '酷安上提问' %}
{% asset_img 投屏.png  '投屏' %}

</div>

-解决办法就是手动安装驱动程序，核心就是把libusbK给替换掉，化成正确的MTP驱动

-Scrcpy
顺便提下scrcpy（https://github.com/Genymobile/scrcpy?tab=readme-ov-file）
一个非常好用的投屏工具

可以通过USB或者无线局域网让电脑连接到手机

