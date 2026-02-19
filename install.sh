#!/bin/sh
# ditch-vercel installer
# Usage: curl -fsSL https://raw.githubusercontent.com/umarmuhandis/ditch-vercel/main/install.sh | bash
# Flags: --uninstall  Remove installed files
#        --dry-run    Show what would be done without making changes
set -e

REPO="umarmuhandis/ditch-vercel"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Skill files to download
SKILL_FILES="
skills/ditch-vercel/SKILL.md
skills/ditch-vercel/frameworks/nextjs.md
skills/ditch-vercel/frameworks/astro.md
skills/ditch-vercel/frameworks/remix.md
skills/ditch-vercel/frameworks/sveltekit.md
skills/ditch-vercel/frameworks/nuxt.md
skills/ditch-vercel/frameworks/static.md
skills/ditch-vercel/targets/cloudflare.md
skills/ditch-vercel/targets/vps.md
"

ADAPTER_FILES="
AGENTS.md
adapters/cursor.mdc
adapters/windsurf.md
adapters/clinerules.md
"

# --- Flags ---
DRY_RUN=false
UNINSTALL=false
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --help|-h)
      echo "Usage: install.sh [--dry-run] [--uninstall]"
      echo ""
      echo "Installs the ditch-vercel skill into your project."
      echo "Run from your project root directory."
      echo ""
      echo "Flags:"
      echo "  --dry-run    Show what would be done without making changes"
      echo "  --uninstall  Remove installed ditch-vercel files"
      exit 0
      ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# --- Helpers ---
info()  { printf "\033[34m→\033[0m %s\n" "$1"; }
ok()    { printf "\033[32m✓\033[0m %s\n" "$1"; }
warn()  { printf "\033[33m!\033[0m %s\n" "$1"; }
err()   { printf "\033[31m✗\033[0m %s\n" "$1" >&2; }

download() {
  url="$1"
  dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
    # wget doesn't fail on 404 by default — validate the download
    if [ -f "$dest" ] && head -c 20 "$dest" | grep -qi '<!doctype\|<html'; then
      err "Download failed (got HTML error page): $url"
      rm -f "$dest"
      return 1
    fi
  else
    err "Neither curl nor wget found. Install one and retry."
    exit 1
  fi
}

# --- Agent detection ---
detect_agents() {
  agents=""

  # Claude Code
  if [ -d ".claude" ] || [ -f ".claude-plugin/plugin.json" ]; then
    agents="$agents claude-code"
  fi

  # Cursor
  if [ -d ".cursor" ] || [ -f ".cursorrules" ]; then
    agents="$agents cursor"
  fi

  # Windsurf
  if [ -d ".windsurf" ]; then
    agents="$agents windsurf"
  fi

  # Cline / Roo Code
  if [ -d ".clinerules" ] || [ -d ".roo" ]; then
    agents="$agents cline"
  fi

  # Codex / Copilot / any AGENTS.md consumer
  # Always install AGENTS.md — it's the universal standard
  agents="$agents agents-md"

  echo "$agents"
}

# --- Uninstall ---
if [ "$UNINSTALL" = true ]; then
  info "Uninstalling ditch-vercel..."

  all_files="$SKILL_FILES $ADAPTER_FILES"
  removed=0

  for f in $all_files; do
    if [ -f "$f" ]; then
      if [ "$DRY_RUN" = true ]; then
        info "Would remove: $f"
      else
        rm "$f"
        ok "Removed $f"
      fi
      removed=$((removed + 1))
    fi
  done

  # Clean up empty directories
  for dir in skills/ditch-vercel/frameworks skills/ditch-vercel/targets skills/ditch-vercel adapters; do
    if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
      if [ "$DRY_RUN" = true ]; then
        info "Would remove empty dir: $dir"
      else
        rmdir "$dir"
        ok "Removed empty dir: $dir"
      fi
    fi
  done

  if [ "$removed" -eq 0 ]; then
    warn "No ditch-vercel files found to remove."
  elif [ "$DRY_RUN" = true ]; then
    info "Dry run complete. No files were removed."
  else
    ok "ditch-vercel uninstalled."
  fi
  exit 0
fi

