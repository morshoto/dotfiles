source "$HOME/.config/zsh/environment.zsh"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/keybindings.zsh"
source "$HOME/.config/zsh/completion.zsh"
source "$HOME/.config/zsh/integrations.zsh"
source "$HOME/.config/zsh/extra.zsh"

if [[ -f "$HOME/.config/zsh/local.zsh" ]]; then
  source "$HOME/.config/zsh/local.zsh"
fi

source "$HOME/.config/zsh/home-manager.zsh"
