-- The options table passed to obsidian.nvim's setup(). Kept declarative; the
-- only logic is the frontmatter title derivation, which reuses the shared note
-- helpers.
local text = require("custom.notes.text")
local scan = require("custom.notes.scan")
local c = require("synthweave.palette")

local M = {}

-- Title for a note: prefer its first H1 (from note.contents when obsidian.nvim
-- provides it, otherwise the current buffer).
local function note_title(note)
	local lines
	if note and note.contents and not vim.tbl_isempty(note.contents) then
		lines = note.contents
	else
		lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	end
	return scan.title_from_lines(lines)
end

function M.build(vault_path)
	return {
		legacy_commands = false,
		workspaces = {
			{
				name = "the-pot",
				path = vault_path,
			},
		},

		open_notes_in = "current",

		notes_subdir = "notes",

		note_path_func = function(spec)
			local path = spec.dir / tostring(spec.id)
			return path:with_suffix(".md")
		end,

		daily_notes = {
			folder = "notes/daily/",
			date_format = "%Y-%m-%d",
			alias_format = "%A, %B %-d, %Y",
			default_tags = { "daily" },
			template = "templates/daily-note.md",
		},
		attachments = {
			folder = "assets/imgs",
			img_name_func = function()
				return string.format("%s-", os.date("%Y%m%d-%H%M%S"))
			end,
		},

		templates = {
			folder = "templates",
			date_format = "%Y-%m-%d",
			alias_format = "%A, %B %-d, %Y",
			substitutions = {
				yesterday = function()
					return os.date("%Y-%m-%d", os.time() - 86400)
				end,
				tomorrow = function()
					return os.date("%Y-%m-%d", os.time() + 86400)
				end,
			},
		},

		picker = {
			name = "telescope.nvim",
			note_mappings = {
				new = "<C-x>",
				insert_link = "<C-l>",
			},
			tag_mappings = {
				tag_note = "<C-x>",
				insert_tag = "<C-l>",
			},
		},

		search = {
			sort_by = "modified",
			sort_reversed = true,
		},

		new_notes_location = "notes_subdir",
		link = {
			style = "wiki",
			auto_update = true,
		},

		frontmatter = {
			enabled = true,
			sort = { "id", "aliases", "tags" },
			func = function(note)
				local title = note_title(note)

				if title then
					note:add_alias(title)
					local short = title:match("^(.-)%s*%(")
					if short and short ~= "" and short ~= title then
						note:add_alias(short)
					end
				end

				local out = { id = note.id, title = title, aliases = note.aliases, tags = note.tags }

				-- `note.metadata` contains any manually added fields in the frontmatter.
				-- So here we just make sure those fields are kept in the frontmatter.
				if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
					for k, v in pairs(note.metadata) do
						out[k] = v
					end
				end

				return out
			end,
		},

		note_id_func = function(title)
			local suffix = title and text.slugify(title) or ""
			return tostring(os.time()) .. "_" .. suffix
		end,

		note = {
			id_func = function(title)
				local suffix = title and text.slugify(title) or ""
				return tostring(os.time()) .. "_" .. suffix
			end,
			template = "default-neovim.md",
		},

		ui = {
			enable = false, -- needs conceallevel = 1 or 2 to fully take effect
			hl_groups = {
				ObsidianRefText = { fg = "#ff00ff", underline = false },
				ObsidianExtLinkIcon = { fg = c.gray },
				ObsidianWikiLink = { fg = c.yellow, underline = false },
				ObsidianTodo = { bold = true, fg = "#f78c6c" },
				ObsidianDone = { bold = true, fg = "#89ddff" },
				ObsidianForward = { bold = true, fg = "#f78c6c" },
				ObsidianTilde = { bold = true, fg = "#ff5370" },
				ObsidianImportant = { bold = true, fg = "#d73128" },
				ObsidianBullet = { bold = true, fg = c.cyan },
				ObsidianTag = { italic = true, fg = "#89ddff" },
				ObsidianBlockID = { italic = true, fg = "#89ddff" },
				ObsidianHighlightText = { bg = "#75662e" },
			},
		},
		checkbox = {
			enabled = true,
			create_new = true,
			order = { " ", "~", "!", ">", "<", "/", "x" },
		},
	}
end

return M
