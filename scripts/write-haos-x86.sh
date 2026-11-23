#!/usr/bin/env bash
# Ubuntu のライブ USB（「Ubuntu を試す」）で起動した PC の内蔵ディスクに
# Home Assistant OS（generic-x86-64）を書き込みます。
#
# 使い方（Ubuntu のターミナルで）:
#   wget -O w.sh https://raw.githubusercontent.com/bey-jp/home-assistant-setup/main/scripts/write-haos-x86.sh && sudo bash w.sh
#
# 安全のため:
#   - 起動に使っている USB メモリと、USB 接続のディスクには書き込みません
#   - 書き込むディスクは名前を入力して選び、最後に YES と入力するまで何も消しません
#   - ダウンロードしたイメージは SHA-256 を GitHub の公表値と照合します
# 環境変数: BOARD（既定 generic-x86-64）、HAOS_VERSION（例 18.4。省略時は最新の安定版）
set -euo pipefail

BOARD="${BOARD:-generic-x86-64}"
WORK=/tmp/haos
say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
die()  { printf '\n\033[31m[中止] %s\033[0m\n' "$*" >&2; exit "${2:-1}"; }

[ "$(id -u)" -eq 0 ] || die "sudo bash $0 のように sudo を付けて実行してください。"
[ -d /sys/firmware/efi ] || die "UEFI で起動していません。BIOS で UEFI ブートを有効にし、USB メモリを「UEFI:」の付いた項目から起動し直してください。" 2
for c in python3 xz dd lsblk sha256sum; do command -v "$c" >/dev/null || die "$c が見つかりません。" 2; done

fetch() {  # fetch URL [出力先]
  if command -v curl >/dev/null; then
    if [ -n "${2:-}" ]; then curl -fL --retry 3 -o "$2" "$1"; else curl -fsSL --retry 3 "$1"; fi
  else
    if [ -n "${2:-}" ]; then wget -O "$2" "$1"; else wget -qO- "$1"; fi
  fi
}

# 1. 最新の安定版で、この機種のイメージを含むリリースを探す
#    （Raspberry Pi だけのリリースがあるので、releases/latest は使わない）
say "1/5 Home Assistant OS の最新版を調べています…"
REL_JSON=$(fetch "https://api.github.com/repos/home-assistant/operating-system/releases?per_page=30") \
  || die "GitHub に接続できません。LAN ケーブルと、画面右上のネットワーク表示を確認してください。" 3
