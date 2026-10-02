# chromatic · BetterNCM 安装与插件商店修复

这个 fork 提供 Windows 网易云音乐的 **BetterNCM 安装、插件商店恢复和回滚工具**，用于旧官方安装器或默认插件源失效的情况。

普通用户从这里开始：**[下载仓库 ZIP](https://github.com/Kafka-Hatsune/chromatic/archive/refs/heads/master.zip) → 完整解压 → 打开 `tools/cloudmusic` → 双击 `Install.cmd`**。

- [安装、使用、卸载和故障恢复说明](tools/cloudmusic/README.md)
- [已验证环境、测试范围和兼容性](tools/cloudmusic/VALIDATION.md)
- [修复内容、源码来源与构建方法](tools/cloudmusic/DEVELOPMENT.md)

## 已验证环境

| 项目 | 版本 |
| --- | --- |
| 操作系统 | Windows 10 专业版 22H2，64 位，Build 19045 |
| 网易云音乐 | **3.1.41.205529 x64** |
| CEF / Chromium | 91.2.3+g3268653 / 91.0.4472.169 |
| 插件加载器 | 官方 BetterNCM **1.3.4 x64** |
| 插件商店 | PluginMarket **0.8.4**，本仓库的源地址与错误处理补丁 |
| 安装环境 | Windows 自带 PowerShell 5.1；也验证 PowerShell 7 |

**普通用户不需要安装 Git、Node.js、Python、Visual Studio 或编译源码。** 插件列表与下载需要能够访问 GitHub Raw；软件本体仍由用户自行安装。

这是一组已验证的版本组合。其他网易云版本、Windows 11 和其他加载器 fork 尚未完成相同的运行验证；32 位网易云不受本安装包支持。

## 安装后怎么用

1. 重启网易云，点击右上角新增的 **BetterNCM** 图标。
2. 打开 **PluginMarket**。首次出现引导时点击“开始使用”；若右侧空白，点一次“重载插件”。
3. 从商店选择插件，每次先安装一个并验证。安装器只部署商店，不自动安装主题或歌词插件。
4. 若已安装其他 BetterNCM 加载器，先阅读[只修复商店](tools/cloudmusic/README.md#已有-betterncm只修复插件商店)，使用 `Repair-Market.cmd` 保留原加载器。

安装过程会备份修改的文件。保留 `tools/cloudmusic/backups`，后续回滚需要其中的记录。

## 当前修复的范围

- 使用带 SHA-256 校验的官方 DLL，绕过失效的旧安装器版本查询。
- 插件商店默认连接官方 GitHub 插件库，移除对旧远程源列表的依赖。
- 修复无效源名称导致的异常，以及插件下载 HTTP 错误仍被保存的问题。
- 提供路径检测、未知加载器保护、安装回滚和指定插件禁用工具。

本仓库没有重编译或修改 BetterNCM 核心 DLL，也没有修复所有第三方插件。RefinedNowPlayingNext 的一次卡住问题在完整重启后恢复，但没有确认根因，不能据此承诺已解决长期卡死。

## 与上游 Chromatic 的关系

本 fork 保留 Chromatic 主线源码和历史；网易云修复工具独立放在 `tools/cloudmusic`。工具实际安装的是 **旧 BetterNCM 1.3.4**。直接编译根目录的 Chromatic 不会生成这里使用的 BetterNCM 修复包。

Chromatic 是上游正在重写的 Chromium/V8 通用修改器。见[保留的上游介绍](docs/chromatic-upstream.md)、[上游仓库](https://github.com/std-microblock/chromatic)、[BetterNCM v2 代码存档](https://github.com/std-microblock/chromatic/tree/v2)。

工具与所分发组件的许可证及来源见 [tools/cloudmusic/LICENSE](tools/cloudmusic/LICENSE) 和 [THIRD_PARTY_NOTICES.md](tools/cloudmusic/THIRD_PARTY_NOTICES.md)。该目录的许可证说明不用于重新声明上游其他目录的授权。
