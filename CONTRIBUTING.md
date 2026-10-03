# Contributing

感谢你帮助改进 CodexMeter。

## 开发流程

1. Fork 仓库并创建功能分支。
2. 使用 Xcode 15 或更新版本打开 `CodexMeter.xcodeproj`。
3. 保持主应用和 Widget 的数据模型、App Group 配置兼容。
4. 不要提交 Apple Team ID、证书、Provisioning Profile、账号信息或本地路径。
5. 运行 README 中的无签名构建检查。
6. 提交清晰的 Pull Request，说明行为变化和验证方式；涉及 UI 时附截图。

## 代码原则

- 优先使用系统框架和原生 Swift API。
- 不采集、记录或上传认证凭据。
- 对 App Server 响应做防御性解析，避免依赖数组顺序。
- 用户可见错误保持简洁，详细诊断仅写入本地 Debug Console。
- 新增依赖前说明必要性、许可证和隐私影响。

## Bug 报告

请提供 macOS、Xcode 和 Codex CLI 版本、复现步骤及脱敏后的错误日志。不要粘贴 Token、Cookie、邮箱或其他账号信息。
