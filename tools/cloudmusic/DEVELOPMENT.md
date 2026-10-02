# 修复内容与构建

本工具发行标识：`2026.10.02.1`。这是安装工具与补丁的版本，不是 BetterNCM 核心的新版本。

## 改动来源

旧官方安装器会请求 GitCode 上的适配版本清单。本次环境中该地址返回 HTTP 200 的 HTML，无法按 JSON 解析；插件商店旧默认站点连接超时。这里采用官方已发布的 x64 DLL，直接实施上游文档中的 `msimg32.dll` 安装方式。

PluginMarket 基于 `BetterNCM/Plugin-Market` 的提交 `3ad8be7d6e21d87fc8c9e6858a297c0ede5a62f0`，补丁为 [plugin-market.patch](plugin-market.patch)：

- 默认插件源改为官方 GitHub Raw，去掉旧的远程源列表请求。
- 保留备用源、已有的额外源接口和插件包协议。
- 源名称不存在时回退默认源。
- 下载 HTTP 非成功响应时抛出错误，不再将该响应写为插件包。
- 固定 React 等必要依赖并补全构建依赖，保存锁文件。

安装脚本新增架构/文件哈希检查、路径检测、备份与回滚、未知加载器保护、只修复商店模式。恢复工具使用 BetterNCM 自带的 `disable_list.txt` 机制。

**尚未改动**：BetterNCM 原生核心、JavaScript 框架、RefinedNowPlayingNext。下载量统计仍使用上游旧服务；本补丁不代表所有旧网络服务均已替换。HTTP 状态检查也不是对远程插件内容的完整校验。

## 版本与自动更新

PluginMarket 的 manifest 仍为 `0.8.4`。官方插件源对此插件声明 `force-update: "*"`，BetterNCM 1.3.4 会在本地与远程版本字符串不同时替换本地包。直接改成一个独立版本号会触发覆盖。

因此当前用独立的工具发行标识区分修复版本，并通过 `packages/sha256.json` 校验内容。如果远程商店版本发生变化，现有补丁仍可能被自动更新替换；届时需要重新评估，不能将当前策略视为永久更新方案。同一 `PluginMarket` 身份的多个 fork 应作为替换关系处理。

## 重建 PluginMarket

开发环境使用 Git、Node.js **24.14.0**、npm **11.9.0**；无需 Python。普通用户无需执行构建。

在本目录运行：

```powershell
.\Build-PluginMarket.ps1
```

脚本会将上游固定提交克隆到仓库 `.local-install/Plugin-Market-rebuild`，应用补丁、复制锁文件、执行 `npm ci --ignore-scripts` 和生产构建，输出 `PluginMarket.plugin`。已存在的构建目录不会被自动清空；再次构建可以指定新的 `-SourceDir`。

```powershell
.\Build-PluginMarket.ps1 -SourceDir 'D:\Build\PluginMarket-rebuild'
```

ZIP 时间戳和压缩元数据可能导致重建包的整体 SHA-256 不同。核对解包后的文件内容；要替换发行包，必须同步更新 `packages/sha256.json`，并重新进行安装验证。所附 BetterNCM DLL 是官方二进制，这个脚本不编译 C++ 核心。

## 验证脚本

从仓库根目录执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\cloudmusic\tests\Installation.Tests.ps1
pwsh.exe -NoProfile -File .\tools\cloudmusic\tests\Installation.Tests.ps1
```

测试在临时隔离目录使用 PE 头样本检查文件安装、回滚和覆盖保护，不启动网易云、不更改真实账号数据。它不替代真实客户端的运行验证。

## 运行诊断

`Inspect-BetterNCM.mjs` 需要 Node.js 22+。仅排查时，先完整退出网易云，再用 `--remote-debugging-port=32341 --remote-debugging-address=127.0.0.1` 启动目标 `cloudmusic.exe`，运行：

```powershell
node .\Inspect-BetterNCM.mjs
```

使用结束后完整退出该实例，再不带参数地启动。安装和恢复入口均使用正常启动，不持久保存调试设置。诊断文件与截图不属于发行内容。
