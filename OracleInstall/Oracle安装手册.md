# Oracle 数据库安装全记录（Windows 11 家庭版 · 中文用户名 · 装到 D 盘）
> 记录日期：2026-11-13
> 机器：LAPTOP-SMS3QHLC（AMD Ryzen 9 7940HS / Zen4，13.7GB 内存）
> 系统：Windows 11 家庭版中文版，Build 10.0.26200
> 结论：**Oracle AI Database 26ai Free（数据库）+ Oracle 11g R2 11.2.0.4 32 位客户端 + PL/SQL Developer 11.0.2** 这一套已跑通并实测登录成功。

---
## 一、最终成果一览
| 组件 | 安装路径 | 说明 |
| ---- | ---- | ---- |
| 数据库 26ai Free | `D:\app\Free26ai` | ORACLE_HOME = `D:\app\Free26ai\dbhomeFree` |
| 11g 32 位客户端 | `D:\app\client\product\11.2.0\client_1` | 给 32 位 PL/SQL Developer 提供 OCI |
| PL/SQL Developer 11.0.2.1766 | `D:\PLSQLDeveloper` | 32 位程序，从 U 盘整份拷贝 |
| Oracle 清单（Inventory） | `C:\Program Files (x86)\Oracle\Inventory` | 32 位客户端写入 |

### 连接参数（记住这一组就够）
| 项 | 值 |
| ---- | ---- |
| 主机端口 | `127.0.0.1:1521` |
| 容器库（CDB） | `FREE` |
| 可插拔库（PDB） | `FREEPDB1` |
| 管理员账号 | `system`，口令 `Oracle26ai` |
| SYS 账号 | `sys`，口令 `Oracle26ai`（`as sysdba` 登录） |
| 字符集 | AL32UTF8 |

### 服务（装完自动创建，均为开机自启）
- `OracleServiceFREE` —— 数据库实例服务（必须 Running）
- `OracleOraDB23Home1TNSListener` —— 监听器（必须 Running）
- `OracleJobSchedulerFREE` —— 禁用状态，正常
- `OracleRemExecService` / `OracleVssWriterFREE` —— 辅助服务，可忽略

---
## 二、版本选型：为什么不是 11g
初始目标是 U 盘里的 11g R2 `setup.exe`（11.2.0.1），结论是装不了，改用官方免费版 26ai Free。

| 版本 | 能否在 Win11 + Zen4 上装 | 原因 |
| ---- | ---- | ---- |
| Oracle 11g R2 11.2.0.1（数据库） | ❌ 明确不能 | OUI 捆绑 JDK 1.5.0_17，在 Win11 build 26200 + Zen4 上必然 native 崩溃：`0xc0000005`、`ntdll.dll+0x124137`，GUI 与静默两条路都崩，生成 11 份 hs_err |
| Oracle 11g R2 11.2.0.4 客户端（32 位） | ✅ 可以 | 安装器内嵌 JDK 较新，不再崩；静默安装约 90 秒完成 |
| Oracle 11g R2 11.2.0.4 数据库 | ⚠️ 未验证 | U 盘只带了第 3 分卷（纯客户端），缺 1of6/2of6，无引擎 |
| Oracle 26ai Free（Windows x64） | ✅ 成功 | 官方免费版，Windows x64 zip 可匿名下载 |
| Docker 官方 Oracle 镜像 | ❌ 网络不通 | Oracle private registry 的 `/auth` 端点从本机 20 秒超时；国内加速器只代理 Docker Hub |

> 重要认知：**11g 那一代安装器失败与"配置不足"无关，是 JDK 与 CPU/系统不兼容**。不用找"兼容模式""改 cvu_prereq.xml""绕过系统检查"之类的偏方，那些只能骗过检测，骗不过 native 崩溃。

---
## 三、需要准备的东西（清单）
### 1. 安装介质
| 文件 | 大小 | 取得方式 |
| ---- | ---- | ---- |
| `oracle-ai-database-free-26ai-windows.x64.zip` | 约 1.31 GB | Oracle 官网 Oracle Database Free 下载页（Windows x64） |
| 11g R2 客户端分卷 `p13390677_112040_WINNT_3of6.zip` | 约 578 MB | U 盘 / 实验室；解压后只有 `client`，不含数据库引擎 |
| `PLSQL Developer` 便携目录 | 约 32 MB | U 盘 / 实验室（`plsqldev.exe` = 11.0.2.1766，x86 32 位） |

