# Privacy

CodexMeter is designed to keep account handling local.

- It starts the installed Codex CLI locally and reads usage data from its App Server over standard input/output.
- It does not ask for, read, store, or upload access tokens, browser cookies, or passwords.
- It has no analytics or advertising SDK.
- It does not send data to a CodexMeter-operated server.
- The most recent successful usage snapshot is stored locally so the Widget can display it.
- Network requests needed to retrieve account usage are made by the user's installed and authenticated Codex CLI.

Debug logs may contain technical error messages. Users should review and redact logs before sharing them publicly.
