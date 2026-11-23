# Home Assistant Green の始め方（AI 向け）

[AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md) から来た AI 向けの手順です。

Home Assistant Green には HA が最初から入っています。**インストール作業はありません。** つないで待つだけです。

## 手順

1. **つなぐ**：ユーザーに次をしてもらいます。
   - 同梱の LAN ケーブルで、Green とルーター（または有線 LAN のハブ）をつなぐ
   - 同梱の電源アダプタをつなぐ（電源ボタンはなく、挿すと起動します）
   - USB メモリや Zigbee ドングルは、まだ挿さない
2. **待つ**：初回は HA 本体のダウンロードと更新があるので、5〜20 分かかります。ユーザーには「本体のランプを見ていてください。その間、電源は抜かないでください」と伝えます。
3. **HA の画面を探す**：あなたのパソコンから `http://homeassistant.local:8123` に接続してみます（`curl -s -o /dev/null -w "%{http_code}" http://homeassistant.local:8123`。Windows は `curl.exe`）。
   - 応答があれば、ユーザーにブラウザで同じ URL を開いてもらいます。
   - 「準備中（Preparing Home Assistant）」の画面なら、そのまま待ってもらいます。
   - 20 分たっても見つからなければ、[AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md) の「HA の画面を探す」に従って IP アドレスを探します。それでもだめなら、LAN ケーブルを挿し直す・別のポートに挿す・電源を挿し直す、の順で試してもらいます。
4. **最初の設定**：[first-steps.md](first-steps.md) へ進みます。

## Green の注意

- 内蔵ストレージは 32GB の eMMC です。カメラ映像を大量に保存する用途には向きません。
- USB ポートは USB 2.0 です。Zigbee ドングルを挿すときは、USB 延長ケーブルで本体から離すと電波が安定します。
- ランプの意味や初期化（リセット）の方法は、Nabu Casa のサポートページを見てください：https://support.nabucasa.com/