### 2. 磁盘空间
数据库约需 8～10GB；客户端 Runtime 类型约 750MB
本次均装 D 盘：`D:\app`
> 安装目录及其所有父目录不要有中文，也不要让 `Authenticated Users` 有写权限（26ai 安装向导会直接红字拦你）

### 3. 权限与账户
必须是 `Administrators` 组的直接成员（不能只是嵌套成员）
需要一个纯英文名的本地账户（见"核心前提"，这是本次成功的最关键一步）

---
## 四、核心前提  
### 前提 1：用纯英文名账户执行安装
本机登录账户是 `瑶`（中文名），profile 为 `C:\Users\瑶`。Oracle 安装器（11g 与 26ai）在这条中文路径上有两类致命症状：
11g 客户端安装：`[INS-30131] Initial setup required for the execution of installer validations failed`，展开为 `CAUSE: Failed to access the temporary location.`
26ai 安装：`clone.pl -virtualAccount` 阶段 `SetACLForUser` 报 `PRCZ-1042` / `WSE-000014`，底层 `OS 1332 (ERROR_NONE_MAPPED)`，最终 `RunScripts returned actual error code 1603` 并整体回滚

改 `TEMP`/`TMP` 到 `D:\Temp`、加 `-ignorePrereq`、换安装类型，全都无效（校验程序不读这些）。

做法：新建本地管理员账户，用计划任务以它身份跑静默安装：
```powershell
net user oracle Oracle12345 /add
net localgroup Administrators oracle /add

schtasks /create /tn OraDbInstall /tr "D:\Oracle\downloads\run_db_install.cmd" `
  /ru oracle /rp Oracle12345 /rl HIGHEST /sc once /st 23:58 /f
