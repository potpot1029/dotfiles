-- Copy/insert Obsidian-style wikilinks.
local notes = require("custom.obsidian.note")

local M = {}

local function current_note()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		vim.notify("Buffer has no file", vim.log.levels.WARN)
		return nil
	end
	local title = notes.title_from_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false))
	return notes.note_id_from_path(path), title
end

local function copy(link)
	vim.fn.setreg("+", link)
	vim.notify("Copied: " .. link)
end

local function heading_link(note_id, note_title, heading)
	return ("[[%s#%s|%s]]"):format(note_id, heading, notes.heading_alias(note_title, heading))
end

-- [[note#Heading|Title › Heading]] for the heading under the cursor.
function M.copy_link_to_heading()
	local heading = vim.api.nvim_get_current_line():match("^#+%s+(.+)$")
	if not heading then
		vim.notify("Not on a heading line", vim.log.levels.WARN)
		return
	end
	local note_id, note_title = current_note()
	if note_id then
		copy(heading_link(note_id, note_title, notes.trim(heading)))
	end
end

function M.pick_and_copy_heading_link()
	local headings = notes.read_headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))
	if #headings == 0 then
		vim.notify("No headings in this note", vim.log.levels.WARN)
		return
	end
	local note_id, note_title = current_note()
	if not note_id then
		return
	end

	vim.ui.select(headings, {
		prompt = "Copy link to heading:",
		format_item = function(h)
			return string.rep("  ", h.level - 1) .. h.title
		end,
	}, function(choice)
		if choice then
			copy(heading_link(note_id, note_title, choice.title))
		end
	end)
end

-- [[note#^id]] for the line under the cursor, adding a ^block-id if it has none.
function M.copy_link_to_block()
	local note_id = current_note()
	if not note_id then
		return
	end
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()

	local id = line:match(notes.BLOCK_ID_PATTERN)
	if not id then
		id = notes.new_block_id()
		vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { line:gsub("%s*$", "") .. " ^" .. id })
	end
	copy(("[[%s#^%s]]"):format(note_id, id))
end

-- Replace the visual selection with a wikilink to a note picked in telescope
-- (<C-x> creates a new note titled with the prompt text instead).
function M.link_selection_as_alias(vault_path)
	vim.cmd('noautocmd normal! "zy')
	local selection = vim.fn.getreg("z")
	if selection == "" then
		return
	end

	local s_row, s_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local e_row, e_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
	local original_buf = vim.api.nvim_get_current_buf()

	local function insert_link(target_id)
		local link = target_id == selection and ("[[%s]]"):format(target_id)
			or ("[[%s|%s]]"):format(target_id, selection)
		vim.api.nvim_set_current_buf(original_buf)
		vim.api.nvim_buf_set_text(0, s_row - 1, s_col, e_row - 1, e_col + 1, { link })
	end

	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Link selection: " .. selection .. "  [<CR>=link | <C-x>=create new]",
			default_text = selection,
			finder = require("telescope.finders").new_table({
				results = notes.scan_md_files(vault_path),
				entry_maker = require("custom.obsidian.entry").entry_maker,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selected = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selected then
						insert_link(notes.note_id_from_path(selected.value))
					end
				end)

				map({ "i", "n" }, "<C-x>", function()
					local prompt = action_state.get_current_line()
					actions.close(prompt_bufnr)
					vim.cmd("Obsidian new " .. vim.fn.fnameescape(prompt ~= "" and prompt or selection))
					insert_link(notes.note_id_from_path(vim.api.nvim_buf_get_name(0)))
				end)

				return true
			end,
		})
		:find()
end

return M
