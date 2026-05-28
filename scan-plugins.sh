#!/bin/bash
# scan-plugins.sh — 掃描 GitHub repos (shawnlin0125/vendor-plugin-*) → 更新 values.yaml
# Adapted from GitLab → GitHub version
set -e

if [ -z "$GH_TOKEN" ]; then
  echo "ERROR: GH_TOKEN not set"
  exit 1
fi

# ── 取得所有 vendor-plugin repos（排除 template） ──
echo "Scanning GitHub for vendor-plugin repos..."

PLUGINS=$(gh repo list shawnlin0125 \
  --limit 100 \
  --json name \
  --jq '.[] | select(.name | startswith("vendor-plugin-")) | select(.name != "vendor-plugin-template") | .name | sub("^vendor-plugin-"; "")' 2>/dev/null)

if [ -z "$PLUGINS" ]; then
  echo "No vendor plugins found (excluding template)."
  PLUGINS=""
fi

# ── 更新 values.yaml ──
cat > values.yaml << 'HEADER'
# 此檔案由 scan-plugins.sh 自動維護，勿手動編輯 plugins 清單
# GitHub Repo: https://github.com/shawnlin0125/vendor-plugins-chart

namespace: vendor-staging

plugins:
HEADER

for PLUGIN in $PLUGINS; do
  cat >> values.yaml << EOF
  - name: ${PLUGIN}
    image: ghcr.io/shawnlin0125/vendor-plugin-${PLUGIN}
    tag: latest
    port: 8080
EOF
done

cat >> values.yaml << 'FOOTER'

registry:
  server: ghcr.io
FOOTER

echo "values.yaml updated with $(echo $PLUGINS | wc -w | tr -d ' ') plugins."

# ── Git commit & push ──
git config user.email "ci@shawnlin.online"
git config user.name "CI Bot"

git add values.yaml
if ! git diff --staged --quiet; then
  git commit -m "chore: sync plugin list from GitHub repos [skip ci]"
  git push origin main
  echo "✅ values.yaml committed and pushed."
else
  echo "ℹ️  No changes to values.yaml."
fi
