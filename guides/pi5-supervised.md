# Raspberry Pi 5 に Home Assistant Supervised を入れる（AI 向け・上級者向け）

[AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md) から来た AI 向けの手順です。

Raspberry Pi OS の上に Docker と HA の Supervisor を入れる方式です。**HA の画面やアプリ（旧アドオン）は HA OS とほぼ同じように使えて、同じ Pi でほかのソフト（ファイルサーバー、自作スクリプトなど）も動かせます。**

## 始める前にユーザーに必ず伝えること

- **この方式は、HA 公式のサポートが 2025.12 で終わっています。** 動きはしますが、HA の画面に「サポートされていないシステム」と表示され、不具合を報告しても対応してもらえません。今後の更新で動かなくなる可能性もあります。
- HA だけを使うなら、[pi5-haos.md](pi5-haos.md)（HA OS）のほうが簡単で安全です。
- 同じ Pi でほかのソフトを動かすと、HA が不調になったときの原因の切り分けが難しくなります。

ユーザーが了解したら進めます。了解しなければ pi5-haos.md に切り替えます。

参考：この手順は、Raspberry Pi 5（8GB）・Raspberry Pi OS（Debian 12 bookworm）・Supervisor 2026.11 / HA 2026.11 で動いている実機の設定をもとにしています。インストーラ 4.0.0（2025-11）で Debian 13（trixie）にも対応しました。

## 進め方

この方式では、あなた（AI）がユーザーのパソコンから **SSH で Pi に接続してコマンドを実行**できます。ほとんどの作業をあなたが行えます。

## 1. Raspberry Pi OS を書き込む（ユーザーのパソコンで）

1. SSH 用の鍵を用意します。ユーザーのパソコンに `~/.ssh/id_ed25519.pub` が無ければ `ssh-keygen -t ed25519` で作ります（パスフレーズは空でよいか、ユーザーに聞く）。
2. Raspberry Pi Imager を入れます（[pi5-haos.md](pi5-haos.md) の「1. 書き込みソフトを入れる」と同じ）。
3. Imager で次を選んでもらいます。
   - **デバイス**：Raspberry Pi 5
   - **OS**：「Raspberry Pi OS (other)」→「**Raspberry Pi OS Lite (64-bit)**」（画面のないサーバー用）
   - **ストレージ**：microSD か USB ケースに入れた NVMe SSD。**容量を見て確認**（止まって確認する場所 1）
4. 「OS のカスタマイズ」で次を設定してもらいます。
   - ホスト名：例 `raspi5`（以下 `<ホスト名>`）
   - ユーザー名とパスワード：ユーザーが決める（以下 `<ユーザー>`）
   - ロケール：タイムゾーン `Asia/Tokyo`、キーボード `jp`
   - **SSH を有効にする** →「公開鍵認証のみ」→ 1 の `id_ed25519.pub` の中身を貼る（あなたがファイルの中身を表示して、ユーザーにコピーしてもらう）
   - Wi-Fi は設定しない（有線 LAN を使う）
5. 書き込み → Pi に挿す → LAN ケーブル → 電源。2〜3 分待ちます。

## 2. SSH でつなぐ

```
ssh <ユーザー>@<ホスト名>.local
```

つながらなければ、ルーターの管理画面で Pi の IP アドレスを探してもらいます。以後のコマンドは、Pi の上で実行します。

まず状態を確認します。

```
cat /etc/os-release | head -4      # Debian 12 (bookworm) か 13 (trixie)
uname -m                           # aarch64
nmcli -t device                    # NetworkManager が eth0 を管理しているか
```

`uname -m` が `aarch64` でなければ（32 ビット版の OS）、書き込みからやり直します。

## 3. 更新と必要なパッケージ

```
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget
```

- Raspberry Pi OS は最初から NetworkManager を使っているので、HA 公式の手順にある「ifupdown から NetworkManager への移行」は不要です（`/etc/network/interfaces` に eth0 の設定が無いことだけ確認します）。
- `systemd-resolved` を入れた直後に名前解決ができなくなったら、`sudo systemctl restart systemd-resolved NetworkManager` を実行します。SSH が切れたら、少し待ってからつなぎ直します（IP アドレスが変わることがあります）。

