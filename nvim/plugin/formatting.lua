vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

local conform = require("conform")

conform.setup({
	format_on_save = {
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	},
	formatters_by_ft = {
		javascript = { "prettier" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		lua = { "stylua" },
		python = { "isort", "black" },
		sql = { "sql-formatter" },
		java = { "google-java-format" },
		go = { "goimports" },
	},
})

vim.keymap.set({ "n", "v" }, "<leader>f", function()
	conform.format({
		async = true,
	})
end, { desc = "[f]ormat buffer" })
