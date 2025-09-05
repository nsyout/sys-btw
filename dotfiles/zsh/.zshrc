# History & completion
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY
autoload -Uz compinit && compinit

# Keybindings
bindkey -e

# Prompt
eval "$(starship init zsh)"

# PATH
export PATH="$HOME/go/bin:$PATH"

# Aliases
alias ls='ls --color=auto'
alias cat='bat --style=plain --paging=never 2>/dev/null || cat'

