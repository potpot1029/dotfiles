vim.pack.add({
	"https://github.com/nvim-lualine/lualine.nvim",
	-- dependency
	"https://github.com/nvim-tree/nvim-web-devicons",
})

require("lualine").setup({
	options = {
		theme = "synthweave",
	},
})
