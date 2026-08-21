-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("killall xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal")
	hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-hyprland &")
	hl.exec_cmd("sleep 2 && /usr/lib/xdg-desktop-portal &")
	hl.exec_cmd("hyprshade on vibrance")
	hl.exec_cmd("waybar")
	-- hl.exec_cmd("sleep 5 && app2unit -s a -- spotify")
	hl.exec_cmd("awww-daemon --format xrgb")
	hl.exec_cmd("sleep 1 && awww img /home/asitos/Downloads/wallpapers/spiderman.png")
	hl.exec_cmd("clipse -listen")
	hl.exec_cmd("/usr/sbin/kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("~/.config/Scripts/battery_notif.sh")
	hl.exec_cmd("systemctl --user enable --now hyprpolkitagent.service")
end)
