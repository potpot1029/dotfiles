local palette = dofile(os.getenv("HOME") .. "/.config/palette/palette.lua")

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,
		border_size = 1,
		col = {
			active_border = "rgb(" .. palette.cyan:sub(2) .. ")",
			inactive_border = "0xff" .. palette.gray:sub(2),
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = tonumber("0xee" .. palette.black:sub(2)),
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = false,
	},

	dwindle = {
		preserve_split = true,
	},
})
