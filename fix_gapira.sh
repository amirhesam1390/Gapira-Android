#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="/opt/nava-android"
XML="$PROJECT/TMessagesProj/src/main/res/values/strings.xml"

cd "$PROJECT"

echo "======================================"
echo "       GAPIRA ANDROID REPAIR"
echo "======================================"

# بررسی مسیر پروژه
if [[ ! -f "$XML" ]]; then
    echo "[ERROR] strings.xml پیدا نشد"
    exit 1
fi

# تهیه نسخه پشتیبان
BACKUP="$XML.backup.$(date +%Y%m%d_%H%M%S)"
cp "$XML" "$BACKUP"
echo "[OK] Backup: $BACKUP"

# اصلاح شناسه‌های داخلی منابع
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("TMessagesProj/src/main/res/values/strings.xml")
s = p.read_text(encoding="utf-8")

fixed = 0

def fix_name(match):
    global fixed
    value = match.group(2)
    new_value = value.replace("Gapira", "Telegram")
    if value != new_value:
        fixed += 1
    return match.group(1) + new_value + match.group(3)

s = re.sub(
    r'(\bname\s*=\s*")([^"]*)(")',
    fix_name,
    s
)

p.write_text(s, encoding="utf-8")
print(f"[OK] Resource identifiers repaired: {fixed}")
PY

# تست ساختار XML
echo
echo "[TEST 1] XML syntax"

python3 - <<'PY'
import xml.etree.ElementTree as ET
ET.parse("TMessagesProj/src/main/res/values/strings.xml")
print("[PASS] XML is valid")
PY

# تست شناسه‌های موردنیاز جاوا
echo
echo "[TEST 2] Required Android resources"

python3 - <<'PY'
import re
from pathlib import Path

xml = Path("TMessagesProj/src/main/res/values/strings.xml").read_text(
    encoding="utf-8"
)

required = [
    "TelegramFeaturesUrl",
    "TelegramVersion",
    "InviteToTelegramShort",
    "NewContactPhoneNotOnTelegram",
    "NewContactPhoneOnTelegram",
    "ClearTelegramCache",
    "TelegramCacheSize",
    "TelegramPremiumUserStatusCollectibleDialogTitle",
    "TelegramPremiumUserStatusDialogSubtitle",
    "TelegramPremiumUserStatusDialogTitle",
]

names = set(re.findall(r'<(?:string|plurals|string-array)\b[^>]*\bname="([^"]+)"', xml))

missing = [name for name in required if name not in names]

if missing:
    print("[FAIL] Missing resources:")
    for name in missing:
        print(" -", name)
    raise SystemExit(1)

print(f"[PASS] All {len(required)} required resources exist")
PY

# بررسی باقی نماندن شناسه Gapira
echo
echo "[TEST 3] Resource identifier integrity"

python3 - <<'PY'
import re
from pathlib import Path

xml = Path("TMessagesProj/src/main/res/values/strings.xml").read_text(
    encoding="utf-8"
)

names = re.findall(r'\bname="([^"]+)"', xml)
bad = [name for name in names if "Gapira" in name]

if bad:
    print("[FAIL] Invalid resource names:")
    for name in bad:
        print(" -", name)
    raise SystemExit(1)

print("[PASS] No Gapira resource identifiers remain")
PY

# بررسی حفظ نام نمایشی Gapira
echo
echo "[TEST 4] App branding"

if grep -q 'name="AppName">Gapira<' "$XML"; then
    echo "[PASS] AppName is Gapira"
else
    echo "[FAIL] AppName is not Gapira"
    exit 1
fi

# بررسی whitespace و خطاهای Git
echo
echo "[TEST 5] Git diff check"

git diff --check
echo "[PASS] Git diff check"

# بررسی تغییرات
echo
echo "======================================"
echo "          CHANGE SUMMARY"
echo "======================================"

git status --short
git diff --stat

# Commit و Push
echo
read -r -p "تمام تست‌ها موفق بودند. Commit و Push انجام شود؟ (yes/no): " answer

if [[ "$answer" != "yes" ]]; then
    echo "[STOP] تغییرات محلی باقی ماندند؛ Push انجام نشد."
    exit 0
fi

git add TMessagesProj/src/main/res/values/strings.xml

if git diff --cached --quiet; then
    echo "[INFO] تغییر جدیدی برای Commit وجود ندارد."
else
    git commit -m "Fix Gapira Android resource identifiers"
fi

git push origin master

echo
echo "======================================"
echo "[SUCCESS] Repair and Push completed"
echo "======================================"
echo "حالا GitHub Actions را اجرا کن:"
echo "https://github.com/amirhesam1390/Gapira-Android/actions"
