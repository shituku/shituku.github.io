---
title: Macmini+iPad无感随航进阶使用教程(终极版)
date: 2025-12-22 02:48:31
tags:
- 教程
- Macmini
- 随航
---

### 随航 iPad：Mac mini + iPad 移动工作流

*   **设备**：Mac mini + iPad
*   **实现目标**：将 iPad 打造为 Mac mini 的随身屏幕。相比 Parsec，苹果官方随航（Sidecar）支持 Apple Pencil，且基于 VideoToolbox 底层架构，分辨率和延迟表现更好。
*   **关键词**：苹果设备联动、iPad无感随航、Mac mini便携性提升、副屏

---

#### 详细实现步骤

**1. 自动登陆系统**
用于开机自动进入 Mac，无需手动登录账号。
> **操作**：设置 - 用户与群组 - 添加群组 - 设置自动以此身份登陆

**2. 开启远程登录 (SSH)**
用于 SSH 连接，让 iPad 通过快捷指令唤起 Mac。
> **操作**：设置 - 通用 - 共享 - 远程登录 (开启) - 选择刚刚添加的群组
> *(注意：确保密码相同且正确，别错选 Administrator)*

**3. 关闭锁屏和休眠**
防止因锁屏导致无法用 iPad 直接唤起随航（有屏幕的同学请自行把握）。
> **操作**：设置 - 锁定屏幕 - 将可设置的 3 项改为“永不”

**4. 安装 BetterDisplay (关键)**
极为重要，必须虚拟出屏幕才能启用随航。
*   **下载**：[GitHub - BetterDisplay](https://github.com/waydabber/BetterDisplay/releases/tag/v4.1.1)
*   **操作**：打开 dmg 将图标拖入 Applications 文件夹。打开软件，新建一个虚拟屏幕（比例任意，只用于启用随航）。

**5. 完善 BetterDisplay 设置**
> **操作**：设置 - 显示器 - 右侧加号 - 镜像 iPad - 再选择虚拟显示器 - 用作（iPad 镜像）
> *(如果没有出现 iPad，尝试推出 iCloud 但保留本地副本后重登，或连接数据线尝试)*

**6. 设置 Mac 端快捷指令**
用于自动启用随航（代码见下方）。
> **操作**：
> 1. 创建快捷指令 - 运行 AppleScript - 授予所有权限（可用右上角开始键测试）。
> 2. 将此快捷指令添加到程序坞 - 右键 - 在访达中显示 - 拖入左侧“应用程序 (Applications)”文件夹。
> 3. 在“启动台”检查是否移动成功。

**7. iPad 端设置快捷指令**
用于 SSH 连接 Mac 并运行上面的指令。
> **操作**：添加“通过 SSH 运行脚本”
> *   **代码**：`open -a "/Applications/Mac上的快捷指令名称.app"` (注意路径)
> *   **主机**：填写 Mac 的本地主机名 (在 Mac 设置-通用-共享中查看)
> *   **用户**：填写群组名字，密码同上

---

#### 注意事项与代码

*   **连接技巧**：如果在无屏幕情况下无法启动，用数据线连接 Mac 和 iPad，长按 Mac 开机键强制关机，重启后等 10s 再开启随航。
*   **操作手势**：双指滚动，捏合缩放，三指点击调出剪切板，更多操作建议配合 Pencil。

**Mac 端快捷指令代码 (AppleScript)**
*(请直接复制，不要修改)*

```applescript
-- 自定义函数：从后往前找最后一个匹配项的索引
on findLastTargetIndex(targetItem, itemList)
    set lastIndex to 0
    repeat with i from (count of itemList) to 1 by -1
        if item i of itemList is targetItem then
            set lastIndex to i
            exit repeat
        end if
    end repeat
    return lastIndex
end findLastTargetIndex

beep 1
beep 1

tell application "System Settings"
    activate
    delay 2 -- 增加初始等待，确保窗口完全打开
    
    tell application "System Events"
        tell process "System Settings"
            click menu item "显示器" of menu "显示" of menu bar item "显示" of menu bar 1
            delay 1
            
            tell group 1 of group 2 of splitter group 1 of group 1 of window "显示器"
                try
                    set buttonFound to false
                    set timeoutSeconds to 10
                    set startTime to current date
                    repeat
                        try
                            set addButton to pop up button "添加"
                            set buttonFound to true
                            exit repeat
                        on error
                            if (current date) - startTime > timeoutSeconds then
                                say "超时：未找到“添加”按钮"
                                return
                            end if
                            delay 0.5
                        end try
                    end repeat
                    
                    if buttonFound then
                        click addButton
                        delay 0.5
                        
                        -- 获取菜单项
                        tell pop up button "添加"
                            set menuItems to name of menu items of menu 1
                        end tell
                        
                        set targetIndex to (my findLastTargetIndex("NameiPad", menuItems))
                        -- NameiPad：是你的Mac名称要修改
                        if targetIndex > 0 then
                            -- 关键修复：点击前激活窗口，确保焦点正确
                            tell application "System Settings" to activate
                            delay 0.5
                            
                            -- 点击目标菜单项
                            tell pop up button "添加"
                                click menu item targetIndex of menu 1
                            end tell
                            
                            -- 等待 Continuity 完成连接（这是解决“无法连接”的关键）
                            delay 3
                            
                            say "已点击连接 NameiPad，请等待镜像启动"
                        else
                            say "未找到设备：NameiPad"
                        end if
                    end if
                on error errMsg number errNum
                    say "发生错误：" & errMsg
                    return
                end try
            end tell
        end tell
    end tell
end tell

delay 1
beep 1
tell application "System Settings" to quit
```

**iPad 端 SSH 设置参考**

*   **脚本内容**：`open -a "/Applications/连接iPad.app"`
    *(注：请将“连接iPad.app”替换为你实际生成的 App 名称)*
*   **主机**：`你的mac名字.local`
*   **端口**：`22`
*   **认证**：密码