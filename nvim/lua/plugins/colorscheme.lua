return {
	{
		"samharju/synthweave.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local synthweave = require("synthweave")
			local palette = require("synthweave.palette")
			synthweave.setup({
				transparent = true,
				overrides = {
					Statement = { bold = true, fg = palette.yellow },
				},
			})
			synthweave.load()
		end,
	},
}
