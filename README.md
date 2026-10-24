# M3TAL Plugins Repository (`m3tal-plugins`)

This repository contains all official and community plugins for the **M3TAL Core** platform (`jakej985-rgb/m3tal-core`).

## 1. Architectural Principles

- **Zero Core Footprint**: `m3tal-core` contains zero plugin-specific UI components, API endpoints, or models. It acts solely as the Host Supervisor and Dynamic UI mount point.
- **Top-Level Plugin Folders**: Every plugin lives in its own top-level directory directly under this repository root (e.g. `docker-monitor/`, `ai-engine/`, `smart-disk/`). There is no intermediate wrapper folder.
- **Complete Self-Containment**: All backend code, frontend UI assets, manifest (`plugin.yaml`), configuration schema, and build rules live strictly within the plugin's own folder.
- **Canonical Process Identity**: Every running plugin subprocess identifies as `m3tal-<plugin-name>` (e.g. `m3tal-docker`, `m3tal-ai`).
- **Debian Packaging & Central Signing**: All `.deb` packages (`m3tal-plugin-<name>_<version>_amd64.deb`) are built in this repository and dispatched to `jakej985-rgb/m3tal-apt-key` for official GPG signing and APT repository indexing.

---

## 2. Repository Layout

```text
m3tal-plugins/
├── <plugin-name>/               # E.g. docker-monitor, smart-disk, ai-engine
│   ├── .agents/
│   │   └── agents/
│   │       └── plugin-maintainer/
│   │           └── agent.md     # In-repo custodian agent for this plugin
│   ├── plugin.yaml              # Standard manifest (apiVersion: m3tal.io/v1alpha1)
│   ├── Makefile                 # Plugin-specific build & test targets
│   ├── bin/                     # Backend binary or executable entrypoint
│   ├── ui/
│   │   └── dist/
│   │       ├── index.html       # Web UI micro-bundle mounted at /plugins/<name>/
│   │       └── assets/          # Relative static assets
│   ├── config/
│   │   └── config.schema.json   # Settings JSON schema
│   └── src/                     # Backend source code (Go, Python, Shell, Rust)
├── scripts/
│   └── build-plugin-deb.sh      # Central Debian packaging script
├── .github/
│   └── workflows/
│       └── build-and-publish-deb.yml # CI builder & APT repository dispatcher
└── Makefile                     # Monorepo build orchestrator
```

---

## 3. Developing a Plugin

### Scaffolding a New Plugin
Use the `plugin-author` subagent from `m3tal-core`:
```bash
# In M3tal-core chat:
# "Scaffold a new plugin named 'smart-disk' in m3tal-plugins"
```
The agent automatically scaffolds the directory structure, JSON-RPC 2.0 loop, static UI bundle, and embeds `.agents/agents/plugin-maintainer/agent.md`.

### Building Plugins
```bash
# Build a single plugin:
make build PLUGIN=docker-monitor

# Build all plugins:
make build-all

# Test a single plugin:
make test PLUGIN=docker-monitor
```

### Packaging into Debian (`.deb`)
```bash
./scripts/build-plugin-deb.sh docker-monitor
```
Generates `m3tal-plugin-docker-monitor_<version>_amd64.deb`.

---

## 4. Release & APT Ingestion Pipeline

1. When a change or tag is pushed to `<plugin-name>/`, `.github/workflows/build-and-publish-deb.yml` builds the `.deb`.
2. A GitHub Release is created with the `.deb` asset.
3. The workflow dispatches a `publish-deb` event to `jakej985-rgb/m3tal-apt-key`:
   ```json
   {
     "package_id": "m3tal-plugin-<name>",
     "version": "<version>",
     "deb_url": "https://github.com/jakej985-rgb/m3tal-plugins/releases/download/v<version>/m3tal-plugin-<name>_<version>_amd64.deb",
     "allow_replace": true
   }
   ```
4. `m3tal-apt-key` signs the package with the official M3TAL GPG key and updates the APT pool, making it available via:
   ```bash
   sudo apt update
   sudo apt install m3tal-plugin-<name>
   ```
