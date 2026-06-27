-- Buffer actions for copying/inserting Obsidian-style links.
local text = require("custom.notes.text")
local scan = require("custom.notes.scan")

local M = {}

-- First H1 in the current buffer (the note's display title), or nil.
local function current_note_title()
	return scan.title_from_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

-- Copy a wikilink to the heading under the cursor: [[note#Heading|Title › Heading]].
function M.copy_link_to_heading()
	local line = vim.api.nvim_get_current_line()

	local heading = line:match("^#+%s+(.+)$")
	if not heading then
		vim.notify("Not on a heading line", vim.log.levels.WARN)
		return
	end
	heading = text.trim(heading)

	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		vim.notify("Buffer has no file", vim.log.levels.WARN)
		return
	end
	local note_id = scan.note_id_from_path(path)

	local alias = text.heading_alias(current_note_title(), heading)
	local link = string.format("[[%s#%s|%s]]", note_id, heading, alias)

	vim.fn.setreg("+", link)
	vim.notify("Copied: " .. link, vim.log.levels.INFO)
end

-- Pick a heading from the current note and copy a wikilink to it.
function M.pick_and_copy_heading_link()
	local headings = scan.read_headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))

	if #headings == 0 then
		vim.notify("No headings in this note", vim.log.levels.WARN)
		return
	end

	local path = vim.api.nvim_buf_get_name(0)
	local note_id = scan.note_id_from_path(path)
	local note_title = current_note_title()

	vim.ui.select(headings, {
		prompt = "Copy link to heading:",
		format_item = function(h)
			return string.rep("  ", h.level - 1) .. h.title
		end,
	}, function(choice)
		if not choice then
			return
		end
		local alias = text.heading_alias(note_title, choice.title)
		local link = string.format("[[%s#%s|%s]]", note_id, choice.title, alias)
		vim.fn.setreg("+", link)
		vim.notify("Copied: " .. link)
	end)
end

-- Copy a block link to the line under the cursor, creating a ^block-id if needed.
function M.copy_link_to_block()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]

	local existing_id = line:match(text.BLOCK_ID_PATTERN)

	local function copy(id)
		local path = vim.api.nvim_buf_get_name(0)
		local note_id = scan.note_id_from_path(path)
		local link = string.format("[[%s#^%s]]", note_id, id)
		vim.fn.setreg("+", link)
		vim.notify("Copied: " .. link)
	end

	if existing_id then
		copy(existing_id)
	else
		local id = text.new_block_id()
		local new_line = line:gsub("%s*$", "") .. " ^" .. id
		vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new_line })
		copy(id)
	end
end

-- Replace the visual selection with a wikilink, picking the target note via
-- Telescope (or creating a new note with <C-x>). `vault_path` is the vault root.
function M.link_selection_as_alias(vault_path)
	-- Yank selection into register z
	vim.cmd('noautocmd normal! "zy')
	local selection = vim.fn.getreg("z")
	if selection == "" then
		return
	end

	-- Remember selection bounds
	local s_row, s_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local e_row, e_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
	local original_buf = vim.api.nvim_get_current_buf()

	local function replace_with_link(target_id)
		local link = (target_id == selection) and ("[[" .. target_id .. "]]")
			or ("[[" .. target_id .. "|" .. selection .. "]]")
		vim.api.nvim_buf_set_text(0, s_row - 1, s_col, e_row - 1, e_col + 1, { link })
	end

	-- Telescope picker — same markdown display as find_files (icon + path + title).
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Link selection: " .. selection .. "  [<CR>=link | <C-x>=create new]",
			default_text = selection, -- pre-fill prompt with selection text
			finder = finders.new_table({
				results = scan.scan_md_files(vault_path),
				entry_maker = require("custom.note_entry"),
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),

			attach_mappings = function(prompt_bufnr, map)
				-- Default action: link to selected note
				actions.select_default:replace(function()
					local selected = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selected then
						vim.api.nvim_set_current_buf(original_buf)
						replace_with_link(scan.note_id_from_path(selected.value))
					end
				end)

				-- <C-x>: create new note with current prompt text as title
				map({ "i", "n" }, "<C-x>", function()
					local prompt = action_state.get_current_line()
					local title = prompt ~= "" and prompt or selection
					actions.close(prompt_bufnr)

					vim.cmd("Obsidian new " .. vim.fn.fnameescape(title))
					local new_path = vim.api.nvim_buf_get_name(0)
					local new_id = scan.note_id_from_path(new_path)
					vim.api.nvim_set_current_buf(original_buf)
					replace_with_link(new_id)
				end)

				return true
			end,
		})
		:find()
end

return M
