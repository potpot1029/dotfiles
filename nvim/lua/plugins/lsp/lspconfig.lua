return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"nvim-telescope/telescope.nvim",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- ---------------------------------------------
		-- diagnostics
		-- ---------------------------------------------
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- ---------------------------------------------
		-- keymaps
		-- ---------------------------------------------

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
				map("n", "gR", function()
					require("telescope.builtin").lsp_references({ reuse_win = true })
				end, "[g]o to [R]eferences")
				map("n", "gi", function()
					require("telescope.builtin").lsp_implementations({ reuse_win = true })
				end, "[g]o to [i]mplementation")
				map("n", "gy", function()
					require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
				end, "[g]o to t[y]pe definition")

				-- actions
				map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "code action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "rename")

				-- docs
				map("n", "K", vim.lsp.buf.hover, "hover docs")
			end,
		})

		local servers = {
			clangd = {},
			gopls = {},
			pyright = {},
			rust_analyzer = {},
			svelte = {
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					vim.api.nvim_create_autocmd("BufWritePost", {
						pattern = { "*.js", "*.ts" },
						callback = function(ctx)
							-- Here use ctx.match instead of ctx.file
							client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
						end,
					})
				end,
			},
			lua_ls = {
				capabilities = capabilities,
				settings = {
					Lua = {
						-- make the language server recognize "vim" global
						diagnostics = {
							globals = { "vim" },
						},
						completion = {
							callSnippet = "Replace",
						},
					},
				},
			},
			emmet_ls = {
				capabilities = capabilities,
				filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
			},
			graphql = {
				capabilities = capabilities,
				filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
			},
			jdtls = {
				capabilities = capabilities,
				filetypes = { "java" },
			},
		}

		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					local server = servers[server_name] or {}
					-- This handles overriding only values explicitly passed
					-- by the server configuration above. Useful when disabling
					-- certain features of an LSP (for example, turning off formatting for tsserver)
					server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
					require("lspconfig")[server_name].setup(server)
				end,
			},
		})
	end,
}
