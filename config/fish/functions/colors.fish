function colors
    echo
    echo " 🐱 Catppuccin Mocha Palette"
    echo " --------------------------"

    # Function to print colored line
    function _print_col
        set_color $argv[2]
        printf "  %-12s %s  ██████\n" $argv[1] $argv[3]
        set_color normal
    end

    # The Palette
    _print_col "Rosewater"  f5e0dc "#f5e0dc"
    _print_col "Flamingo"   f2cdcd "#f2cdcd"
    _print_col "Pink"       f5c2e7 "#f5c2e7"
    _print_col "Mauve"      cba6f7 "#cba6f7"
    _print_col "Red"        f38ba8 "#f38ba8"
    _print_col "Maroon"     eba0ac "#eba0ac"
    _print_col "Peach"      fab387 "#fab387"
    _print_col "Yellow"     f9e2af "#f9e2af"
    _print_col "Green"      a6e3a1 "#a6e3a1"
    _print_col "Teal"       94e2d5 "#94e2d5"
    _print_col "Sky"        89dceb "#89dceb"
    _print_col "Sapphire"   74c7ec "#74c7ec"
    _print_col "Blue"       89b4fa "#89b4fa"
    _print_col "Lavender"   b4befe "#b4befe"
    _print_col "Text"       cdd6f4 "#cdd6f4"
    
    echo " --------------------------"
    echo
end
