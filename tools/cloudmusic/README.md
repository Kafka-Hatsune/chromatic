# 网易云音乐安装与使用指南

适用于想恢复 BetterNCM 插件商店的 Windows 用户。已实测：Windows 10 22H2 x64、网易云音乐 **3.1.41.205529 x64**、BetterNCM **1.3.4 x64**。详细边界见 [VALIDATION.md](VALIDATION.md)。

## 第一次安装

1. 先安装并确认网易云音乐本身能够正常启动。
2. [下载本仓库 ZIP](https://github.com/Kafka-Hatsune/chromatic/archive/refs/heads/master.zip)，**完整解压**到可写目录。不要在压缩包预览窗口内运行脚本。
3. 保存正在进行的操作；安装会完整退出该安装目录的网易云进程并重新启动。
4. 打开解压后的 `tools/cloudmusic`，双击 **`Install.cmd`**。
5. 脚本会尝试从运行进程、注册表和常见位置检测安装目录。若出现 `Enter the CloudMusic folder`，输入包含 `cloudmusic.exe` 的文件夹路径并回车，也可以输入完整的 `cloudmusic.exe` 路径。
6. 出现 `Installed` 后，网易云会重新打开。按下任意键关闭安装窗口。

找不到目录时，可以右键桌面上的网易云快捷方式，选择“打开文件所在的位置”。若打开的仍是快捷方式，查看其“属性 → 目标”中的可执行文件位置。

普通安装不需要额外开发环境。只有出现 `Access denied` / “拒绝访问”，且确认是安装目录权限问题时，再右键 `Install.cmd`，选择“以管理员身份运行”。启动器使用的执行策略仅作用于本次 PowerShell 进程，不修改系统的永久执行策略。

不要只下载单个 `.ps1` 文件：脚本依赖同目录的 `Common.ps1` 和 `packages`。

### 想明确指定目录

在本目录的 PowerShell 窗口中执行，替换成你自己的路径：

```powershell
.\Install-BetterNCM.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -Restart
```

只做检查，不写入文件、不重启：

```powershell
.\Install-BetterNCM.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -CheckOnly
```

## 已有 BetterNCM：只修复插件商店

双击 **`Repair-Market.cmd`**，或者：

```powershell
.\Install-BetterNCM.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -MarketOnly -Restart
```

这个模式保留安装目录已有的 `msimg32.dll`，更新 PluginMarket 和源配置。它要求现有加载器提供兼容的 BetterNCM 接口；不会判断所有第三方 fork 的 API 是否兼容。

普通安装发现不同于所附官方版本的 `msimg32.dll` 时会停止，不会覆盖。若要更换加载器，应先用原加载器自己的卸载方法处理。

## 安装后使用插件

1. 点击网易云右上角的 **BetterNCM** 图标。
2. 在左侧选择 **PluginMarket**。
3. 首次显示欢迎页面时点击“开始使用”。如果右侧空白，点击上方“重载插件”。这属于现有框架的首次界面挂载问题，本修复包没有改动该框架。
4. 搜索或浏览插件，点击安装，等待页面重载。先逐个安装和验证，再继续添加。
5. 已加载插件会出现在管理器左侧；点击插件进入其设置。插件自行决定是否需要完整重启。

默认插件源是 [BetterNCM 官方打包仓库](https://github.com/BetterNCM/BetterNCM-Packed-Plugins)。需要能访问 `raw.githubusercontent.com`；备用源能否连接、是否及时同步，取决于网络和源本身。本修复未打包全部第三方插件供离线使用。

商店中标记支持网易云 3.x，并不代表该插件的全部功能都已适配 3.1.41。本仓库的兼容性记录不会自动覆盖商店里的所有插件。

### RefinedNowPlayingNext 的界面操作

这是可选的第三方播放页插件，安装器不会自动安装它。

- 返回网易云主页：鼠标移到窗口底部，点击底部中央出现的关闭播放页按钮。
- 最小化、窗口缩放等按钮：鼠标移到右上角后显示。
- GPU、背景效果等设置由插件自己的向导和设置页管理。本安装脚本不改变硬件加速设置。

## 插件导致卡住或无法启动

关闭主窗口可能只是缩到托盘，并没有结束全部进程。

如果最近安装的是 **RefinedNowPlayingNext**，双击 **`Recover.cmd`**。它会完整结束对应目录的网易云进程，将该插件加入 BetterNCM 的禁用列表，再正常启动。插件包、插件设置、登录信息和音乐文件都保留。

需要禁用其他插件时，指定其 manifest 中的 `slug`（没有 `slug` 时需核对加载器实际使用的名称）：

```powershell
.\Recover-CloudMusic.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -PluginSlug 'RefinedNowPlayingNext'
```

重新启用：

```powershell
.\Recover-CloudMusic.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -PluginSlug 'RefinedNowPlayingNext' -EnablePlugin
```

恢复工具只禁用指定插件，不会自动定位所有故障插件，也不会修复加载器本身的问题。

## 回滚本次安装

每次安装都会在 `backups\日期时间\receipt.json` 留下回滚记录及原文件。**不要删除此目录后再尝试回滚。**

在本目录打开 PowerShell，将示例中的 `日期时间` 替换成实际安装记录目录：

```powershell
.\Restore-BetterNCM.ps1 -Receipt '.\backups\日期时间\receipt.json' -Restart
```

- 对于第一次安装，回滚会移除这次新增的加载器和商店。
- 对于覆盖已有安装，回滚会恢复覆盖前的版本；这不等同于卸载旧安装。
- 多次安装需要按需要选择对应的记录。`recovery-` 开头的是插件禁用记录，不能用作安装回滚记录。
- 安装后又修改过的配置或商店包会保留并提示；若加载器 DLL 已被替换，回滚会停止以免覆盖。
- 其他插件、账号数据、缓存与音乐文件不会被递归删除。

## 文件放在哪里

| 文件 | 作用 |
| --- | --- |
| 网易云安装目录的 `msimg32.dll` | BetterNCM 加载器 |
| 默认 `C:\betterncm\plugins\PluginMarket.plugin` | 修复后的插件商店 |
| 默认 `C:\betterncm\config.json` | 插件源等框架设置，安装时保留其他配置项 |
| 默认 `C:\betterncm\disable_list.txt` | 指定插件的禁用列表 |
| 本工具目录的 `backups` | 本次工具操作的备份与回滚记录 |

已有 `BETTERNCM_PROFILE` 环境变量时会采用该数据目录。显式传入 `-ProfileDir` 时必须与当前环境变量匹配。普通用户不需要设置它。

安装不修改 `cloudmusic.exe` 或 `libcef.dll`，正常启动不开启调试端口。

## 常见失败提示

| 提示或现象 | 处理方法 |
| --- | --- |
| `cloudmusic.exe not found` | 检查是否输入了快捷方式所在目录，而非程序实际目录 |
| `requires x64` | 当前包只支持 x64，不能把 x64 DLL 装入 32 位网易云 |
| `different loader` | 已有不同加载器；使用只修复商店模式，或先卸载原加载器 |
| `Package checksum mismatch` | 重新下载、完整解压；不要混用不同包里的文件 |
| 商店列表加载失败 | 检查 GitHub Raw 连通性和所选源；重装 DLL 通常不能解决网络问题 |
| `Exit CloudMusic completely` | 从托盘退出，或在命令中增加 `-Restart` |
| 无法写入 / 拒绝访问 | 检查目录权限；必要时以管理员身份运行安装入口 |

报告问题时附上 Windows、网易云版本及位数、加载器版本、插件名称和复现步骤即可。不要公开上传完整账号配置、缓存、备份或带个人内容的诊断截图。
