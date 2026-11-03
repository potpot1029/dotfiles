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
	-- jdtls is started manually by nvim-jdtls (plugin/jdtls.lua). Excluding it here
	-- prevents mason-lspconfig's automatic_enable from ALSO starting the bundled
	-- native jdtls config, which would attach a second client (rooted at the .git
	-- repo instead of the maven module) and double every codelens.
	automatic_enable = { exclude = { "jdtls" } },
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
		"dockerls",
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
		"ruff",
		"eslint_d",
		"markdownlint",
		-- java debug/test bundles (consumed by nvim-jdtls)
		"java-test",
		"java-debug-adapter",
	},
})
