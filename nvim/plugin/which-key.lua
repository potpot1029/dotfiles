vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
	-- Delay between pressing a key and opening which-key (milliseconds)
	delay = 0,
	icons = { mappings = vim.g.have_nerd_font },
	-- Document existing key chains
	spec = {
		{ "<leader>s", group = "[s]earch (Telescope)", mode = { "n", "v" } },
		{ "<leader>h", group = "[h]arpoon" },
		{ "<leader>w", group = "pane actions" },
		{ "<leader>o", group = "[o]bsidian" },
		{ "<leader>a", group = "[a]I/Claude Code" },
		{ "gr", group = "LSP actions", mode = { "n" } },
	},
})
