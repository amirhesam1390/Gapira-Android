#!/usr/bin/env bash

set +e
ROOT="/opt/nava-android"
cd "$ROOT" || exit 1

OUT="/tmp/gapira_brand_report.txt"
: > "$OUT"

{
    echo "======================================"
    echo "       GAPIRA BRAND AUDIT"
    echo "======================================"
    echo "Project: $ROOT"
    echo "Date: $(date)"
    
    echo
    echo "========== 1. APP MANIFEST =========="
    find TMessagesProj TMessagesProj_AppStandalone \
      -name AndroidManifest.xml -type f 2>/dev/null |
    while read -r f; do
        echo
        echo "--- $f ---"
        grep -nE 'application|activity|android:label|android:icon|roundIcon|logo|splash' "$f"
    done

    echo
    echo "========== 2. APP NAME / STRINGS =========="
    grep -RniE 'app_name|Telegram|telegram' \
      TMessagesProj/src/main/res/values \
      TMessagesProj_AppStandalone/src/main/res/values \
      --include="strings.xml" 2>/dev/null

    echo
    echo "========== 3. LAUNCHER ICON FILES =========="
    find TMessagesProj/src/main/res \
      TMessagesProj_AppStandalone/src/main/res \
      -type f 2>/dev/null |
    grep -Ei '/(mipmap|drawable)[^/]*/.*(launcher|ic_launcher|icon|logo|gapira)' |
    sort

    echo
    echo "========== 4. ADAPTIVE ICON XML =========="
    find TMessagesProj TMessagesProj_AppStandalone \
      -type f \( -name "*.xml" \) \
      -path "*/res/*" 2>/dev/null |
    while read -r f; do
        if grep -qiE 'foreground|background|monochrome|ic_launcher|gapira_logo' "$f"; then
            echo
            echo "--- $f ---"
            grep -niE 'foreground|background|monochrome|ic_launcher|gapira_logo' "$f"
        fi
    done

    echo
    echo "========== 5. SPLASH RESOURCES =========="
    find TMessagesProj/src/main/res \
      TMessagesProj_AppStandalone/src/main/res \
      -type f 2>/dev/null |
    grep -Ei 'splash|gapira_logo|launch' |
    sort

    echo
    echo "========== 6. VISIBLE TELEGRAM REFERENCES =========="
    for d in \
      TMessagesProj/src/main/res \
      TMessagesProj_AppStandalone/src/main/res \
      TMessagesProj/src/main/java \
      TMessagesProj_AppStandalone/src/main/java
    do
        [ -d "$d" ] || continue
        grep -RniE 'Telegram|telegram' "$d" \
          --include="*.xml" \
          --include="*.java" \
          --include="*.kt" \
          --include="*.json" 2>/dev/null
    done | head -250

    echo
    echo "========== 7. GAPIRA BRAND REFERENCES =========="
    grep -Rni 'Gapira\|gapira' \
      TMessagesProj/src/main \
      TMessagesProj_AppStandalone/src/main \
      --include="*.xml" \
      --include="*.java" \
      --include="*.kt" 2>/dev/null | head -150

    echo
    echo "========== 8. IMAGE RESOURCE DIMENSIONS =========="
    find TMessagesProj/src/main/res \
      TMessagesProj_AppStandalone/src/main/res \
      -type f 2>/dev/null |
    grep -Ei 'launcher|icon|logo|gapira' |
    while read -r f; do
        file "$f" 2>/dev/null
    done

    echo
    echo "========== 9. GIT STATUS =========="
    git status --short
    echo
    echo "========== 10. CURRENT COMMIT =========="
    git log -1 --oneline

    echo
    echo "========== AUDIT FINISHED =========="
} | tee "$OUT"

echo
echo "REPORT SAVED: $OUT"
