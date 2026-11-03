-- Buffer-local <leader>o… keymaps for notes inside the vault.
local vault = require("custom.obsidian.vault")
local links = require("custom.obsidian.links")
local notes = require("custom.obsidian.note")

local M = {}

local function rename_note()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		vim.notify("no file in current buffer", vim.log.levels.WARN)
		return
	end
	local current_id = notes.note_id_from_path(path)
	vim.ui.input({ prompt = "new note ID: ", default = current_id }, function(new_id)
		if new_id and new_id ~= "" and new_id ~= current_id then
			vim.cmd("Obsidian rename " .. new_id)
		end
	end)
end

-- { mode, lhs, rhs, description }
local maps = {
	{ "n", "<leader>o;", "<cmd>Obsidian toc<CR>", "open toc" },
	{ "n", "<leader>od", "<cmd>Obsidian today<CR>", "open [d]aily note" },
	{ "n", "<leader>oo", "<cmd>Obsidian open<CR>", "[o]pen note in Obsidian app" },
	{ "n", "<leader>ol", "<cmd>Obsidian links<CR>", "show note [l]inks" },
	{
		"n",
		"<leader>ob",
		function()
			require("custom.obsidian.backlinks").show()
		end,
		"show note [b]acklinks",
	},
	{ "n", "<leader>ot", "<cmd>Obsidian tags<CR>", "show [t]ags" },
	{ "n", "<leader>of", "<cmd>Obsidian quick_switch<CR>", "[f]ind notes (quick switcher)" },
	{ "n", "<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", "toggle [c]heckbox" },
	{ "n", "<leader>os", "<cmd>Obsidian search<CR>", "[s]earch notes" },
	{ "n", "<leader>on", "<cmd>Obsidian new<CR>", "[n]ew note" },
	{ "n", "<leader>ov", "<cmd>Obsidian new_from_template<CR>", "new note from template" },
	{ "n", "<leader>or", rename_note, "[r]ename note" },
	{ "n", "<leader>ox", "<cmd>Obsidian extract_note<CR>", "e[x]tract note" },
	{ "n", "<leader>om", "<cmd>Obsidian template<CR>", "insert template" },
	{ "n", "<leader>oi", "<cmd>Obsidian paste_img<CR>", "paste [i]mage" },
	{ "n", "<leader>og", "<cmd>Obsidian follow_link<CR>", "([g]o) follow link" },
	{ "n", "<leader>oy", links.copy_link_to_heading, "[y]ank link to heading" },
	{ "n", "<leader>oY", links.pick_and_copy_heading_link, "pick heading and copy link" },
	{ "n", "<leader>ok", links.copy_link_to_block, "copy link to bloc[k]" },
	{
		"x",
		"<leader>oL",
		function()
			links.link_selection_as_alias(vault.path)
		end,
		"[L]ink selection (create if missing)",
	},
}

function M.setup()
	vim.api.nvim_create_autocmd("BufEnter", {
		group = vim.api.nvim_create_augroup("obsidian_keymaps", { clear = true }),
		pattern = "*.md",
		callback = function(args)
			if vim.b[args.buf].obsidian_keymaps_set or not vault.has_buf(args.buf) then
				return
			end
			vim.b[args.buf].obsidian_keymaps_set = true

			for _, m in ipairs(maps) do
				vim.keymap.set(m[1], m[2], m[3], { buffer = args.buf, desc = "[o]bsidian: " .. m[4] })
			end
		end,
	})
end

return M
