vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" })

local lint = require("lint")

lint.linters_by_ft = {
	python = { "pylint" },
	javascript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescript = { "eslint_d" },
	typescriptreact = { "eslint_d" },
	go = { "golangci-lint" },
	markdown = { "markdownlint" },
}

-- Disable MD013 (line length) and MD025 (multiple top-level headings). Prepend to
-- the linter's default args so stdin handling is preserved.
local markdownlint = lint.linters.markdownlint
markdownlint.args = vim.list_extend({ "--disable", "MD013", "MD025" }, markdownlint.args or {})

-- Create autocommand which carries out the actual linting
-- on the specified events.
local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		-- Only run the linter in buffers that you can modify in order to
		-- avoid superfluous noise, notably within the handy LSP pop-ups that
		-- describe the hovered symbol using Markdown.
		if vim.bo.modifiable then
			lint.try_lint()
		end
	end,
})
