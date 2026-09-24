# claude-installer

Bootstrap a fresh server for Claude Code work: build deps, `gh` CLI, NVM + Node LTS, and the Claude Code CLI itself. Single self-contained script — nothing else needs to be uploaded. Auto-detects the package manager, so the same script works on:

- Ubuntu/Debian (`apt`)
- RHEL/CentOS/Fedora/Amazon Linux (`dnf` or `yum`)
- Alpine (`apk`)
- macOS (`brew`)

## Run it on a server

No copy-paste, no upload — run straight from this repo:

```bash
curl -fsSL https://raw.githubusercontent.com/imwebdev/claude-installer/main/install.sh | bash
```

Prefer to read it before running it (recommended for any curl-pipe-bash on a server you care about):

```bash
curl -fsSL https://raw.githubusercontent.com/imwebdev/claude-installer/main/install.sh -o install.sh
less install.sh          # review
chmod +x install.sh
./install.sh
```

## Options

```
--force            Reinstall steps even if already present
--skip-node        Skip NVM/Node/npm setup
--skip-claude      Skip Claude Code CLI install
--skip-extras      Skip gh/ripgrep/fd/jq extras
--skip-claude-md   Skip starter CLAUDE.md scaffold
--project-dir=DIR  Where to scaffold CLAUDE.md (default: cwd)
```

Example: install just Claude Code CLI on a box that already has Node:

```bash
curl -fsSL https://raw.githubusercontent.com/imwebdev/claude-installer/main/install.sh | bash -s -- --skip-node --skip-extras
```

## What it does

1. Installs apt base deps (`build-essential curl git wget ca-certificates gnupg lsb-release unzip`)
2. Installs `gh`, `ripgrep`, `fd-find`, `jq`
3. Installs NVM (latest release, resolved dynamically) + Node LTS, updates npm
4. Installs Claude Code CLI via Anthropic's native installer (falls back to `npm install -g @anthropic-ai/claude-code` if that fails)
5. Prompts for git `user.name`/`user.email` if unset
6. Fetches `templates/CLAUDE.md` from this repo into the target project dir, if one isn't already there

Every step checks whether it's already done and skips it — safe to re-run after a partial failure. Use `--force` to redo a step anyway.

## Extending

`templates/CLAUDE.md` is the only resource `install.sh` pulls from this repo at runtime (via raw.githubusercontent.com — no git clone, no auth needed since the repo is public). Add more files under this repo and reference them the same way if you want the installer to scaffold more than just a CLAUDE.md.
