#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  بازگردانی پنل‌های سنایی — نرم‌افزار از ریپوی اصلی، داده از بکاپ
#
#  curl -fsSL https://raw.githubusercontent.com/arshiyaazizi/xui-backup/main/install.sh | bash
#
#  🔹 نرم‌افزار (x-ui / داکر / acme.sh) از ریپوهای رسمی نصب میشه
#  🔹 فقط «دیتابیس + فایل‌ها + گواهی‌ها» از بکاپ میاد
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO="arshiyaazizi/xui-backup"
# ⚠️ توکن نباید داخل فایل باشه — گیت‌هاب push حاوی رمز رو رد می‌کنه
#    (secret scanning push protection). از متغیر محیطی میاد:
TOK="${GHTOKEN:-}"
if [ -z "$TOK" ]; then
  echo "❌ توکن گیت‌هاب لازمه. اینطوری اجرا کن:"
  echo
  echo "   GHTOKEN=<توکنت> bash -c 'curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash'"
  echo
  exit 1
fi
IMG="ghcr.io/mhsanaei/3x-ui:latest"
ACME_HOME="/root/.acme.sh"

c_ok()   { printf '  \033[32m✅\033[0m %s\n' "$*"; }
c_info() { printf '  \033[36m⏳\033[0m %s\n' "$*"; }
c_err()  { printf '  \033[31m❌\033[0m %s\n' "$*"; }

[ "$(id -u)" = "0" ] || { c_err "با sudo اجرا کن"; exit 1; }
export DEBIAN_FRONTEND=noninteractive

echo "══ ۱) نصب نرم‌افزار از ریپوهای رسمی ══"

# ── ۱.۱) پیش‌نیازها ───────────────────────────────────────────
c_info "پیش‌نیازها (apt رسمی اوبونتو) ..."
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq curl tar zstd ca-certificates python3 cron >/dev/null 2>&1 || true
c_ok "curl, tar, zstd, python3"

# ── ۱.۲) داکر — از get.docker.com رسمی ────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  c_info "نصب داکر (get.docker.com) ..."
  curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
  systemctl enable --now docker >/dev/null 2>&1 || true
  c_ok "داکر نصب شد"
else
  c_ok "داکر از قبل نصب است"
fi

# ── ۱.۳) x-ui لوکال — نسخه **۳.۳.۱** (پین‌شده، اپدیت نشه) ─────
# ⚠️ کاربر تأکید کرده: پنل لوکال حتماً 3.3.1 باقی بمونه — آپدیت نکن
XV="3.3.1"
c_info "دانلود x-ui نسخه $XV از MHSanaei/3x-ui (پین‌شده) ..."
TMP=$(mktemp -d); cd "$TMP"
curl -fsSL "https://github.com/MHSanaei/3x-ui/releases/download/v$XV/x-ui-linux-amd64.tar.gz" -o xui.tgz \
  || { c_err "دانلود نسخه $XV ممکن نشد"; exit 1; }
mkdir -p /usr/local/x-ui
tar -xzf xui.tgz 2>/dev/null || true
[ -f x-ui/x-ui ] && { cp -f x-ui/x-ui /usr/local/x-ui/x-ui; chmod +x /usr/local/x-ui/x-ui; }
cp -af x-ui/bin /usr/local/x-ui/ 2>/dev/null || true
rm -rf x-ui xui.tgz
[ -x /usr/local/x-ui/x-ui ] && c_ok "x-ui $XV نصب شد (بدون آپدیت)" || { c_err "نصب x-ui شکست خورد"; exit 1; }

# ── ۱.۴) acme.sh — از ریپوی رسمی Neilpang/acme.sh ─────────────
if [ ! -x "$ACME_HOME/acme.sh" ]; then
  c_info "نصب acme.sh (get.acme.sh) ..."
  curl -fsSL https://get.acme.sh | sh -s email=admin@localhost >/dev/null 2>&1 || true
  [ -x "$ACME_HOME/acme.sh" ] && c_ok "acme.sh نصب شد" || c_err "acme.sh نصب نشد (ادامه میدم)"
else
  c_ok "acme.sh از قبل نصب است"
fi

# ═══════════════════════════════════════════════════════════════
echo
echo "══ ۲) بازگردانی داده از بکاپ ══"

# ── ۲.۱) دانلود آرشیو بکاپ ───────────────────────────────────
c_info "دانلود بکاپ از گیت‌هاب ..."
cd "$TMP"
curl -fsSL -H "Authorization: token $TOK" \
  "https://raw.githubusercontent.com/$REPO/main/xui-snapshot.tar.zst" -o snap.tar.zst
zstd -q -d snap.tar.zst -o snap.tar && tar --numeric-owner -xf snap.tar
c_ok "بکاپ باز شد ($(du -h snap.tar.zst | cut -f1))"
MANIFEST="$TMP/meta/MANIFEST.txt"
[ -f "$MANIFEST" ] && { c_ok "MANIFEST:"; sed 's/^/      /' "$MANIFEST"; }

