# RefinedNowPlayingNext 日语汉字上方罗马音

这是基于 **RefinedNowPlayingNext 3.0.2** 的可选改版，版本号为 **3.0.2+romaji.1**。
保留原来的播放页、设置和插件名称，不需要再安装一个独立注音插件。

例如「世界へ」仅在「世界」上方显示 `sekai`，「へ」与中文翻译保持原样。
开启后，日语行不再额外显示整行罗马音。原始歌词、翻译和时间轴不被改写。

## 普通用户安装

1. 先按[安装指南](../README.md)安装 BetterNCM，并正常启动过网易云。
2. 完整下载并解压本仓库，打开 `tools/cloudmusic`，双击 **Install-Romaji.cmd**。
3. 安装器会备份已有的 RNP 3.0.2，并完整重启网易云。没有 RNP 时会安装此版本。
4. 点击左下角歌曲封面，打开 RefinedNowPlayingNext 播放页。
5. 打开该插件设置的 **歌词 → 日语汉字上方注音 → 罗马音**。默认已选中。
6. 保持歌词旁的 **“音”** 按钮开启；也可切换为平假名，或关闭上方注音。

普通用户不需要 Node.js、Git、Python 或编译器。约 16 MB 的插件包内已包含日语词典，
注音生成不依赖 CDN 或第三方在线注音服务。首次遇到日语歌词时加载词典可能需要数秒。
获取歌曲原始歌词仍使用网易云原有接口。

如果 RNP 以前被故障恢复工具禁用了，需先在 BetterNCM 重新启用；本安装器保留禁用列表。
其他 RNP 版本会被安装器拒绝覆盖，防止意外降级。相同版本号的自定义改版仍需自行核对差异。

仅检查环境、不写入或重启：

```powershell
.\tools\cloudmusic\Install-RefinedRomaji.ps1 -CloudMusicDir 'D:\Apps\CloudMusic' -CheckOnly
```

## 注音从哪里来

优先把歌曲已有的罗马音对齐到汉字，原文自带的括号读音也可参与识别。
缺少或无法对齐时，用 **kuromoji / IPADIC** 在本地分析日语，再用 **WanaKana** 转成罗马音。
复用了 [jp-furigana](https://github.com/Leleawa/jp-furigana) 的文字对齐算法，完整保留其许可证。

词典解压、分词和对齐在 Web Worker 中完成。网易云 3.1.41 禁止播放页直接创建 Blob Worker，
因此通过 BetterNCM 挂载的本地页面托管 Worker，并用私有 MessageChannel 传递数据。
没有修改网易云 CSP 或硬件加速设置。关闭注音会释放线程；超时或失败时保留原歌词。

注音直接进入 RNP 的 React 歌词渲染，支持普通歌词、复制模式和逐字歌词。
跨多个逐字时间段的词，例如「世」「界」，合用一个 `sekai` 注音，各字保留原有时间索引。
同一个时间段内部被注音边界拆开的字仍共享原时间段，滑动填色会分别作用于各片段。

## 已验证与限制

- Windows 10 22H2 x64；网易云 **3.1.41.205529 x64**；CEF / Chromium **91**；BetterNCM **1.3.4 x64**。
- 与当前 PluginMarket 修复版和 BGEnhanced 0.3.8 同时加载正常。
- 《愛がゆえに》— 月詠み，歌曲 ID `3437475642`：验证时网易云两种歌词接口均无罗马音；本地补全了 **39 行、141 组汉字**，未给假名或数字加注音，原文完整保留。
- 实机首次加载词典并补全该歌曲约 **1.4 秒**；短时间界面定时器采样的最大间隔约 90 ms。该数值不是所有设备的性能承诺。
- 5 项自动测试通过：文本保留、只注汉字、已有读音优先、跨逐字边界、后台线程及切歌旧任务丢弃。
- 固定源码全新构建通过；构建结果差异仅为文本行尾。安装器和回退脚本在 PowerShell 5.1 与 7 中完成隔离目录测试，回退后原插件字节完全一致。
- CEF 实机检查通过：罗马音 / 平假名 / 关闭切换，关闭恢复整行罗马音，关闭释放托管页面；独立渲染样例的上浮和滑动动画保留时间索引及填色层，注音位置位于汉字上方。

日语识别依据原文中的假名。全曲只有汉字而没有假名时不会擅自当成日语；中日混合歌曲也可能误判个别行。
词典无法保证姓名、多音字、古语、特殊唱法或作者自定义读法完全准确，生僻字可能不注音。
英文、数字与汉字混合且无法可靠拆分的词会保留原样，避免把假名读音重复标到汉字上。

其他网易云版本、加载器 fork、同类 DOM 注音插件的组合尚未完成验证。
不建议同时启用 jp-furigana 等另一套自动改写同一歌词节点的注音插件。
此改版不声称解决了所有 RNP 卡死问题。商店将来升级 RNP 可能覆盖此功能；请保留补丁和插件包。

## 回退

只想恢复原显示：在插件设置中将“日语汉字上方注音”设为“关闭”。

恢复安装前的插件包：使用安装器输出的记录路径，完整退出网易云或加 `-Restart`：

```powershell
.\tools\cloudmusic\Restore-RefinedRomaji.ps1 -Receipt '.\tools\cloudmusic\backups\romaji-日期时间\receipt.json' -Restart
```

回退不删除歌词设置、登录数据或其他插件。若包在安装后又被更新，回退脚本会停止，防止覆盖后续修改。
无法启动时仍可使用上一级目录的 `Recover.cmd` 暂时禁用 RNP。

## 开发者构建

需要 Git、Node.js / npm；已验证 Node.js 24.14.0。构建不需要 Python。

```powershell
.\tools\cloudmusic\refined-romaji\Build.ps1
```

脚本在新的 `.build` 目录拉取固定源码版本、应用 [refined-romaji.patch](refined-romaji.patch)，
复制相同版本的词典与许可证，使用锁文件 `npm ci --ignore-scripts`，构建并运行测试。
新生成的 `.plugin` 路径和 SHA-256 会打印出来，不自动安装到本机。
Git 行尾设置和 ZIP 时间戳会影响包的哈希；随仓库分发的包哈希记录于 [package.json](package.json)。

固定来源：

- [RefinedNowPlayingNext](https://github.com/SUlTlUS/refined-now-playing-netease-next/tree/167bffe62b57bd276fc6aa34237c4a197f56fa7d)：MIT。
- [jp-furigana](https://github.com/Leleawa/jp-furigana/tree/b536d24b67a625dd4fc01a899e92da69a40cfb1f)：对齐代码 MIT；kuromoji Apache-2.0；IPADIC 的 NAIST / ICOT 条款见包内完整 NOTICE。
- [WanaKana 5.3.1](https://github.com/WaniKani/WanaKana)：MIT。

插件包的 `licenses/` 保留上述完整声明。测试使用自造句子；实际歌曲全文、个人配置和调试截图不进入仓库。
