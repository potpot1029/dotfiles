require("modules.programs")

hl.on("hyprland.start", function()
	-- hyprlock greeting screen
	hl.exec_cmd("hyprlock || hyprctl dispatch exit")

	-- bar, wallpaper
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")

	-- app
	hl.exec_cmd(browser, { workspace = "1" })
	hl.exec_cmd("surfshark", { workspace = "1 silent" })
	hl.exec_cmd(terminal, { workspace = "2 silent" })
	hl.exec_cmd("obsidian", { workspace = "3 silent" })
	hl.exec_cmd("steam", { workspace = "5 silent" })
	hl.exec_cmd("discord", { workspace = "6 silent" })
	hl.exec_cmd("ticktick", { workspace = "8 silent" })

	-- utility
	hl.exec_cmd("fcitx")
	hl.exec_cmd("solaar")
end)