# ── ۲.۲) دیتابیس + فایل‌های پنل لوکال ─────────────────────────
c_info "دیتابیس پنل لوکال ..."
mkdir -p /etc/x-ui
if [ -d "$TMP/local-panel" ]; then
  systemctl stop x-ui 2>/dev/null || true
  find "$TMP/local-panel" -maxdepth 1 -type f ! -name 'x-ui.service' ! -name 'etc-default-x-ui' \
       -exec cp -af {} /etc/x-ui/ \;
  [ -f "$TMP/local-panel/x-ui.service" ]     && cp -f "$TMP/local-panel/x-ui.service"     /etc/systemd/system/x-ui.service
  [ -f "$TMP/local-panel/etc-default-x-ui" ] && cp -f "$TMP/local-panel/etc-default-x-ui" /etc/default/x-ui
  c_ok "دیتابیس + unit پنل لوکال"
fi

# ── ۲.۳) گواهی‌ها ─────────────────────────────────────────────
c_info "گواهی‌ها ..."
mkdir -p /root/cert
[ -d "$TMP/certs" ] && cp -af "$TMP/certs/." /root/cert/ 2>/dev/null || true
if [ -d "$TMP/acme" ]; then
  cp -af "$TMP/acme/." "$ACME_HOME/" 2>/dev/null || true
  c_ok "گواهی‌ها + اکانت acme بازگردانی شد"
fi

# ── ۲.۴) دیتابیس + گواهی پنل داکر ─────────────────────────────
c_info "دیتابیس پنل داکر ..."
mkdir -p /root/sanaei-second/db /root/sanaei-second/cert /root/sanaei-second/container-certs
if [ -d "$TMP/docker-panel" ]; then
  cp -af "$TMP/docker-panel/db/."              /root/sanaei-second/db/ 2>/dev/null || true
  cp -af "$TMP/docker-panel/cert/."            /root/sanaei-second/cert/ 2>/dev/null || true
  cp -af "$TMP/docker-panel/container-certs/." /root/sanaei-second/container-certs/ 2>/dev/null || true
  c_ok "دیتابیس + گواهی پنل داکر"
fi
touch /root/sanaei-second/container-certs/fullchain.cer /root/sanaei-second/container-certs/privkey.key

# ═══════════════════════════════════════════════════════════════
echo
echo "══ ۳) بالا آوردن سرویس‌ها ══"
echo
c_info "پنل لوکال ..."
systemctl daemon-reload
systemctl enable --now x-ui >/dev/null 2>&1 || systemctl restart x-ui
c_ok "x-ui (لوکال) فعال"
# تأیید نسخه پین‌شده
INST=$(/usr/local/x-ui/x-ui -v 2>/dev/null | head -1 | tr -d ' v')
if [ "$INST" = "3.3.1" ]; then
  c_ok "نسخه پنل لوکال: 3.3.1 ✅ (پین‌شده)"
else
  c_err "نسخه پنل لوکال $INST هست — باید 3.3.1 باشه!"
fi

c_info "پنل داکر ..."
docker rm -f 3xui_app >/dev/null 2>&1 || true
docker pull -q "$IMG" >/dev/null 2>&1 || true
docker run -d --name 3xui_app --restart unless-stopped \
  -p 2053:2053 -p 2097:2097 -p 8142:8142 \
  -v /root/sanaei-second/db/:/etc/x-ui:rw \
  -v /root/sanaei-second/cert/:/root/cert:rw \
  -v /root/sanaei-second/container-certs/fullchain.cer:/root/fullchain.cer:rw \
  -v /root/sanaei-second/container-certs/privkey.key:/root/privkey.key:rw \
  "$IMG" >/dev/null 2>&1
c_ok "3xui_app (داکر) فعال"

# کرون تمدید گواهی
( crontab -l 2>/dev/null | grep -v 'acme.sh --cron'
  echo "39 3,9,15,21 * * * \"$ACME_HOME\"/acme.sh --cron --home \"$ACME_HOME\" > /dev/null"
) | crontab - 2>/dev/null || true
c_ok "کرون تمدید خودکار گواهی"

# ═══════════════════════════════════════════════════════════════
sleep 6
echo
echo "══════════════════  نتیجه  ══════════════════"
for s in x-ui docker; do printf "  %-10s %s\n" "$s:" "$(systemctl is-active $s 2>/dev/null)"; done
printf "  %-10s %s\n" "3xui_app:" "$(docker inspect 3xui_app --format '{{.State.Status}}' 2>/dev/null || echo not-running)"
echo
echo "  پورت‌های گوش‌دهنده:"
ss -tlnp 2>/dev/null | grep -E ':(3399|2053|2097|8142|8080)\b' | awk '{print "    "$4}' | sort -u
echo
echo "  ✅ نصب کامل شد."
echo "  🔑 پنل لوکال : https://<IP>:3399/iXDXsPtDsiQyj2ftDY/"
echo "  🔑 پنل داکر  : https://<IP>:2053/"
echo "═══════════════════════════════════════════════"
rm -rf "$TMP"
