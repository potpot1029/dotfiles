vim.pack.add({
	"https://github.com/nvim-mini/mini.ai",
	"https://github.com/nvim-mini/mini.surround",
})

require("mini.ai").setup({
	custom_textobjects = {
		L = { "%[%[().-()%]%]" }, -- L for wikiLinks
		M = { "%[().-()%]%b()" }, -- M for Markdown links
	},
	mappings = {
		goto_left = "g[",
		goto_right = "g]",
	},
})
require("mini.surround").setup({})
