vim.pack.add({
	{
		src = "https://github.com/ThePrimeagen/harpoon",
		version = "harpoon2",
	},
	"https://github.com/nvim-lua/plenary.nvim",
})

local harpoon = require("harpoon")

harpoon.setup()

vim.keymap.set("n", "<leader>hA", function()
	harpoon:list():prepend()
end, { desc = "add to the start of harpoon list" })
vim.keymap.set("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "add to the end of harpoon list" })
vim.keymap.set("n", "<leader>hw", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "open harpoon window" })

vim.keymap.set("n", "<M-1>", function()
	harpoon:list():select(1)
end)
vim.keymap.set("n", "<M-2>", function()
	harpoon:list():select(2)
end)
vim.keymap.set("n", "<M-3>", function()
	harpoon:list():select(3)
end)
vim.keymap.set("n", "<M-4>", function()
	harpoon:list():select(4)
end)
