-- Telescope rows for markdown notes: <icon> <dim relative path> <H1 title>.
local notes = require("custom.obsidian.note")

local M = {}

-- Returns a telescope `display` function for the note at `path`, and its title
-- (nil when the note has no H1).
function M.note_display(path)
	local ok, lines = pcall(vim.fn.readfile, path, "", 30)
	local title = ok and notes.title_from_lines(lines) or nil
	local rel_path = vim.fn.fnamemodify(path, ":.")
	local icon, icon_hl =
		require("nvim-web-devicons").get_icon(vim.fn.fnamemodify(path, ":t"), "md", { default = true })

	local display = function()
		local entry_display = require("telescope.pickers.entry_display")
		if title then
			return entry_display.create({
				separator = " ",
				items = { { width = 2 }, { width = 50 }, { remaining = true } },
			})({ { icon, icon_hl }, { rel_path, "Comment" }, { title, "@markup.heading" } })
		end
		return entry_display.create({
			separator = " ",
			items = { { width = 2 }, { remaining = true } },
		})({ { icon, icon_hl }, { rel_path, "Comment" } })
	end

	return display, title
end

local file_entry
-- Entry maker for file pickers: markdown notes get the title display and are
-- searchable by title; other files keep telescope's default.
function M.entry_maker(path)
	file_entry = file_entry or require("telescope.make_entry").gen_from_file()
	local entry = file_entry(path)

	if path:match("%.md$") then
		local display, title = M.note_display(path)
		entry.display = display
		entry.ordinal = title and (title .. " " .. path) or path
	end

	return entry
end

return M
