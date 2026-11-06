function realme --description "Connect to Realme over wireless ADB via default gateway"
    set -l gw (ip route | awk '/default/ {print $3; exit}')
    if test -n "$gw"
        set -l port (test -n "$argv[1]"; and echo "$argv[1]"; or echo "5555")
        adb connect "$gw:$port"
    else
        echo "Error: Default gateway not found."
        return 1
    end
end