read -r VER URL DIGEST < <(printf '%s' "$REL_JSON" | BOARD="$BOARD" WANT="${HAOS_VERSION:-}" python3 -c '
import json, os, sys
board, want = os.environ["BOARD"], os.environ["WANT"]
for r in json.load(sys.stdin):
    if r.get("draft") or r.get("prerelease"): continue
    if want and r["tag_name"] != want: continue
    tag = r["tag_name"]
    name = "haos_" + board + "-" + tag + ".img.xz"
    for a in r["assets"]:
        if a["name"] == name:
            print(tag, a["browser_download_url"], (a.get("digest") or "none").removeprefix("sha256:"))
            sys.exit(0)
sys.exit(1)
') || die "haos_${BOARD} のイメージが見つかりませんでした。" 3
echo "  バージョン: $VER"
echo "  ファイル  : ${URL##*/}"

# 2. 書き込み先のディスクを選ぶ
say "2/5 書き込み先のディスクを選びます"
LIVE_DISK=""
for m in /cdrom /run/live/medium /isodevice; do
  src=$(findmnt -no SOURCE "$m" 2>/dev/null || true)
  [ -n "$src" ] && LIVE_DISK=$(lsblk -no PKNAME "$src" 2>/dev/null | head -1) && [ -n "$LIVE_DISK" ] && break
done
lsblk -d -e 1,7,11 -o NAME,SIZE,TRAN,RM,MODEL
echo
CANDS=()
while read -r name tran rm; do
  [ "$name" = "$LIVE_DISK" ] && continue
  [ "$tran" = "usb" ] && continue
  [ "$rm" = "1" ] && continue
  CANDS+=("$name")
done < <(lsblk -dn -e 1,7,11 -o NAME,TRAN,RM | awk '{ if (NF==2) print $1, "-", $2; else print $1, $2, $3 }')
[ "${#CANDS[@]}" -gt 0 ] || die "書き込める内蔵ディスクが見つかりません（USB 接続のディスクは対象外です）。" 4
[ -n "$LIVE_DISK" ] && echo "  起動中の USB メモリ: $LIVE_DISK（対象外）"
echo "  書き込める内蔵ディスク: ${CANDS[*]}"
read -r -p "書き込むディスクの名前を入力してください（例: ${CANDS[0]}）: " DISK
DISK=${DISK#/dev/}
printf '%s\n' "${CANDS[@]}" | grep -qx "$DISK" || die "「$DISK」は候補にありません。" 4

SECTOR=$(cat "/sys/block/$DISK/queue/logical_block_size")
[ "$SECTOR" = "512" ] || die "このディスクのセクターは ${SECTOR} バイトです。HAOS は 512 バイトのディスクでないと起動しません。" 4
SIZE_GB=$(( $(cat "/sys/block/$DISK/size") * 512 / 1000000000 ))
[ "$SIZE_GB" -ge 32 ] || die "ディスクが ${SIZE_GB}GB しかありません。32GB 以上が必要です。" 4

echo
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL "/dev/$DISK"
echo
echo "  /dev/$DISK（${SIZE_GB}GB）の中身は、Windows も含めてすべて消えます。"
read -r -p "よければ大文字で YES と入力してください: " OK
[ "$OK" = "YES" ] || die "YES ではなかったので、何もせずに終了しました。" 1

# 3. ダウンロードと照合
say "3/5 ダウンロードしています（数分かかります）…"
mkdir -p "$WORK"
IMG="$WORK/${URL##*/}"
fetch "$URL" "$IMG" || die "ダウンロードに失敗しました。" 3
GOT=$(sha256sum "$IMG" | cut -d' ' -f1)
if [ "$DIGEST" = "none" ]; then
  echo "  GitHub に SHA-256 の公表値がありませんでした。計算値: $GOT"
  read -r -p "照合せずに続けますか？（YES で続行）: " OK; [ "$OK" = "YES" ] || die "中止しました。" 1
elif [ "$GOT" != "$DIGEST" ]; then
  die "SHA-256 が一致しません（壊れたファイルの可能性）。もう一度実行してください。" 3
else
  echo "  SHA-256 一致: $GOT"
fi

# 4. 書き込み
say "4/5 /dev/$DISK に書き込んでいます。終わるまで電源を切らないでください…"
for p in $(lsblk -lnpo NAME "/dev/$DISK" | tail -n +2); do umount "$p" 2>/dev/null || true; done
swapoff -a 2>/dev/null || true
xz -dc "$IMG" | dd of="/dev/$DISK" bs=4M conv=fsync status=progress
sync
partprobe "/dev/$DISK" 2>/dev/null || true
sleep 2

# 5. UEFI の起動項目を登録（BIOS が自動で見つけない機種のため）
say "5/5 起動項目を登録しています…"
if command -v efibootmgr >/dev/null; then
  efibootmgr --create --disk "/dev/$DISK" --part 1 --label "HAOS" --loader '\EFI\BOOT\bootx64.efi' >/dev/null \
    && echo "  起動項目「HAOS」を登録しました。" \
    || echo "  起動項目の登録に失敗しました（多くの機種では登録しなくても起動します）。"
else
  echo "  efibootmgr が無いので省略しました（多くの機種では登録しなくても起動します）。"
fi

say "完了しました：Home Assistant OS $VER を /dev/$DISK に書き込みました。"
cat <<EOF
次にやること:
  1. 電源を切り、USB メモリを抜きます（右上のメニュー → 電源オフ）。
  2. LAN ケーブルはつないだまま、電源を入れます。
  3. Windows が起動してしまう場合は、BIOS の起動順位で「HAOS」か内蔵ディスクを一番上にします。
  4. 5〜20分ほど待ってから、ほかのパソコンかスマホで http://homeassistant.local:8123 を開きます。
EOF
