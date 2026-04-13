# Load private constants, otherwise error
if [[ -f ~/.zshrc.local ]]; then
  source ~/.zshrc.local
else
  echo "Error: missing  ~/.zshrc.local: create a symbolic link to dotfiles/.zshrc.local"
  return 1
fi

SESH="tmux-sesh"
if ! tmux has-session -t $SESH 2>/dev/null; then
    tmux new-session -d -s $SESH -n "nvim"
    tmux new-window -t $SESH -n "terminal_0"
    tmux new-window -t $SESH -n "terminal_1"
    tmux new-window -t $SESH -n "ssh"
    tmux select-window -t $SESH:1
fi
tmux attach -t $SESH

export PATH="$PATH:/opt/nvim/"



# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ec="$EDITOR $HOME/.zshrc" # edit .zshrc
alias sc="source $HOME/.zshrc"  # reload zsh configuration
alias vim='nvim'

# Set up the prompt - if you load Theme with zplugin as in this example, this will be overriden by the Theme. If you comment out the Theme in zplugins, this will be loaded.
autoload -Uz promptinit
promptinit
# prompt adam1            # see Zsh Prompt Theme below

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

setopt histignorealldups sharehistory

# Keep 5000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

# zplug - manage plugins
source "$PATH_TO_ZPLUG"
# 1. Load OMZ Libraries FIRST
zplug "lib/functions", from:oh-my-zsh
zplug "lib/theme-and-appearance", from:oh-my-zsh
zplug "lib/git", from:oh-my-zsh
zplug "lib/bzr", from:oh-my-zsh
zplug "lib/hg", from:oh-my-zsh
zplug "lib/clipboard", from:oh-my-zsh
zplug "lib/async_prompt", from:oh-my-zsh
# 2. Load Plugins
zplug "plugins/terraform", from:oh-my-zsh   # <-- add this
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/sudo", from:oh-my-zsh
zplug "plugins/mercurial", from:oh-my-zsh 
zplug "plugins/command-not-found", from:oh-my-zsh
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-completions"
zplug "junegunn/fzf"

# 3. Load the Theme LAST
zplug "themes/agnoster", from:oh-my-zsh, as:theme

#zplug - install/load new plugins when zsh is started or reloaded
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
zplug load --verbose
clear

# CUSTOM FUNCTIONS

# Exit all tmux windows and close the parent terminal
function quitall() {
  # 1. Check if we are actually inside a tmux session
  if [[ -z "$TMUX" ]]; then
    echo "Not inside a tmux session. Exiting normally."
    exit
  fi

  # 2. Get the Process ID (PID) of the active tmux client
  local client_pid=$(tmux display-message -p '#{client_pid}')
  
  # 3. Get the PID of the parent process (the shell or terminal that launched tmux)
  local parent_pid=$(ps -o ppid= -p "$client_pid" | awk '{print $1}')

  # 4. If we successfully found the parent shell, set a trap for it
  if [[ -n "$parent_pid" ]]; then
    # We run a sleep/kill command in the background. 
    # The `&!` is Zsh-specific syntax that backgrounds AND disowns the process 
    # so it survives the upcoming destruction of the tmux pane.
    (sleep 0.2 && kill -9 "$parent_pid" 2>/dev/null) &!
  fi

  # 5. Kill the current tmux session (which closes all its windows/panes)
  tmux kill-session
}
