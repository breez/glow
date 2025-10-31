cd build/app/outputs/flutter-apk
for f in app-*-release.apk; do
  abi=$(echo "$f" | sed -E 's/app-(.*)-release\.apk/\1/')
  mv "$f" "glow-0.1.0-1-release-${abi}-$(date +%Y%m%d).apk"
done
