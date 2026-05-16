# Extra zsh settings managed in dotfiles.
# Keep non-Nix-managed local integrations here.

# Colorize `ls` output on macOS and highlight directories only.
export CLICOLOR=1
export LSCOLORS="Exxxxxxxxxxxxxxxxxxxxx"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Google Cloud SDK
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
fi

if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
fi

# TeX Live
if [ -d "/usr/local/texlive/2024/bin/universal-darwin" ]; then
  export PATH="$PATH:/usr/local/texlive/2024/bin/universal-darwin"
fi

if [ -d "/usr/local/texlive/2024/bin/x86_64-darwin" ]; then
  export PATH="$PATH:/usr/local/texlive/2024/bin/x86_64-darwin"
fi

# MongoDB via Homebrew
if [ -d "/opt/homebrew/opt/mongodb-community/bin" ]; then
  export PATH="/opt/homebrew/opt/mongodb-community/bin:$PATH"
fi

# Angular CLI completion
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi
