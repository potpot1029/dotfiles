-- Buffer-local Obsidian keymaps for notes inside the vault, plus a one-time
-- vim.ui.open override (open .png in nvim, .pdf in zathura).
local M = {}

local ui_open_patched = false

local function patch_ui_open()
	if ui_open_patched then
		return
	end
	ui_open_patched = true

	vim.ui.open = (function(overridden)
		return function(uri, opt)
			if vim.endswith(uri, ".png") then
				vim.cmd("edit " .. uri) -- early return to just open in neovim
				return
			elseif vim.endswith(uri, ".pdf") then
				opt = { cmd = { "zathura" } } -- override open app
			end
			return overridden(uri, opt)
		end
	end)(vim.ui.open)
end

-- `in_vault(bufnr)` decides whether a buffer belongs to the vault; `links` is the
-- custom.obsidian.links module; `vault_path` is the vault root.
function M.setup(in_vault, links, vault_path)
	patch_ui_open()

	local group = vim.api.nvim_create_augroup("obsidian_keymaps", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*.md",
		callback = function(args)
			if not in_vault(args.buf) then
				return
			end
			if vim.b[args.buf].obsidian_keymaps_set then
				return
			end
			vim.b[args.buf].obsidian_keymaps_set = true

			local opts = function(desc)
				return { buffer = args.buf, desc = desc }
			end

			vim.keymap.set("n", "<leader>od", "<cmd>Obsidian today<CR>", opts("[o]bsidian: open [d]aily notes"))
			vim.keymap.set(
				"n",
				"<leader>oo",
				"<cmd>Obsidian open<CR>",
				opts("[o]bsidian: [o]pen notes in Obsidian app")
			)
			vim.keymap.set("n", "<leader>ol", "<cmd>Obsidian links<CR>", opts("[o]bsidian: show note [l]inks"))
			vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<CR>", opts("[o]bsidian: show note [b]acklinks"))
			vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian tags<CR>", opts("[o]bsidian: show [t]ags"))
			vim.keymap.set("n", "<leader>o'", "<cmd>Obsidian move_note<CR>", opts("[o]bsidian: move note"))
			vim.keymap.set(
				"n",
				"<leader>of",
				"<cmd>Obsidian quick_switch<CR>",
				opts("[o]bsidian: [f]ind notes (quick switcher)")
			)
			vim.keymap.set(
				"n",
				"<leader>oc",
				"<cmd>Obsidian toggle_checkbox<CR>",
				opts("[o]bsidian: toggle checkboxes")
			)
			vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<CR>", opts("[o]bsidian: [s]earch notes"))
			vim.keymap.set("n", "<leader>on", "<cmd>Obsidian new<CR>", opts("[o]bsidian: [n]ew note"))
			vim.keymap.set(
				"n",
				"<leader>ov",
				"<cmd>Obsidian new_from_template<CR>",
				opts("[o]bsidian: new note from template")
			)
			vim.keymap.set("n", "<leader>or", function()
				-- Get the current buffer's file path and extract the note ID (filename without extension)
				local current_path = vim.api.nvim_buf_get_name(0)
				if current_path == "" then
					vim.notify("no file in current buffer", vim.log.levels.WARN)
					return
				end
				local current_id = vim.fn.fnamemodify(current_path, ":t:r") -- :t = tail, :r = remove ext

				-- Prompt with the current ID pre-filled
				vim.ui.input({
					prompt = "new note ID: ",
					default = current_id,
				}, function(new_id)
					if not new_id or new_id == "" or new_id == current_id then
						return -- cancelled or unchanged
					end
					vim.cmd("Obsidian rename " .. new_id)
				end)
			end, opts("[o]bsidian: [r]ename notes"))
			vim.keymap.set("n", "<leader>ox", "<cmd>Obsidian extract_note<CR>", opts("[o]bsidian: e[x]tract note"))
			vim.keymap.set("n", "<leader>om", "<cmd>Obsidian template<CR>", opts("[o]bsidian: insert template"))
			vim.keymap.set("n", "<leader>oi", "<cmd>Obsidian paste_img<CR>", opts("[o]bsidian: paste [i]mage"))

			vim.keymap.set(
				"n",
				"<leader>og",
				"<cmd>Obsidian follow_link<CR>",
				opts("[o]bsidian: ([g]o) follow through link")
			)

			vim.keymap.set("x", "<leader>oL", function()
				links.link_selection_as_alias(vault_path)
			end, opts("[o]bsidian: [L]ink selection (create if missing)"))
			vim.keymap.set(
				"n",
				"<leader>oY",
				links.pick_and_copy_heading_link,
				opts("[o]bsidian: pick heading and copy link")
			)

			vim.keymap.set("n", "<leader>oy", links.copy_link_to_heading, opts("[o]bsidian: [y]ank link to heading"))

			vim.keymap.set("n", "<leader>ok", links.copy_link_to_block, opts("[o]bsidian: copy link to bloc[k]"))
		end,
	})
end

return M
