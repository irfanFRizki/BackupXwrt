#!/bin/sh
# backupwrt-notify.sh — Kirim notifikasi Telegram setelah backup

TG_TOKEN=$(uci get backupwrt.telegram.bot_token 2>/dev/null)
TG_CHAT=$(uci get backupwrt.telegram.chat_id 2>/dev/null)
TG_ENABLED=$(uci get backupwrt.telegram.enabled 2>/dev/null)

[ "$TG_ENABLED" != "1" ] && exit 0
[ -z "$TG_TOKEN" ] && { echo "Telegram: bot_token belum diisi"; exit 1; }
[ -z "$TG_CHAT"  ] && { echo "Telegram: chat_id belum diisi";  exit 1; }

GH_OWNER=$(uci get backupwrt.github.owner   2>/dev/null || echo "?")
GH_REPO=$(uci get backupwrt.github.repo     2>/dev/null || echo "?")
GH_BRANCH=$(uci get backupwrt.github.branch 2>/dev/null || echo "main")
HOSTNAME=$(cat /proc/sys/kernel/hostname 2>/dev/null || echo "OpenWrt")
UPTIME=$(uptime 2>/dev/null | sed 's/.*up //' | cut -d',' -f1 | xargs)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date)

# Parse parameter: via CGI (QUERY_STRING) atau langsung (argv)
if [ -n "$QUERY_STRING" ]; then
    OK=$(echo    "$QUERY_STRING" | grep -oE 'ok=[0-9]+'    | cut -d= -f2)
    FAIL=$(echo  "$QUERY_STRING" | grep -oE 'fail=[0-9]+'  | cut -d= -f2)
    TOTAL=$(echo "$QUERY_STRING" | grep -oE 'total=[0-9]+' | cut -d= -f2)
else
    OK="${1:-0}"; FAIL="${2:-0}"; TOTAL="${3:-0}"
fi
OK="${OK:-0}"; FAIL="${FAIL:-0}"; TOTAL="${TOTAL:-0}"

if   [ "$FAIL" = "0" ] && [ "$OK" != "0" ]; then STATUS="Semua sukses"
elif [ "$OK"   = "0" ];                      then STATUS="Semua gagal"
else                                              STATUS="Sebagian gagal"
fi

# Tulis pesan ke tempfile (menghindari masalah multiline di busybox ash)
TMPFILE=$(mktemp /tmp/tg_msg.XXXXXX)
cat > "$TMPFILE" << EOF
$STATUS - BackupWRT

Total    : $TOTAL
Sukses   : $OK
Gagal    : $FAIL

Repo     : $GH_OWNER/$GH_REPO @ $GH_BRANCH
Host     : $HOSTNAME
Waktu    : $TIMESTAMP
Uptime   : $UPTIME
EOF

# Kirim ke Telegram — gunakan -F "text=<file" (stabil untuk multiline busybox)
RESULT=$(curl -s --max-time 15 \
    -X POST \
    "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -F "chat_id=${TG_CHAT}" \
    -F "text=<${TMPFILE}" 2>&1)
rm -f "$TMPFILE"

if echo "$RESULT" | grep -q '"ok":true'; then
    echo "Notifikasi Telegram terkirim"
else
    echo "Gagal kirim Telegram: $RESULT" >&2
    exit 1
fi

[ -n "$REQUEST_METHOD" ] && echo "ok"
exit 0