# --- Install ---
info "Installing ditch-vercel..."
echo ""

agents=$(detect_agents)
# Filter out agents-md for display (it's always installed, not a real agent)
display_agents=$(echo "$agents" | tr ' ' '\n' | grep -v '^$' | grep -v 'agents-md' | tr '\n' ' ')
if [ -n "$(echo "$display_agents" | tr -d ' ')" ]; then
  info "Detected agents:$(echo "$display_agents" | tr ' ' '\n' | grep -v '^$' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
else
  info "No specific agents detected. Installing universal AGENTS.md."
fi
echo ""

# Download skill files (always needed)
info "Downloading skill files..."
for f in $SKILL_FILES; do
  dir=$(dirname "$f")
  if [ "$DRY_RUN" = true ]; then
    info "Would create: $f"
  else
    mkdir -p "$dir"
    download "${BASE_URL}/${f}" "$f"
    ok "$f"
  fi
done
echo ""

# Install AGENTS.md (universal — works with Codex, Copilot, Gemini CLI, etc.)
info "Installing AGENTS.md (universal agent discovery)..."
if [ "$DRY_RUN" = true ]; then
  info "Would create: AGENTS.md"
else
  download "${BASE_URL}/AGENTS.md" "AGENTS.md"
  ok "AGENTS.md"
fi
echo ""

# Install agent-specific adapters
for agent in $agents; do
  case "$agent" in
    cursor)
      info "Installing Cursor adapter..."
      if [ "$DRY_RUN" = true ]; then
        info "Would create: adapters/cursor.mdc"
      else
        mkdir -p adapters
        download "${BASE_URL}/adapters/cursor.mdc" "adapters/cursor.mdc"

        # Also copy to .cursor/rules/ if .cursor/ exists
        if [ -d ".cursor" ]; then
          mkdir -p .cursor/rules
          cp adapters/cursor.mdc .cursor/rules/ditch-vercel.mdc
          ok "adapters/cursor.mdc + .cursor/rules/ditch-vercel.mdc"
        else
          ok "adapters/cursor.mdc"
        fi
      fi
      ;;
    windsurf)
      info "Installing Windsurf adapter..."
      if [ "$DRY_RUN" = true ]; then
        info "Would create: adapters/windsurf.md"
      else
        mkdir -p adapters
        download "${BASE_URL}/adapters/windsurf.md" "adapters/windsurf.md"

        # Also copy to .windsurf/rules/ if .windsurf/ exists
        if [ -d ".windsurf" ]; then
          mkdir -p .windsurf/rules
          cp adapters/windsurf.md .windsurf/rules/ditch-vercel.md
          ok "adapters/windsurf.md + .windsurf/rules/ditch-vercel.md"
        else
          ok "adapters/windsurf.md"
        fi
      fi
      ;;
    cline)
      info "Installing Cline/Roo adapter..."
      if [ "$DRY_RUN" = true ]; then
        info "Would create: adapters/clinerules.md"
      else
        mkdir -p adapters
        download "${BASE_URL}/adapters/clinerules.md" "adapters/clinerules.md"

        # Copy to .clinerules/ if it exists
        if [ -d ".clinerules" ]; then
          cp adapters/clinerules.md .clinerules/ditch-vercel.md
          ok "adapters/clinerules.md + .clinerules/ditch-vercel.md"
        fi
        # Copy to .roo/rules/ if it exists
        if [ -d ".roo" ]; then
          mkdir -p .roo/rules
          cp adapters/clinerules.md .roo/rules/ditch-vercel.md
          ok "adapters/clinerules.md + .roo/rules/ditch-vercel.md"
        fi
        if [ ! -d ".clinerules" ] && [ ! -d ".roo" ]; then
          ok "adapters/clinerules.md"
        fi
      fi
      ;;
    claude-code|agents-md)
      # Already handled above (skill files + AGENTS.md)
      ;;
  esac
done

echo ""
if [ "$DRY_RUN" = true ]; then
  info "Dry run complete. No files were created."
else
  ok "ditch-vercel installed!"
  echo ""
  info "To migrate, open your AI agent and ask: \"migrate from Vercel\""
  info "Or in Claude Code: /ditch-vercel"
fi
