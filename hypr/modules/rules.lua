----------------
---- WINDOW ----
----------------

-- tags
hl.window_rule({ match = { class = "^([Hh]elium)$" }, tag = "+browser" })

hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm|ghostty)$" }, tag = "+terminal" })

hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })

hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	tag = "+setting",
})
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+setting" })
hl.window_rule({ match = { class = "^([Ss]olaar)$" }, tag = "+setting" })

-- floating app
hl.window_rule({ match = { tag = "setting" }, float = true, center = true })
hl.window_rule({ match = { class = "imv" }, float = true, center = true })
hl.window_rule({ match = { class = "[Bb]itwarden" }, float = true, center = true })

-- floating pop-up
hl.window_rule({
	match = { title = "^(Open File)(.*)$" },
	float = true,
	center = true,
})
hl.window_rule({
	match = { title = "^(Save As)(.*)$" },
	float = true,
	center = true,
})
hl.window_rule({
	match = { title = "^(Select a File)(.*)$" },
	float = true,
	center = true,
})
hl.window_rule({
	match = { title = "^(File Upload)(.*)$" },
	float = true,
	center = true,
})
hl.window_rule({ match = { title = "^(Save As)(.*)$" }, float = true, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, float = true, center = true })

-- default workspace
hl.window_rule({ match = { tag = "browser" }, workspace = "1" })
hl.window_rule({ match = { tag = "terminal" }, workspace = "2" })
hl.window_rule({ match = { class = "steam" }, workspace = "5" })
hl.window_rule({ match = { class = "discord" }, workspace = "6" })
hl.window_rule({ match = { class = "ticktick" }, workspace = "8" })

-------------------
---- WORKSPACE ----
-------------------
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })

hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-2" })

---------------
---- MISC. ----
---------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})