## 4. AppArmor を有効にする

HA の Supervisor は AppArmor（アプリの権限を制限する仕組み）を必要とします。Raspberry Pi の標準カーネルでは、起動オプションで有効にします。

```
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak
grep -q 'security=apparmor' /boot/firmware/cmdline.txt || sudo sed -i '1 s/$/ apparmor=1 security=apparmor/' /boot/firmware/cmdline.txt
cat /boot/firmware/cmdline.txt     # 1 行のまま、末尾に追加されていること
sudo reboot
```

再起動後、つなぎ直して `sudo aa-status | head -3` で `apparmor module is loaded.` と出ることを確認します。

## 5. Docker を入れる

```
curl -fsSL https://get.docker.com | sudo sh
sudo docker version
```

## 6. OS Agent を入れる

```
VER=$(curl -s https://api.github.com/repos/home-assistant/os-agent/releases/latest | jq -r .tag_name)
wget -O os-agent.deb "https://github.com/home-assistant/os-agent/releases/download/${VER}/os-agent_${VER}_linux_aarch64.deb"
sudo dpkg -i os-agent.deb
busctl introspect --system io.hass.os /io/hass/os | head -3   # エラーが出ないこと
```

## 7. HA Supervised を入れる

機種の質問に自動で答えるよう、先に機種を設定してから入れます。

```
echo "homeassistant-supervised ha/machine-type select raspberrypi5-64" | sudo debconf-set-selections
wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
sudo apt install -y ./homeassistant-supervised.deb
```

- Raspberry Pi 4 の場合は `raspberrypi4-64` にします。
- インストール中に一時的にネットワークが切れることがあります。SSH が切れたら、数分待ってつなぎ直し、`sudo docker ps` で確認します。
- 「OS がサポートされていない」と止まる場合は、Debian 12 / 13 以外の OS です。書き込みからやり直します。
- データは `/var/lib/homeassistant` に保存されます（HA の設定は `/var/lib/homeassistant/homeassistant`）。

## 8. 起動の確認

数分〜20 分で、HA のコンテナが順に起動します。

```
sudo docker ps --format '{{.Names}}'   # hassio_supervisor, homeassistant などが並ぶ
```

`homeassistant` が出たら、`http://<ホスト名>.local:8123` を開きます。[first-steps.md](first-steps.md) へ進みます。

## Supervised ならではの注意

- **「サポートされていないシステム」の表示は正常です**（理由は `os`・`software` など）。消す方法はありません。
- **HA が管理する Docker に、ほかのコンテナを置かないでください。** Supervisor が「未知のソフト」とみなし、不調の原因になります。ほかのソフトは Pi に直接（apt などで）入れます。
- HA 本体・Supervisor・アプリの更新は HA の画面からできます。**OS（Raspberry Pi OS）の更新**は自分で `sudo apt update && sudo apt full-upgrade` を行います。Docker の大きな更新の前には HA のバックアップを取ります。
- ページサイズ：Raspberry Pi 5 の標準カーネルはページサイズ 16K です（`getconf PAGESIZE` で `16384`）。筆者の環境はこのままで動いていますが、一部のアプリが起動しない場合は、`/boot/firmware/config.txt` に `kernel=kernel8.img`（4K ページのカーネル）を追加して再起動すると直ることがあります。
- 将来 HA OS に移るときは、HA のバックアップを取り、HA OS を入れた機械で「バックアップから復元」すれば、設定をそのまま持っていけます。

## 参考

- Supervised インストーラ：https://github.com/home-assistant/supervised-installer
- OS Agent：https://github.com/home-assistant/os-agent
- 廃止の発表（2025-05）：https://www.home-assistant.io/blog/2025/05/22/deprecating-core-and-supervised-installation-methods-and-32-bit-systems/
