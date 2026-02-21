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

  # Claude Code (binary or project config)
  if command -v claude >/dev/null 2>&1 || [ -d ".claude" ] || [ -f ".claude-plugin/plugin.json" ]; then
    agents="$agents claude-code"
  fi

  # Cursor (binary, macOS app, or project config)
  if command -v cursor >/dev/null 2>&1 || [ -d "/Applications/Cursor.app" ] || [ -d ".cursor" ] || [ -f ".cursorrules" ]; then
    agents="$agents cursor"
  fi

  # Windsurf (binary, macOS app, or project config)
  if command -v windsurf >/dev/null 2>&1 || [ -d "/Applications/Windsurf.app" ] || [ -d ".windsurf" ]; then
    agents="$agents windsurf"
  fi

  # Cline / Roo Code (VS Code extensions — no binary, project dir only)
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

  removed=0

  # Remove skill files (installed under .agents/)
  for f in $SKILL_FILES; do
    if [ -f ".agents/$f" ]; then
      if [ "$DRY_RUN" = true ]; then
        info "Would remove: .agents/$f"
      else
        rm ".agents/$f"
        ok "Removed .agents/$f"
      fi
      removed=$((removed + 1))
    fi
  done

  # Remove adapter files (installed at project root)
  for f in $ADAPTER_FILES; do
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

  # Remove Claude Code skill symlink
  if [ -L ".claude/skills/ditch-vercel" ]; then
    if [ "$DRY_RUN" = true ]; then
      info "Would remove: .claude/skills/ditch-vercel (symlink)"
    else
      rm ".claude/skills/ditch-vercel"
      ok "Removed .claude/skills/ditch-vercel (symlink)"
    fi
    removed=$((removed + 1))
  fi

  # Clean up empty directories
  for dir in .agents/skills/ditch-vercel/frameworks .agents/skills/ditch-vercel/targets .agents/skills/ditch-vercel .agents/skills .agents adapters .claude/skills .claude; do
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
  dir=$(dirname ".agents/$f")
  if [ "$DRY_RUN" = true ]; then
    info "Would create: .agents/$f"
  else
    mkdir -p "$dir"
    download "${BASE_URL}/${f}" ".agents/$f"
    ok ".agents/$f"
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
    claude-code)
      info "Registering skill with Claude Code..."
      if [ "$DRY_RUN" = true ]; then
        info "Would create: .claude/skills/ditch-vercel -> ../../.agents/skills/ditch-vercel"
      else
        mkdir -p .claude/skills
        ln -sfn ../../.agents/skills/ditch-vercel .claude/skills/ditch-vercel
        ok ".claude/skills/ditch-vercel (symlink)"
      fi
      ;;
    agents-md)
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
  info "To start the migration, open your agent and use one of these:"
  echo ""

  for agent in $agents; do
    case "$agent" in
      claude-code) info "  Claude Code:     /ditch-vercel" ;;
      cursor)      info "  Cursor:          Ask \"migrate this project from Vercel\"" ;;
      windsurf)    info "  Windsurf:        Ask \"migrate from Vercel using ditch-vercel\"" ;;
      cline)       info "  Cline/Roo:       Ask \"migrate this project from Vercel\"" ;;
      agents-md)   info "  Copilot/Codex:   Ask \"use the ditch-vercel skill to migrate\"" ;;
    esac
  done
fi
