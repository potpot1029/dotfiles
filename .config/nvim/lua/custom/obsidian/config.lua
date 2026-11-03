-- obsidian.nvim options, matched to how the Obsidian app is set up for the vault.
local notes = require("custom.obsidian.note")

local M = {}

local DATE_TITLE = "%A, %B %-d, %Y" -- "Tuesday, November 3, 2026"

-- First H1 of the note (or of the current buffer when obsidian.nvim has no contents).
local function note_title(note)
	local lines = note.contents
	if not lines or vim.tbl_isempty(lines) then
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	end
	return notes.title_from_lines(lines)
end

-- Frontmatter in the same shape as the app's notes: title, aliases, tags (no id).
local function frontmatter(note)
	local title = note_title(note)
	if title then
		note:add_alias(title)
		local short = title:match("^(.-)%s*%(") -- "Foo (bar)" also gets alias "Foo"
		if short and short ~= "" and short ~= title then
			note:add_alias(short)
		end
	end

	local id = tostring(note.id or "")
	if id:match("^%d%d%d%d%-%d%d%-%d%d$") then -- daily notes: date as an alias too
		note:add_alias(id)
	end

	local tags = note.tags
	if not tags or vim.tbl_isempty(tags) then
		tags = { "notes" }
	end

	local out = { title = title, aliases = note.aliases, tags = tags }
	for k, v in pairs(note.metadata or {}) do -- keep any other existing fields
		out[k] = v
	end
	return out
end

-- File name = slug of the title (like the vault's Templater new-file.md), with
-- -2, -3, ... when `dir` already has a note by that name.
local function note_id(vault_path)
	return function(title, dir)
		local base = title and notes.note_slug(title) or ""
		if base == "" then
			base = "untitled"
		end
		dir = dir and tostring(dir) or vim.fs.joinpath(vault_path, "notes")
		local name, n = base, 2
		while vim.uv.fs_stat(vim.fs.joinpath(dir, name .. ".md")) do
			name = base .. "-" .. n
			n = n + 1
		end
		return name
	end
end

-- {{daily_title}}: the daily note's own date (its id is YYYY-MM-DD), so
-- `:Obsidian tomorrow` gets tomorrow's title.
local function daily_title(ctx)
	local id = ctx and ctx.partial_note and tostring(ctx.partial_note.id) or ""
	local y, m, d = id:match("(%d%d%d%d)-(%d%d)-(%d%d)$")
	local time = y and os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
	return os.date(DATE_TITLE, time or os.time())
end

function M.build(vault)
	return {
		legacy_commands = false,
		workspaces = { { name = vault.name, path = vault.path } },

		notes_subdir = "notes",
		new_notes_location = "notes_subdir",
		note_id_func = note_id(vault.path),
		note = { template = "note.md" },
		frontmatter = { sort = { "title", "aliases", "tags" }, func = frontmatter },

		daily_notes = {
			folder = "notes/dailies",
			date_format = "%G/W%V/%Y-%m-%d",
			alias_format = DATE_TITLE,
			default_tags = { "daily-notes" },
			template = "daily-note.md",
		},

		-- the vault's own templates are Templater (JS); these are plain copies
		templates = {
			folder = "templates/nvim",
			date_format = "%Y-%m-%d",
			time_format = "**%H:%M**",
			substitutions = { daily_title = daily_title },
		},

		attachments = {
			folder = "assets/images",
			img_name_func = function()
				return os.date("%Y%m%d-%H%M%S-")
			end,
		},

		picker = {
			name = "telescope.nvim",
			note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
			tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
		},

		link = { auto_update = true },
		ui = { enable = false },
		checkbox = { order = { " ", "x", "~", "!", ">", "<", "/" } },
	}
end

return M
