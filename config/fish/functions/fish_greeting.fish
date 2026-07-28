function fish_greeting
    # The Silly List
    set -l messages \
        "welcome back, asitos! :3" \
        "arch linux goes meow~ 󰄛" \
        "don't break the system today, okay? :3" \
        "uwu what's this? a terminal?"
    
    # Pick one at random
    set -l msg (random choice $messages)
    
    # Print it in Lavender
    echo
    set_color b4befe # Lavender hex
    echo "$msg"
    set_color normal
    echo
end
