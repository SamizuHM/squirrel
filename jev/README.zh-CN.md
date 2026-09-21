# Jev Squirrel 移植（待 macOS 验证）

基于当前鼠须管源码的新分支 `feat/jev-context-ranking`。添加 `sources/JevRanking.swift`、`sources/JevContext.h`，并在 `SquirrelInputController` 接入异步候选排序。密钥可在输入法菜单 **Jev API key / 推荐设置** 中填写，使用 macOS 钥匙串保存。无开发者密钥随源码分发。

通过 InputMethodKit 客户端的周边文本接口读取插入点上下文，安全输入模式停用；URLSession 使用临时会话、超时、请求取消和结果快照校验。不请求辅助功能或屏幕录制权限。实际兼容性受应用暴露的文档接口影响。

**尚未在 macOS/Xcode 编译，也未在 macOS 26 实机验证。此目录不能作为已验证可安装的 Mac 发行版。** Windows 的完整构建和 Rime 集成测试位于同级 `weasel`。

在 macOS 26 + Xcode 26 上：

1. 按上游 `INSTALL.md`（若无则 `README.md`、`Makefile`）准备依赖，运行 `git submodule update --init --recursive` 与 `make deps`。
2. `make release`，按照上游流程安装、签名与启用 Squirrel。
3. 将 `jev/lua/jev.lua` 复制到 `~/Library/Rime/lua/jev.lua`。在全拼或双拼方案的 `.custom.yaml` 中添加以下补丁，并重新部署：

```yaml
patch:
  'switches/@next': {name: jev_enabled, reset: 1, states: [本地, Jev]}
  'engine/processors/@before 0': lua_processor@*jev*processor
  'engine/filters/@next': lua_filter@*jev*filter
```

4. 在输入法菜单设置自己的 key，然后测试 TextEdit、Safari、VS Code，以及密码框、失焦、改动光标、断网。确认已上屏词与候选顺序对应。不要在没有这些验证时声称兼容 macOS 26。

源代码许可证继承上游 GPLv3。协议与整体设计见 `../weasel/jev/README.zh-CN.md`。
