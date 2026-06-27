-- Telescope entry maker for file paths that shows markdown notes with their H1
-- title: <icon> <dim relative path> <yellow title>. Non-markdown files fall back
-- to the default file entry. Shared by find_files and the obsidian link picker.
local scan = require("custom.notes.scan")

return function(entry)
	local make_entry = require("telescope.make_entry")
	local default_entry = make_entry.gen_from_file()(entry)

	if entry:match("%.md$") then
		local ok, lines = pcall(vim.fn.readfile, entry, "", 30)
		local title = ok and scan.title_from_lines(lines) or nil

		local rel_path = vim.fn.fnamemodify(entry, ":.")

		local devicons = require("nvim-web-devicons")
		local filename = vim.fn.fnamemodify(entry, ":t")
		local icon, icon_hl = devicons.get_icon(filename, "md", { default = true })

		if title then
			-- Has H1 title: yellow title, dim path
			default_entry.display = function()
				local displayer = require("telescope.pickers.entry_display").create({
					separator = " ",
					items = {
						{ width = 2 },
						{ width = 50 },
						{ remaining = true },
					},
				})
				return displayer({
					{ icon, icon_hl },
					{ rel_path, "Comment" },
					{ title, "@markup.heading" },
				})
			end
			default_entry.ordinal = title .. " " .. entry
		else
			-- No H1 title: everything dimmed
			default_entry.display = function()
				local displayer = require("telescope.pickers.entry_display").create({
					separator = " ",
					items = {
						{ width = 2 },
						{ remaining = true },
					},
				})
				return displayer({
					{ icon, icon_hl },
					{ rel_path, "Comment" },
				})
			end
			default_entry.ordinal = entry
		end
	end

	return default_entry
end
