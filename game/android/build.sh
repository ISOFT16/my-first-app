#!/usr/bin/env bash
# Builds the Android APK of the game with plain SDK tools (no Gradle).
# Needs ANDROID_HOME (build-tools + a platform) and a JDK. Output: out/NochnoyUgon.apk
set -euo pipefail
cd "$(dirname "$0")"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:?set ANDROID_HOME}}"
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
PLAT="$(ls "$SDK"/platforms/android-*/android.jar | sort -V | tail -1)"
echo "build-tools: $BT"; echo "platform: $PLAT"

rm -rf out; mkdir -p out/assets out/classes out/dex
{
  printf '%s' '<!doctype html><html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no"><style>body{margin:0;font:14px sans-serif}</style></head><body>'
  cat ../index.html
  printf '%s' '</body></html>'
} > out/assets/index.html

"$BT/aapt2" compile --dir res -o out/res.zip
"$BT/aapt2" link -o out/base.apk -I "$PLAT" --manifest AndroidManifest.xml -A out/assets \
  --min-sdk-version 23 --target-sdk-version 34 \
  --version-code "${VERSION_CODE:-1}" --version-name "1.${VERSION_CODE:-0}" out/res.zip
javac --release 11 -cp "$PLAT" -d out/classes $(find src -name '*.java')
"$BT/d8" --release --lib "$PLAT" --min-api 23 --output out/dex $(find out/classes -name '*.class')
zip -q -j out/base.apk out/dex/classes.dex
"$BT/zipalign" -f 4 out/base.apk out/aligned.apk

KS="${KEYSTORE:-out/build.keystore}"
if [ ! -f "$KS" ]; then
  keytool -genkeypair -keystore "$KS" -storepass android -keypass android -alias game \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Night Heist"
fi
"$BT/apksigner" sign --ks "$KS" --ks-pass pass:android --key-pass pass:android \
  --out out/NochnoyUgon.apk out/aligned.apk
"$BT/apksigner" verify --verbose out/NochnoyUgon.apk | head -5
ls -l out/NochnoyUgon.apk
