#!/bin/bash
#
# install.sh — bootstrap a dev box for Claude Code work.
#
# Single-file, self-contained: upload just this file to a server and run
# it. Core install steps (apt, gh, NVM/Node, Claude Code CLI) need nothing
# else. The one extra resource (starter CLAUDE.md template) is pulled at
# runtime from https://github.com/imwebdev/claude-installer — nothing else
# needs to be uploaded alongside this script.
#
# Usage:
#   ./install.sh [options]
#   curl -fsSL https://raw.githubusercontent.com/imwebdev/claude-installer/main/install.sh | bash
#
# Options:
#   --force            Reinstall steps even if already present
#   --skip-node        Skip NVM/Node/npm setup
#   --skip-claude      Skip Claude Code CLI install
#   --skip-extras      Skip gh/ripgrep/fd/jq extras
#   --skip-claude-md   Skip starter CLAUDE.md scaffold
#   --project-dir=DIR  Where to scaffold CLAUDE.md (default: cwd)
#   -h, --help         Show this help
#
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/imwebdev/claude-installer/main"

# ---------- output helpers ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_status()  { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

trap 'print_error "Failed at line $LINENO. Re-run with the same flags to resume — steps are idempotent."' ERR

# ---------- flags ----------
FORCE=false
SKIP_NODE=false
SKIP_CLAUDE=false
SKIP_EXTRAS=false
SKIP_CLAUDE_MD=false
PROJECT_DIR="$(pwd)"

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --skip-node) SKIP_NODE=true ;;
        --skip-claude) SKIP_CLAUDE=true ;;
        --skip-extras) SKIP_EXTRAS=true ;;
        --skip-claude-md) SKIP_CLAUDE_MD=true ;;
        --project-dir=*) PROJECT_DIR="${arg#*=}" ;;
        -h|--help)
            sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg (use -h for help)"
            exit 1
            ;;
    esac
done

echo "🚀 Claude Code dev box setup"
echo ""

# ---------- 1. OS check ----------
if ! command -v apt >/dev/null 2>&1; then
    print_error "This script targets apt-based distros (Ubuntu/Debian). apt not found."
    exit 1
fi
OS_DESC="$(lsb_release -d 2>/dev/null | cut -f2 || echo 'unknown apt-based distro')"
print_status "📍 Detected: $OS_DESC"

# ---------- 2. apt base deps ----------
print_status "📦 Updating apt and installing base dependencies..."
sudo apt update
sudo apt install -y build-essential curl git wget ca-certificates gnupg lsb-release unzip
print_success "Base dependencies installed"

# ---------- 3. extras: gh, ripgrep, fd, jq ----------
if [ "$SKIP_EXTRAS" = false ]; then
    print_status "🧰 Installing extras (gh, ripgrep, fd-find, jq)..."

    if ! command -v gh >/dev/null 2>&1 || [ "$FORCE" = true ]; then
        if [ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
                | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt update
        fi
        sudo apt install -y gh
        print_success "gh CLI installed ($(gh --version | head -1))"
    else
        print_success "gh CLI already present ($(gh --version | head -1))"
    fi

    sudo apt install -y ripgrep fd-find jq
    print_success "ripgrep, fd-find, jq installed"
else
    print_warning "Skipping extras (--skip-extras)"
fi

# ---------- 4. NVM + Node ----------
if [ "$SKIP_NODE" = false ]; then
    export NVM_DIR="$HOME/.nvm"

    if [ ! -d "$NVM_DIR" ] || [ "$FORCE" = true ]; then
        print_status "📥 Installing NVM..."
        [ -d "$NVM_DIR" ] && rm -rf "$NVM_DIR"

        NVM_LATEST_TAG="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest 2>/dev/null \
            | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || true)"
        NVM_LATEST_TAG="${NVM_LATEST_TAG:-v0.40.1}"  # fallback if GitHub API is rate-limited
        print_status "   using NVM $NVM_LATEST_TAG"

        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_TAG}/install.sh" | bash
        print_success "NVM installed"
    else
        print_success "NVM already installed, skipping (use --force to reinstall)"
    fi

    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    print_status "🟢 Installing Node.js LTS..."
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use --lts

    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_success "Node.js $NODE_VERSION installed"

    print_status "📦 Updating npm to latest..."
    npm install -g npm@latest
    print_success "npm updated to $(npm --version)"

    # idempotent shell profile block
    PROFILE_FILE="$HOME/.bashrc"
    if ! grep -q '# NVM Configuration' "$PROFILE_FILE" 2>/dev/null; then
        {
            echo ""
            echo "# NVM Configuration"
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
        } >> "$PROFILE_FILE"
        print_success "NVM block added to $PROFILE_FILE"
    else
        print_success "NVM block already in $PROFILE_FILE, skipping"
    fi
