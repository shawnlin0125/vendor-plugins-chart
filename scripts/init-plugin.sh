#!/bin/bash
# init-plugin.sh <plugin_name>
# Creates a new vendor plugin repo from the template and triggers chart sync.
set -e

PLUGIN_NAME=$1

# ── Guard ──
if [ -z "${PLUGIN_NAME}" ]; then
  echo "Usage: ./init-plugin.sh <plugin_name>"
  exit 1
fi

if [ "${PLUGIN_NAME}" = "template" ]; then
  echo "ERROR: cannot use 'template' as plugin name"
  exit 1
fi

if [ -z "${GH_TOKEN}" ]; then
  echo "ERROR: GH_TOKEN not set"
  exit 1
fi

REPO_NAME="vendor-plugin-${PLUGIN_NAME}"
echo "🚀 Creating ${REPO_NAME} from template..."

# ── Step 1: Create repo from template ──
gh repo create "shawnlin0125/${REPO_NAME}" \
  --public \
  --template shawnlin0125/vendor-plugin-template \
  --description "Vendor plugin: ${PLUGIN_NAME}" 2>&1

echo "✅ Repo created: https://github.com/shawnlin0125/${REPO_NAME}"

# ── Step 2: Clone and initialize ──
TMP_DIR=$(mktemp -d)
cd "${TMP_DIR}"

gh repo clone "shawnlin0125/${REPO_NAME}"
cd "${REPO_NAME}"

# Set the plugin name
echo "PLUGIN_NAME=${REPO_NAME}" >> .env

# Create development branch
git checkout -b development
git push origin development

# ── Step 3: Push initial commit ──
git add .env
git commit -m "chore: init plugin ${PLUGIN_NAME}"
git push origin development

# ── Step 4: Trigger chart scan via repository_dispatch ──
echo "⏳ Triggering chart scan..."
curl -s -X POST \
  -H "Authorization: bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/shawnlin0125/vendor-plugins-chart/dispatches" \
  -d "{\"event_type\": \"plugin-created\", \"client_payload\": {\"plugin\": \"${PLUGIN_NAME}\"}}"

echo "✅ Triggered chart scan. Argo CD will sync within ~2 min."
echo ""
echo "📋 Plugin ${PLUGIN_NAME} initialized!"
echo "   Repo: https://github.com/shawnlin0125/${REPO_NAME}"
echo "   Clone: ${TMP_DIR}/${REPO_NAME}"

# Cleanup
rm -rf "${TMP_DIR}"
