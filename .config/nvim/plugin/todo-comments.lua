vim.pack.add({
	"https://github.com/folke/todo-comments.nvim",
	-- dependency
	"https://github.com/nvim-lua/plenary.nvim",
})

require("todo-comments").setup()
