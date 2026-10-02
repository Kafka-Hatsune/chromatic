# 来源与许可证

本目录新增的安装、回滚、恢复脚本及 PluginMarket 修改按 [GNU GPL v3](LICENSE) 发布，保留以下上游来源与作者归属。

## BetterNCM 原生加载器

- 作者/项目：std-microblock（原 MicroCBer）及 BetterNCM 贡献者。
- 文件：`packages/BetterNCMII-1.3.4-x64.dll`，保留官方二进制原样。
- 发布页面：[BetterNCM 1.3.4](https://github.com/std-microblock/chromatic/releases/tag/1.3.4)。
- 官方文件：[BetterNCMII.dll](https://github.com/std-microblock/chromatic/releases/download/1.3.4/BetterNCMII.dll)。
- 对应版本源码：[1.3.4 tag](https://github.com/std-microblock/chromatic/tree/1.3.4)、[源码归档](https://github.com/std-microblock/chromatic/archive/refs/tags/1.3.4.zip)。构建依赖和子模块依照该版本仓库配置取得。
- 许可证：[上游 GPL-3.0](https://github.com/std-microblock/chromatic/blob/1.3.4/LICENSE)。
- SHA-256：`A7C77AF418D7940E63FAA58EA036FBA1F4BAAD497947109EA52ED78C8E86608F`。

## PluginMarket

- 作者/项目：[BetterNCM/Plugin-Market](https://github.com/BetterNCM/Plugin-Market)。
- 基础提交：`3ad8be7d6e21d87fc8c9e6858a297c0ede5a62f0`。
- 完整基础源码：[固定提交归档](https://github.com/BetterNCM/Plugin-Market/archive/3ad8be7d6e21d87fc8c9e6858a297c0ede5a62f0.zip)。
- 本地修改：[plugin-market.patch](plugin-market.patch)；依赖锁文件：[plugin-market.package-lock.json](plugin-market.package-lock.json)；构建入口：[Build-PluginMarket.ps1](Build-PluginMarket.ps1)。
- 许可证：[上游 GPL-3.0](https://github.com/BetterNCM/Plugin-Market/blob/3ad8be7d6e21d87fc8c9e6858a297c0ede5a62f0/LICENSE)。
- 发行文件：`packages/PluginMarket.plugin`。该文件不是上游原包，修改范围见 [DEVELOPMENT.md](DEVELOPMENT.md)。

依赖包继续遵循各自的许可证。网易云音乐客户端、账号数据和第三方歌词/主题插件均不在本目录中分发。