else
    print_warning "Skipping Node/npm setup (--skip-node)"
fi

# ---------- 5. Claude Code CLI ----------
if [ "$SKIP_CLAUDE" = false ]; then
    print_status "🧠 Installing Claude Code CLI..."

    if command -v claude >/dev/null 2>&1 && [ "$FORCE" = false ]; then
        print_success "Claude CLI already installed ($(claude --version 2>/dev/null || echo 'version unknown')), skipping"
    else
        # Prefer Anthropic's native installer (no Node dependency, self-updating).
        # Falls back to npm global install if it's unavailable.
        if curl -fsSL https://claude.ai/install.sh | bash; then
            print_success "Claude Code CLI installed via native installer"
        elif [ "$SKIP_NODE" = false ] && command -v npm >/dev/null 2>&1; then
            print_warning "Native installer failed, falling back to npm global install..."
            npm install -g @anthropic-ai/claude-code
            print_success "Claude Code CLI installed via npm"
        else
            print_error "Could not install Claude Code CLI (native installer failed, npm unavailable)"
        fi
    fi

    # Ensure PATH picks up a fresh install in this shell before verifying.
    export PATH="$HOME/.local/bin:$PATH"

    if command -v claude >/dev/null 2>&1; then
        print_success "Claude CLI found: $(claude --version 2>/dev/null || echo 'installed')"
        claude migrate-installer 2>/dev/null || true
    else
        print_warning "Claude CLI not in PATH yet — it'll be available in a new terminal session"
    fi
else
    print_warning "Skipping Claude Code CLI (--skip-claude)"
fi

# ---------- 6. git identity ----------
if [ -z "$(git config --global user.name 2>/dev/null || true)" ] && [ -t 0 ]; then
    print_status "🔧 No global git user.name set."
    read -r -p "   Enter your name for git commits: " GIT_NAME
    [ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
fi
if [ -z "$(git config --global user.email 2>/dev/null || true)" ] && [ -t 0 ]; then
    read -r -p "   Enter your email for git commits: " GIT_EMAIL
    [ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
fi

# ---------- 7. starter CLAUDE.md (pulled from git — not bundled in this file) ----------
if [ "$SKIP_CLAUDE_MD" = false ]; then
    TARGET="$PROJECT_DIR/CLAUDE.md"

    if [ -f "$TARGET" ] && [ "$FORCE" = false ]; then
        print_warning "CLAUDE.md already exists at $TARGET, skipping (use --force to overwrite)"
    else
        print_status "📄 Fetching starter CLAUDE.md template..."
        if curl -fsSL "$REPO_RAW_BASE/templates/CLAUDE.md" -o "$TARGET"; then
            print_success "Starter CLAUDE.md written to $TARGET"
        else
            print_warning "Could not fetch template from $REPO_RAW_BASE, skipping CLAUDE.md scaffold"
        fi
    fi
else
    print_warning "Skipping CLAUDE.md scaffold (--skip-claude-md)"
fi

# ---------- 8. summary ----------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 OS:      $OS_DESC"
[ "$SKIP_NODE" = false ] && echo "🟢 Node:    $(node --version 2>/dev/null || echo 'n/a')"
[ "$SKIP_NODE" = false ] && echo "📦 npm:     $(npm --version 2>/dev/null || echo 'n/a')"
echo "🧠 Claude:  $(command -v claude >/dev/null 2>&1 && echo "$(claude --version 2>/dev/null || echo installed)" || echo 'not in PATH yet')"
[ "$SKIP_EXTRAS" = false ] && echo "🐙 gh:      $(gh --version 2>/dev/null | head -1 || echo 'n/a')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Open a NEW terminal (or: source ~/.bashrc)"
echo "   2. Run: claude doctor"
echo "   3. Run: gh auth login          (if you installed gh)"
echo "   4. Review/edit CLAUDE.md in your project before you start"
echo "   5. cd your-project && claude"
echo ""
