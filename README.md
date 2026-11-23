# home-assistant-setup

**AI に渡すだけで Home Assistant サーバーを作れる指示書** ｜ AI-readable instructions to set up a Home Assistant server (Japanese)

Claude Code・Codex CLI・Gemini CLI などの AI に次の1行を送ると、機種の確認からインストール、最初の設定まで案内してくれます。

```
https://github.com/bey-jp/home-assistant-setup/blob/main/AI_INSTRUCTIONS.md を読んで、その手順どおりに私の Home Assistant サーバーを作ってください。
```

ChatGPT・Gemini などのチャット（Web・アプリ）でも使えます（AI が出すコマンドを自分で実行して、結果を貼り返します）。

```
https://github.com/bey-jp/home-assistant-setup/blob/main/AI_INSTRUCTIONS.md を読んで、「チャット型 AI の進め方」に従って、Home Assistant サーバーを作る手順を1つずつ案内してください。
```

> **ベータ版（2026-11）**：ミニ PC 用の書き込みスクリプト `scripts/write-haos-x86.sh` は、まだ実機での通しテスト前です。試す場合は、消えて困るデータのない PC で使ってください。

## 対応している機種

| 機種 | 方式 | 手順 |
|---|---|---|
| Home Assistant Green | 入っている HA OS をそのまま使う | [guides/green.md](guides/green.md) |
| ミニ PC・中古 PC（N100 / N150 / Core i など） | HA OS（Ubuntu の USB から書き込み） | [guides/x86.md](guides/x86.md) |
| Raspberry Pi 5 / 4（HA 専用） | HA OS（Raspberry Pi Imager） | [guides/pi5-haos.md](guides/pi5-haos.md) |
| Raspberry Pi 5（ほかのソフトと同居） | HA Supervised（**公式サポート終了・上級者向け**） | [guides/pi5-supervised.md](guides/pi5-supervised.md) |

インストール後の最初の設定（アカウント、バックアップ、スマホアプリ）は [guides/first-steps.md](guides/first-steps.md)。

## 安全のために

- ディスクや SD カードに書き込む前に、AI は必ず「中身はすべて消えます。書き込んでよいですか？」と確認します。あなたが「はい」と答えるまで書き込みません。
- ミニ PC 用のスクリプト [scripts/write-haos-x86.sh](scripts/write-haos-x86.sh) は、起動中の USB メモリと USB 接続のディスクには書き込まず、ディスク名の入力と `YES` の入力があるまで何も消しません。イメージは GitHub の SHA-256 と照合します。
- パスワードやトークンを AI に教える必要はありません。

## 解説記事

bey.jp（ブログ）：Home Assistant サーバーの作り方 — どの PC を買えばいい？（準備中）

## English

This repository contains Japanese instructions meant to be read by an AI agent (Claude Code, Codex CLI, Gemini CLI, or a chat AI) so that a beginner can install Home Assistant on Home Assistant Green, an x86-64 mini PC (HA OS via an Ubuntu live USB and `scripts/write-haos-x86.sh`), or a Raspberry Pi 5 (HA OS, or the deprecated Supervised method). Ask your AI to read `AI_INSTRUCTIONS.md` and follow it.

## License

MIT. Home Assistant is a trademark of the Open Home Foundation. This project is not affiliated with Home Assistant or Nabu Casa.
