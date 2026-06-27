local keymap = vim.keymap

local default_keymaps = {
	{
		keys = "grd",
		func = "<cmd>Telescope lsp_references<CR>",
		desc = "[g]o to [d]efinition",
		has = "definitionProvider",
	},
	{ keys = "grD", func = vim.lsp.buf.declaration, desc = "[g]o to [D]eclaration", has = "declarationProvider" },
	{ keys = "gri", func = "<cmd>Telescope lsp_implementations<CR>", desc = "[g]o to [i]mplementation" },
	{ keys = "grt", func = "<cmd>Telescope lsp_type_definitions<CR>", desc = "[g]o to [t]ype definition" },
	{ keys = "grr", func = "<cmd>Telescope lsp_references<CR>", desc = "[g]o to [R]eference" },
	{ keys = "gra", func = vim.lsp.buf.code_action, desc = "code [a]ctions" },
	{ keys = "grn", func = vim.lsp.buf.rename, desc = "smart [r]e[n]ame" },
	{ keys = "<leader>k", func = vim.lsp.buf.hover, desc = "hover docs", has = "hoverProvider" },
	{ keys = "K", func = vim.lsp.buf.hover, desc = "hover docs", has = "hoverProvider" },
	{ keys = "<leader>d", func = vim.diagnostic.open_float, desc = "show line diagnostics" },
	{ keys = "<leader>D", func = "<cmd>Telescope diagnostics bufnr=0<CR>", desc = "show buffer diagnostics" },
}

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", {}),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local buf = args.buf

		if client then
			if client:supports_method("textDocument/documentHighlight", buf) then
				local highlight_augroup = vim.api.nvim_create_augroup("user_lsp_highlight", { clear = false })
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.document_highlight,
				})

				vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
					buffer = buf,
					group = highlight_augroup,
					callback = vim.lsp.buf.clear_references,
				})

				vim.api.nvim_create_autocmd("LspDetach", {
					group = vim.api.nvim_create_augroup("user_lsp_detach", { clear = true }),
					callback = function(event2)
						vim.lsp.buf.clear_references()
						vim.api.nvim_clear_autocmds({ group = "user_lsp_highlight", buffer = event2.buf })
					end,
				})
			end

			if client:supports_method("textDocument/inlayHint", buf) then
				vim.keymap.set("n", "<leader>th", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }))
				end, { desc = "[t]oggle Inlay [h]ints" })
			end

			for _, km in ipairs(default_keymaps) do
				-- Only bind if there's no `has` requirement, or the server supports it
				if not km.has or client.server_capabilities[km.has] then
					vim.keymap.set(
						km.mode or "n",
						km.keys,
						km.func,
						{ buffer = buf, desc = "LSP: " .. km.desc, nowait = km.nowait }
					)
				end
			end
		end
	end,
})

vim.lsp.enable({
	"gopls",
	"lua_ls",
	"ts_ls",
	"html",
	"cssls",
	"basedpyright",
	"clangd",
	"marksman",
	"tailwindcss",
	"dockerls",
	-- java has separate config
})

if vim.g.lsp_on_demands then
	vim.lsp.enable(vim.g.lsp_on_demands)
end