schtasks /run /tn OraDbInstall
```

装完务必清理（否则任务会在设定时间自己再跑一遍安装）：
```powershell
schtasks /delete /tn OraDbInstall /f
schtasks /delete /tn OraClientInstall /f
net user oracle /active:no
```

### 前提 2：系统区域临时改为英文（en-US）
26ai 安装日志明确写出：`Locale 'Chinese (Simplified)_China.936' is unsupported, and may crash the interpreter.`
```powershell
Set-WinSystemLocale en-US
Set-Culture en-US
# 必须重启
```
改完核对：系统区域 LCID 1033、ACP 1252、OEMCP 437。

> **副作用（很重要）**：ACP 变成 1252 后，任何含中文的路径在旧式（ANSI）程序里都会变成 `?`，典型表现是 PL/SQL Developer 报 `Cannot create file "C:\Users\?\AppData\Roaming\docking.ini"`。
> 所以 Oracle 全部装完后，**要把系统区域改回中文**：
> ```powershell
> Set-WinSystemLocale zh-CN
> Set-Culture zh-CN
> # 重启后生效（ACP 回到 936）
> ```
> 只改注册表 ACP（`HKLM\SYSTEM\CurrentControlSet\Control\Nls\CodePage\ACP = 936`）而不重启，新进程能用 936，但系统状态不一致，**建议重启**。

### 前提 3：绕过 VC++ 运行库降级拦截
26ai 的 `setup.exe` 会先检查前置组件，捆绑的 VC++ 14.50.x 被判为"比系统已装的 14.51.x 旧"，Burn 引擎直接返回 `0x666 (ERROR_PRODUCT_VERSION)`，还没进 OUI 就回滚。

两种绕过方式：
- 方式 A（推荐）：不用 `setup.exe`，直接 `msiexec` 跑主 MSI
- 方式 B：把捆绑的 `vcredist_x64.exe` 临时替换成返回 0 的桩程序，装完还原

替换位置：
```
D:\Oracle\downloads\free26ai\ISSetupPrerequisites\{8AD2FD1D-5968-4AD0-95CA-A6CF96F331FE}\vcredist_x64.exe
```
先备份为 `vcredist_x64.exe.orig`（18,558,944 字节），装完拷回。

### 前提 4：安装目录规划
```
D:\app\Free26ai\...                      <- 数据库（INSTALLDIR）
D:\app\client\product\11.2.0\client_1\   <- 11g 32 位客户端（ORACLE_HOME）
C:\Program Files (x86)\Oracle\Inventory  <- 32 位客户端清单
```
`D:\app` 装完后 ACL 会被收紧，非提权会话枚举目录会提示 Access denied（`Get-ChildItem` 返回空不等于目录为空；直接访问具体文件仍可读可执行）。

---
## 五、安装过程
### 5.1 数据库：26ai Free 静默安装
响应文件 `FREEInstall_D.rsp`（放在 `D:\Oracle\downloads\free26ai\`）：
```ini
INSTALLDIR=D:\app\Free26ai
PASSWORD=Oracle26ai
LISTENER_PORT=1521
CHAR_SET=AL32UTF8
DB_DOMAIN=
SOFTWARE_ONLY=FALSE
MODIFY_DIRECTORY_PERMISSIONS=TRUE
```
字段含义：`INSTALLDIR` 装到哪；`PASSWORD` 统一口令（SYS/SYSTEM/PDBADMIN 共用）；`SOFTWARE_ONLY=FALSE` 表示装完顺手建库（TRUE 则只装软件）；`MODIFY_DIRECTORY_PERMISSIONS=TRUE` 让安装器自己修目录权限。

执行命令 `run_db_install.cmd`：
```bat
@echo off
set TEMP=D:\Temp
set TMP=D:\Temp
cd /d D:\Oracle\downloads\free26ai
setup.exe /s /v"RSP_FILE=D:\Oracle\downloads\free26ai\FREEInstall_D.rsp" /v"/L*v D:\Oracle\downloads\db26ai_silent.log" /v"/qn"
echo exit=%ERRORLEVEL%
```
参数必须写成完整的一整串。踩过的坑：用 PowerShell 数组拼接（`@("/s","/v`"RSP_FILE=...`"")`）会在参数中间插入空格，变成 `RSP_FILE= D:\...`，导致 `msiexec` 只打印用法帮助、安装根本没开始。

正常装完的日志特征（`db26ai_silent.log`，约 30MB）：
```text
INFO: Oracle Software configuration finished successfully
INFO: Oracle Listener configuration finished successfully
INFO: cmd.exe /c "...dbca.bat -silent -createDatabase -gdbName FREE -templateName FREE_Database.dbc
     -characterSet AL32UTF8 -createAsContainerDatabase true -numberOfPDBs 1 -pdbName FREEPDB1 -sid FREE ..."
MainEngineThread is returning 0
```
`MainEngineThread is returning 0` = MSI 成功。整套约 15～25 分钟，DBCA 建库占大头；期间 `setup.exe`、`msiexec.exe`、`java.exe` 长时间存在，不是卡死。

装完检查清单：
```powershell
Get-Service Oracle* | ft Name,Status
Test-NetConnection 127.0.0.1 -Port 1521     # TcpTestSucceeded 应为 True
Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Oracle - OraDB23Home1\SQL Plus.lnk"
Get-ChildItem "HKLM:\SOFTWARE\Oracle"       # 应有 KEY_OraDB23Home1
```

```sql
-- 用自带 sqlplus 验证
D:\app\Free26ai\dbhomeFree\bin\sqlplus.exe  system/Oracle26ai@//127.0.0.1:1521/FREEPDB1
SQL> select name, open_mode from v$database;    -- 期望 FREE  READ WRITE
```

### 5.2 11g R2 32 位客户端（为 PL/SQL Developer 而装）
为什么必须装 32 位客户端：PL/SQL Developer 11 是 32 位程序，只能加载 32 位 `oci.dll`；26ai 自带的是 64 位 OCI，32 位程序加载不了。

响应文件 `client_rsp.rsp`：
```ini
oracle.install.responseFileVersion=/oracle/install/rspfmt_clientinstall_response_schema_v11_2_0
ORACLE_HOSTNAME=LAPTOP-SMS3QHLC
UNIX_GROUP_NAME=
INVENTORY_LOCATION=C:\Program Files (x86)\Oracle\Inventory
SELECTED_LANGUAGES=en
ORACLE_HOME=D:\app\client\product\11.2.0\client_1
ORACLE_BASE=D:\app\client
oracle.install.client.installType=Runtime
oracle.install.client.upgrading=false
oracle.install.client.customComponents="oracle.sqlplus:11.2.0.4.0","oracle.rdbms.oci:11.2.0.4.0","oracle.network.client:11.2.0.4.0","oracle.network.listener:11.2.0.4.0","oracle.network.cman:11.2.0.4.0","oracle.nlsrtl.rsf:11.2.0.4.0","oracle.xdk:11.2.0.4.0","oracle.rdbms.util:11.2.0.4.0"
oracle.installer.autoupdates.option=SKIP_UPDATES
```
要点：
`installType=Runtime` 是关键——只装 sqlplus + OCI + net，体积小，不像 Administrator 类型塞满管理工具
`SELECTED_LANGUAGES=en` 只装英文
`SKIP_UPDATES` 跳过联网下载更新（否则又走一次校验，容易撞 INS-30131）

执行命令：
```bat
@echo off
set TEMP=D:\Temp
set TMP=D:\Temp
cd /d E:\Oracle\p13390677_112040_WINNT_3of6\client
setup.exe -silent -ignorePrereq -responseFile D:\Oracle\downloads\client_rsp.rsp
echo exit=%ERRORLEVEL%
```
约 90 秒完成。注册表 32 位视图出现 `HKLM:\SOFTWARE\WOW6432Node\Oracle\KEY_OraClient11g_home1_32bit`。

验证（关键一步）：
```powershell
& "D:\app\client\product\11.2.0\client_1\bin\sqlplus.exe" -s `
  "system/Oracle26ai@//127.0.0.1:1521/FREEPDB1"
```
```sql
SQL> select user from dual;   -- 期望 SYSTEM
```
> 反常识但实测成立：**11g 客户端可以连 26ai**，没有出现 `ORA-28040: No matching authentication protocol`。不必再去找 19c/21c Instant Client。

### 5.3 PL/SQL Developer 配置
U 盘的 `PLSQL Developer` 整个目录拷到 `D:\PLSQLDeveloper`（32.4MB，便携，不写注册表）
建桌面快捷方式指向 `D:\PLSQLDeveloper\plsqldev.exe`

登录对话框：
| 项 | 值 |
| ---- | ---- |
| Username | `system` |
| Password | `Oracle26ai`（10 个字符，大写 O，无尾随空格） |
| Database | `127.0.0.1:1521/FREEPDB1` |
| Connect as | `Normal` |

中文界面：`Tools → Preferences → User Interface → Language` 选 `Chinese`（自带 `Chinese.lang`），重启生效。只要英文就什么都不用动。

---
## 六、问题档案（现象 → 根因 → 解决）
### 问题速查表
| # | 现象/关键字 | 根因 | 解决 |
| ---- | ---- | ---- | ---- |
| 1 | `0xc0000005` / `ntdll.dll+0x124137` / 多份 hs_err | 11g 11.2.0.1 的 OUI 用 JDK 1.5，Win11+Zen4 不兼容 | 放弃 11g 数据库，改 26ai Free |
| 2 | `0x666 (ERROR_PRODUCT_VERSION)` | 捆绑 VC++ 14.50 比系统 14.51 旧，被判降级 | 替换桩程序 或 直接 msiexec 跑主 MSI |
| 3 | `[INS-30131]` + `Failed to access the temporary location` | 中文用户名导致校验拿不到临时句柄 | 换纯英文名账户安装（改 TEMP、`-ignorePrereq` 无效） |
| 4 | `PRCZ-1042` / `WSE-000014` / `OS 1332` / `RunScripts 1603` | 同上，`SetACLForUser` 无法映射中文 profile 下的账户 | 同上，换英文账户一次通过 |
| 5 | `Locale 'Chinese (Simplified)_China.936' is unsupported` | 26ai 的 Java 安装器不支持中文区域 | `Set-WinSystemLocale en-US` + 重启 |
| 6 | msiexec 只打印用法帮助，安装没开始 | PowerShell 数组拼参数插空格（`RSP_FILE= D:\...`） | 参数写成完整单串 |
| 7 | Docker 拉 Oracle 镜像超时 | Oracle registry `/auth` 端点 20 秒超时 | 放弃（需代理或付费专属加速域名） |
| 8 | `Cannot create file "C:\Users\?\AppData\Roaming\docking.ini"` | ACP=1252 无法编码中文用户名 `瑶` | 系统区域改回中文（ACP 936）并重启 |
| 9 | `ORA-01017: invalid username/password`（后面乱码） | 口令输错；乱码是客户端字符集 | 口令严格 10 字符；乱码不影响判断 |
| 10 | 界面字体极小 | PL/SQL Developer 11 按 96 DPI 渲染，屏幕 150% 缩放 | 加兼容标记 `~ GDIDPISCALING DPIUNAWARE`，或程序内调大字体 |
| 11 | `Dynamic Performance Tables not accessible` | 普通用户无权读 `V_$SESSION` 等 | 勾 "Don't show this message again"，或由 SYS 授权 |
| 12 | `ORA-02030: 只能从固定表/视图查询` | 授权写了视图名 `V$SESSION` | 改授底层固定表 `V_$SESSION` |
| 13 | `ORA-01917: 用户或角色不存在` | 在 `CDB$ROOT` 给 PDB 内用户授权 | 先 `alter session set container=FREEPDB1` 或直接连 PDB 服务 |
| 14 | `ORA-01950: 对表空间无权限` | 建了用户但没给配额 | `alter user X quota unlimited on USERS;` |
| 15 | `ORA-01045: lacks CREATE SESSION` | 只建了用户没授权 | `grant create session to X;` |

### 几个最容易卡住的，展开说
#### ① INS-30131 与 clone.pl 失败是同一件事
看到 `Failed to access the temporary location`，常见反应是改 TEMP、关 UAC、加 `-ignorePrereq`。本次三种都试过，全部无效。病因是：校验程序要用当前用户 profile 路径做句柄与 ACL 操作，中文用户名让这步拿不到可映射账户（11g 报 INS-30131，26ai 报 OS 1332）。

判定方法：
```powershell
$env:USERPROFILE          # 若形如 C:\Users\瑶，即命中
```

#### ② 装完连不上？先查这三样
```powershell
Get-Service OracleServiceFREE, OracleOraDB23Home1TNSListener | ft Name,Status
Test-NetConnection 127.0.0.1 -Port 1521
& "D:\app\Free26ai\dbhomeFree\bin\sqlplus.exe" -s "system/Oracle26ai@//127.0.0.1:1521/FREEPDB1"
```
服务没起 → `net start OracleServiceFREE`；端口不通 → 查监听器 `lsnrctl status`；都正常但 01017 → 口令问题。

#### ③ PL/SQL Developer 报 docking.ini
这是编码问题，不是磁盘权限（用管理员运行也没用）。判定：用户名换成英文、或 ACP 改回 936 后立刻消失。

临时绕法（不推荐长期用）：
```bat
set APPDATA=D:\PLSQLDeveloper\profile
start "" "D:\PLSQLDeveloper\plsqldev.exe"
```
注意：该程序部分配置直接向系统查目录，环境变量不一定能完全骗过，根治靠系统区域设置。

#### ④ 字体太小
```powershell
# 等同 右键→属性→兼容性→更改高DPI设置→"系统(增强)"
$key='HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
New-ItemProperty -Path $key -Name 'D:\PLSQLDeveloper\plsqldev.exe' `
  -Value '~ GDIDPISCALING DPIUNAWARE' -PropertyType String -Force
```
再配合 `Tools → Preferences → User Interface → Fonts` 调大 Editor/Grid 字号。

---
## 七、卸载与回滚
### 卸载 26ai
开始菜单 `Oracle - OraDB23Home1` → `Uninstall - OraDB23Home1.lnk`
或 `oradim -delete -sid FREE` 删实例，再走 MSI 卸载

手工清理残留：
```powershell
sc stop OracleServiceFREE
sc delete OracleServiceFREE
sc delete OracleOraDB23Home1TNSListener
Remove-Item -Recurse -Force D:\app
Remove-Item -Recurse -Force "HKLM:\SOFTWARE\Oracle"
Remove-Item -Recurse -Force "C:\Program Files\Oracle\Inventory"
Get-LocalGroup | Where-Object Name -like 'ORA_*' | Remove-LocalGroup   # 需管理员；该 cmdlet 无 -Force
```

### 卸载 11g 客户端
```powershell
& "D:\app\client\product\11.2.0\client_1\deinstall\deinstall.bat"
# 或 控制面板 → 程序 → Oracle Database Client 11.2.0 卸载
```

---
## 八、日常使用与常用语句
### 启停
```powershell
net start OracleServiceFREE            # 起库
net stop  OracleServiceFREE            # 停库（先停库再停监听）
net start OracleOraDB23Home1TNSListener
lsnrctl status                         # 在 dbhomeFree\bin 下
```

### 常用 SQL（以 system 登录）
```sql
select name, open_mode, cdb from v$database;
select name, open_mode from v$pdbs;

select tablespace_name, contents, status from dba_tablespaces;
select username, account_status, default_tablespace from dba_users where oracle_maintained='N';

select privilege, admin_option from dba_sys_privs where grantee='ST2406010066';
select granted_role from dba_role_privs where grantee='ST2406010066';
select * from dba_ts_quotas where username='ST2406010066';
```

### 建练习账户  
```sql
CREATE USER study IDENTIFIED BY "study123"
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER TO study;
```
要点：
Oracle 里"建库"= 建用户。CDB（FREE）与 PDB（FREEPDB1）安装时已建好，不需要天天新建数据库（本机 `max_pdbs=18`，已用 1 个）
`QUOTA` 与 `CREATE TABLE` 是两件事：有权限没配额照样 `ORA-01950`
用户名不加引号会自动变大写（`study` → `STUDY`）
增删改查自己名下的表，本来就不需要授权；对象权限 `SELECT/INSERT/UPDATE/DELETE` 只在操作别人的表时才需要

### 给普通用户开"统计"标签（可选）
```sql
-- 用 SYS 连 FREEPDB1，必须是 V_$ 而不是 V$
grant select on v_$session  to study;
grant select on v_$sesstat  to study;
grant select on v_$statname to study;
```

---
## 九、附录
### 目录结构
```
E:\Oracle安装手册\
├── Oracle安装手册.md            <- 本文件
├── 01_安装脚本\
│   ├── FREEInstall_D.rsp        26ai 静默响应文件
│   ├── client_rsp.rsp           11g 客户端响应文件
│   ├── run_db_install.cmd       以 oracle 账户跑 26ai 静默安装
│   ├── run_client_install.cmd   以 oracle 账户跑客户端静默安装
│   ├── make_oracle_acct.ps1     建账户 + 建任务 + 触发（管理员）
│   ├── run_client_task.ps1      建客户端任务 + 触发（管理员）
│   ├── cleanup_task.ps1         删任务 + 停用账户（管理员）
│   ├── revert_locale.ps1        系统区域改回中文（管理员，改完重启）
│   └── launch_plsql.cmd         PL/SQL Developer 英文配置目录启动器（备用）
└── 02_日志样本\
    ├── oracle_acct.log          账户与任务创建
    ├── client_task.log          客户端安装任务
    ├── cleanup_task.log         清理任务与停用账户
    └── locale_revert.log        区域设置恢复
```

### 大日志在哪（未随包，体积太大）
| 日志 | 路径 | 说明 |
| ---- | ---- | ---- |
| 26ai 成功安装日志（约 30MB） | `D:\Oracle\downloads\db26ai_silent.log` | 结尾 `MainEngineThread is returning 0` |
| 失败的两次静默安装 | `D:\Oracle\downloads\setup26ai.log`、`setup26ai2.log` | 各约 38MB，含 clone.pl 失败现场 |
| OUI 失败临时目录 | `D:\Temp\OraInstall2026-11-13_*` | 11g 客户端 INS-30131 现场 |

排查顺序：先看结尾有没有 `returning 0`，再往上搜 `Return value 3` / `not successful` / `SEVERE`。

### 一键自检（可直接粘到 PowerShell）
```powershell
$sp="D:\app\Free26ai\dbhomeFree\bin\sqlplus.exe"
Get-Service Oracle* | ft Name,Status
"port1521=" + (Test-NetConnection 127.0.0.1 -Port 1521 -WarningAction SilentlyContinue).TcpTestSucceeded
"select name,open_mode from v`$database;`nexit;" | & $sp -s "system/Oracle26ai@//127.0.0.1:1521/FREEPDB1"
"select user from dual;`nexit;" | & "D:\app\client\product\11.2.0\client_1\bin\sqlplus.exe" -s "system/Oracle26ai@//127.0.0.1:1521/FREEPDB1"
Test-Path "D:\PLSQLDeveloper\plsqldev.exe"
```

### 教训  
中文用户名是这一整套折腾的真正元凶，换 ASCII 账户胜过一切偏方。
11g 11.2.0.1 在 Win11+Zen4 上装不上，不是配置问题，别浪费时间。
32 位 PL/SQL Developer 必须配 32 位 OCI，但 11g 客户端连 26ai 是能通的。
ACP 改成英文会让中文路径的旧程序全崩，装完记得改回来。
安装类操作一律用完整单串参数，别用数组拼接。
静默安装后必须删掉临时计划任务，否则它会按设定时间再跑一遍安装。

---
本手册基于本机实际执行记录整理，路径、命令、日志特征均为实测，未使用推测内容。
