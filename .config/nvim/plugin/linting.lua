vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })

local lint = require("lint")

lint.linters_by_ft = {
	python = { "ruff" },
	javascript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescript = { "eslint_d" },
	typescriptreact = { "eslint_d" },
	markdown = { "markdownlint" },
}

-- Use the vault markdownlint config for markdown-specific style rules, while
-- keeping selected noisy rules disabled. Prepend args so stdin handling remains.
local markdownlint_config = vim.fn.expand("~/vaults/pot/.markdownlint.json")
if vim.uv.fs_stat(markdownlint_config) then
	local markdownlint = lint.linters.markdownlint
	markdownlint.args = vim.list_extend({ "--config", markdownlint_config }, markdownlint.args or {})
end

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		-- skip read-only buffers such as LSP hover popups
		if vim.bo.modifiable then
			lint.try_lint()
		end
	end,
})
