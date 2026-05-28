# Vendor Plugins Chart

Helm chart for deploying all vendor plugins via Argo CD. Auto-discovers plugins by scanning GitHub repos.

## Structure

```
vendor-plugins-chart/
├── Chart.yaml
├── values.yaml              # Auto-maintained by scan-plugins.sh
├── scan-plugins.sh          # Discovers vendor-plugin-* repos from GitHub
├── templates/
│   ├── namespace.yaml
│   ├── _helpers.tpl
│   └── plugin-deployment.yaml  # Loop over .Values.plugins
└── .github/workflows/
    └── scan-sync.yaml
```

## How It Works

1. **Plugin repo created** via init-plugin.sh (from template).
2. **scan-sync workflow** runs (manual or scheduled), calls `scan-plugins.sh`.
3. `scan-plugins.sh` queries GitHub API for repos matching `vendor-plugin-*`.
4. **values.yaml** is updated with the new plugin entry.
5. **Argo CD** detects the change in the Helm chart and syncs.
6. New Deployment + Service are created in `vendor-staging` namespace.

## Manual Update

```bash
# Trigger scan manually
gh workflow run scan-and-sync --repo shawnlin0125/vendor-plugins-chart
```

## Development

```bash
# Render templates locally
helm template vendor-plugins . --values values.yaml

# Check syntax
helm lint .
```
