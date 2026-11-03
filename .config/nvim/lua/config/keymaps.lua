local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with 'jk'" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- select all
keymap.set("n", "<C-a>", "gg<S-v>G", { desc = "select all" })

-- split window
keymap.set("n", "<leader>w-", ":split<Return><C-w>w", { desc = "split horizontally" })
keymap.set("n", "<leader>w|", ":vsplit<Return><C-w>w", { desc = "split vertically" })
keymap.set("n", "<leader>wx", "<cmd>close<CR>", { desc = "close split" })

-- move to pane
keymap.set("", "<leader>wh", "<C-w>h", { desc = "move to left window" })
keymap.set("", "<leader>wk", "<C-w>k", { desc = "move to up window" })
keymap.set("", "<leader>wj", "<C-w>j", { desc = "move to down window" })
keymap.set("", "<leader>wl", "<C-w>l", { desc = "move to right window" })

-- resize window
keymap.set("n", "<leader>we", "<C-w>=", { desc = "make splits equal size" })
keymap.set("n", "<leader>w<left>", "<C-w>>", { desc = "split grow left" })
keymap.set("n", "<leader>w<right>", "<C-w><", { desc = "split grow right" })
keymap.set("n", "<leader>w<up>", "<C-w>+", { desc = "split grow up" })
keymap.set("n", "<leader>w<down>", "<C-w>-", { desc = "split grow down" })

-- plugins
keymap.set("n", "<leader>pu", function()
	vim.pack.update()
end, { desc = "[p]ack [u]pdate plugins" })

local function pack_clean()
	local unused = {}
	for _, plugin in ipairs(vim.pack.get()) do
		if not plugin.active then
			table.insert(unused, plugin.spec.name)
		end
	end
	if #unused == 0 then
		print("No unused plugins.")
		return
	end
	print("Would remove: " .. table.concat(unused, ", "))
	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then
		vim.pack.del(unused)
	end
end

keymap.set("n", "<leader>pc", pack_clean, { desc = "[p]ack [c]lean unused plugins" })
