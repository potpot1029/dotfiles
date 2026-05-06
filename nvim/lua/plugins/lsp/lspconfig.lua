return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		vim.lsp.config("*", {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
		})

		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local map = function(modes, keys, action, desc)
					vim.keymap.set(modes, keys, action, { buffer = ev.buf, silent = true, desc = desc })
				end

				-- navigation
				map("n", "gd", function()
					require("telescope.builtin").lsp_definitions({ reuse_win = true })
				end, "[g]o to [d]efinition")
				map("n", "gD", vim.lsp.buf.declaration, "[g]o to [D]eclaration")
				map("n", "gR", function()
					require("telescope.builtin").lsp_references({ reuse_win = true })
				end, "[g]o to [R]eferences")
				map("n", "gi", function()
					require("telescope.builtin").lsp_implementations({ reuse_win = true })
				end, "[g]o to [i]mplementation")
				map("n", "gy", function()
					require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
				end, "[g]o to t[y]pe definition")

				-- diagnostics
				map("n", "[d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, "prev diagnostic")
				map("n", "]d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, "next diagnostic")
				map("n", "<leader>e", vim.diagnostic.open_float, "show line diagnostics")
				map("n", "<leader>D", function()
					require("telescope.builtin").diagnostics({ bufnr = 0 })
				end, "buffer [D]iagnostics")

				-- actions
				map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "code action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "rename")

				-- docs
				map("n", "K", vim.lsp.buf.hover, "hover docs")
				map("i", "<C-s>", vim.lsp.buf.signature_help, "signature help")
			end,
		})

		vim.lsp.enable({
			"ts_ls", "html", "cssls", "emmet_ls",
			"lua_ls", "pyright", "clangd", "gopls", "sqls",
		})
	end,
}
