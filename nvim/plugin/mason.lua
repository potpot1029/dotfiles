vim.pack.add({
	"https://github.com/williamboman/mason.nvim",
	-- dependencies
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
})

require("mason").setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

require("mason-lspconfig").setup({
	-- list of servers for mason to install
	ensure_installed = {
		"gopls",
		"lua_ls",
		"clangd",
		"basedpyright",
		"ts_ls",
		"html",
		"cssls",
		"tailwindcss",
		"jdtls",
		"marksman",
	},
})

require("mason-tool-installer").setup({
	ensure_installed = {
		-- formatter
		"prettier",
		"stylua",
		"isort",
		"black",
		"goimports",
		"sql-formatter",
		"google-java-format",
		-- linter
		"pylint",
		"eslint_d",
		"golangci-lint",
		"markdownlint",
		-- java debug/test bundles (consumed by nvim-jdtls)
		"java-test",
		"java-debug-adapter",
	},
})
