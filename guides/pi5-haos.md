# Raspberry Pi 5 に Home Assistant OS を入れる（AI 向け）

[AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md) から来た AI 向けの手順です。
Raspberry Pi 5（または 4）を **HA 専用**にする方法です。HA 公式が勧める方式で、更新もボタン1つでできます。

## 用意するもの

- Raspberry Pi 5（メモリ 2GB 以上。4GB 以上を推奨）
- **公式の 27W USB-C 電源**（パソコンの USB ポートやスマホ用の充電器は電力不足になりやすい）
- 起動用のストレージ（どちらか）
  - **microSD カード 32GB 以上**、「A2」の表記があるもの（手軽。ただし数年で劣化することがある）
  - **NVMe SSD**（M.2 HAT と SSD が必要。速くて長持ち。書き込みには USB 接続の NVMe ケースかアダプタが必要）
- LAN ケーブル
- ユーザーのパソコンの SD カードリーダー（無ければ USB の SD カードリーダー）

## 1. 書き込みソフトを入れる

**Raspberry Pi Imager** を入れます。

- Windows：`winget install --id RaspberryPiFoundation.RaspberryPiImager -e`
- Mac：`brew install --cask raspberry-pi-imager`（Homebrew がなければ https://www.raspberrypi.com/software/ から）
- Linux：`sudo apt install rpi-imager`、またはサイトの AppImage

## 2. 書き込む（ユーザーが Imager を操作し、あなたが案内）

1. microSD カード（または USB ケースに入れた NVMe SSD）を、ユーザーのパソコンに挿してもらいます。
2. Imager を開き、次を選んでもらいます（Imager の版によって画面の並びや言葉が少し違います。ユーザーに画面の文字を読んでもらいながら案内します）。
   - **デバイス**：Raspberry Pi 5
   - **OS**：「Other specific-purpose OS」→「Home assistants and home automation」（または「Home automation」）→「Home Assistant」→「Home Assistant OS (RPi 5)」
   - **ストレージ**：挿した microSD / SSD。**容量を見て、正しいものかユーザーと確認**（止まって確認する場所 1）。パソコンの内蔵ディスクや、データの入った外付けディスクを選ばないようにします。
3. 「OS のカスタマイズを使いますか？」と聞かれたら「いいえ」（HA OS では使いません）。
4. 「書き込み」→ 終わるまで待つ → 取り出す。

Imager の一覧に Home Assistant が無い場合は、GitHub のリリース（https://github.com/home-assistant/operating-system/releases ）から `haos_rpi5-64-<版>.img.xz` をダウンロードして SHA-256 を照合し、Imager の「Use custom（カスタムを使う）」で書き込みます。最新の安定版で、ファイル名に `rpi5-64` があるものを選びます。

## 3. 起動

1. microSD を Pi に挿す（NVMe なら HAT に取り付ける）、LAN ケーブルをつなぐ、最後に電源をつなぐ、の順で行ってもらいます。
2. 5〜20 分待ちます。
3. [AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md) の「HA の画面を探す」に従い、`http://homeassistant.local:8123` を開きます。
4. [first-steps.md](first-steps.md) へ進みます。

## うまくいかないとき

- **NVMe から起動しない**：古い Pi 5 は、ブートローダー（基板上の起動プログラム）が NVMe に対応していないことがあります。一度 Raspberry Pi OS の microSD で起動し、`sudo rpi-eeprom-update -a` → 再起動で更新してから、もう一度試します。microSD を挿したままだと、そちらが先に起動します。
- **20 分たっても画面が出ない**：電源（27W）とケーブル、LAN の挿し直しを試します。それでもだめなら書き込みからやり直します。
- **Wi-Fi で使いたい**：最初は有線で起動し、HA の画面の「設定 → システム → ネットワーク」で Wi-Fi を設定します。有線のほうが安定します。

## 参考

- HA 公式（Raspberry Pi）：https://www.home-assistant.io/installation/raspberrypi/
