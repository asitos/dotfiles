if status is-interactive
end

fish_add_path /home/asitos/.spicetify
fish_add_path /home/asitos/.local/bin
fish_add_path /home/asitos/Downloads/remotegamepad/
fish_add_path /home/asitos/.config/Scripts/
fish_add_path /home/asitos/.cargo/bin/
fish_add_path /home/asitos/.config/waybar/scripts/
fish_add_path /home/asitos/Downloads/totk/
fish_add_path /home/asitos/Projects/haj/target/release/
if status is-interactive
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    zoxide init fish | source
    alias cd="z" 
    export LFS=/mnt/lfs
    export TERM=xterm-256color

    export WECHALLUSER="asitos"
    export WECHALLTOKEN="81116-7FA02-33D37-A8260-D8418-CF7A0"
    umask 0022
    alias dotfiles="~/Projects/dotfiles/sync.sh"
    alias ds="dotfiles save"
    # alias da="dotfiles apply"
    alias l="eza --icons --all --long --git --no-user"
    alias tree="eza --tree --icons --level=2"
    alias pc="pyroclear"

    alias cat="bat --theme='Catppuccin Mocha'"
    
    alias rm="rm -i"
    alias cp="cp -i"
    alias venv="source ./venv/bin/activate.fish"
    alias gf="git fetch"
    alias gp="git push origin"
    alias gpl="git pull origin"
    alias ga="git add ."
    alias gs="git status"
    alias gc="git commit -m"
    alias gcr="git commit -m \"docs: update readme\""
    alias rd="ga && gcr && gp"
    alias gt="git tag -a"
    alias gpmas="git push origin master"
    alias n="nvim"
    alias nr="nvim README.md"
    alias y="yazi"
    alias nfc="nvim ~/.config/fish/config.fish"
    alias sfc="source ~/.config/fish/config.fish"
    alias s="sudo"
    alias se="sudo -E"
    alias cbr="cargo build --release"
    alias cr="cargo run --"
    alias lg="lazygit"
    alias mirrors="sudo reflector --country 'India','Singapore' --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
    alias h="haj"
    alias a="agy"

    # ssh
    # custom asitos aliases
    alias pocha="clear"
    alias sojaao="shutdown now"
    alias dikhaao="eza --icons --all"
    alias naagin="python"
    alias hataao="rm -rf"
    alias daalo="sudo pacman -S"
    alias dhundo="sudo pacman -Q"
    alias nikaalo="sudo pacman -Rns"
    alias fetch="fastfetch --config ascii-art"
    alias laadle="sudo pacman -Syu"
    alias aawaaz="bluetoothctl connect 41:42:84:84:84:84"
    alias rajma="bluetoothctl connect 10:E4:C2:5F:84:6E"
    
    set -gx fish_color_command b4befe
    
    set -gx fish_color_param f5e0dc
    
    set -gx fish_color_error f38ba8
    
    set -gx fish_color_comment 6c7086
    
    set -gx fish_color_quote a6e3a1
    
    set -gx fish_color_selection --background=b4befe
    
    set -gx fish_color_autosuggestion 585b70
    
    set -gx fish_color_user b4befe
    set -gx fish_color_host b4befe
end

starship init fish | source

function fish_user_key_bindings
    fish_vi_key_bindings

    bind -M default B beginning-of-line
    bind -M default W end-of-line

    bind -M visual B beginning-of-line
    bind -M visual W end-of-line
end

set -g fish_key_bindings fish_vi_key_bindings

set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual block

function nvim
    # Remove margin
    kitty @ set-spacing margin=0
    
    # Run normal Neovim and pass any arguments (like file names) to it
    command nvim $argv
    
    # Restore margin when Neovim closes
    kitty @ set-spacing margin=12
end


# Added by Antigravity CLI installer
set -gx PATH "/home/asitos/.local/bin" $PATH
