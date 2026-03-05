# ~/.zshrc

# ============== Initialization ==============
# Starship prompt initialization
eval "$(starship init zsh)"

# Fuzzy finder (fzf) setup
source <(fzf --zsh)

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Completion system
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

# Autosuggestions
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ================ NVM Setup ==================
#
# Node Version Manager setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ================== Aliases ===================
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# ============== Additional Configs ============
# Add Opencode binaries to PATH
export PATH="$HOME/.opencode/bin:$PATH"

# SSH Authentication Agent
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
