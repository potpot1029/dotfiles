return {
	"akinsho/bufferline.nvim",
	lazy = false,
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	keys = {
		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "delete buffers to the right" },
		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "delete buffers to the left" },
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "prev buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "next buffer" },
	},
	config = function()
		require("bufferline").setup({
			options = {
				diagnostics = "nvim_lsp",
				themable = true,
				offsets = {
					{
						filetype = "neo-tree",
						text = "file explorer",
						highlight = "Directory",
						text_align = "left",
						separator = true,
					},
				},
			},
		})
	end,
}
