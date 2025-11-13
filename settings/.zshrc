# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


# Terminal title  #
echo -en "\e]2;$(hostname -I | awk '{print $1}') | $USER@$(hostname)\a"


# Shell greeting #
echo "greetings"


# PATH #
export PATH=~/.local/bin:/snap/bin::/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/share/games:/usr/local/sbin:/usr/sbin:/sbin:$PATH


# Aliases #
alias ls='ls -lF --color=auto'
alias la='ls -laF --color=auto'
alias ll='ls -laF --color=auto'
alias sc='screen'
alias gdb='gdb -q -x ~/.gdb.cfg'
alias tone='paplay /usr/share/sounds/sound-icons/start'
alias fp='featherpad'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'


# History #
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend  


# Functions #
function hex-encode() {
  echo "$@" | xxd -p
}

function hex-decode() {
  echo "$@" | xxd -p -r
}

function rot13() {
  echo "$@" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}


# Keybinds #

# Ctrl+Right → forward-word
bind '"\e[1;5C": forward-word'

# Ctrl+Left → backward-word
bind '"\e[1;5D": backward-word'

# Ctrl+Backspace → backward-kill-word
bind '"\C-h": backward-kill-word'

# Ctrl+Delete → kill-word
bind '"\e[3;5~": kill-word'


#####################
# Bash standard stuff
#####################

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'


# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt


#########
# If zsh:
#########
if [ -n "$ZSH_VERSION" ]; then

  # Oh My Posh theme
  eval "$(oh-my-posh init zsh --config ~/.poshthemes/powerlevel10k_rainbow.omp.json)"

  # Zsh Prompt
  PROMPT="%F{red}┌[%f%F{cyan}%m%f%F{red}]─[%f%F{yellow}%D{%H:%M-%d/%m}%f%F{red}]─[%f%F{magenta}%d%f%F{red}]%f"$'\n'"%F{red}└╼%f%F{green}$USER%f%F{yellow}$%f"

  # Autosuggestions
  if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi

  # Syntax highlighting
  if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  fi

  # Autocomplete
  if [ -f /usr/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]; then
    source /usr/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
    zstyle ':autocomplete:tab:*' insert-unambiguous yes
    zstyle ':autocomplete:tab:*' widget-style menu-select
    zstyle ':autocomplete:*' min-input 16
    bindkey $key[Up] up-line-or-history
    bindkey $key[Down] down-line-or-history
  fi

  # History settings
  HISTFILE=~/.zsh_history
  HISTSIZE=10000
  SAVEHIST=10000
  setopt appendhistory

  # Navigation keybinds
  bindkey "^[[1;5C" forward-word
  bindkey "^[[1;5D" backward-word
  bindkey "^H" backward-kill-word
  bindkey "^[[3;5~" kill-word

fi
