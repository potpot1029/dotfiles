-- Orchestrates the Obsidian setup: configures obsidian.nvim when the cwd is in
-- the vault, and wires the vault-only highlights and keymaps.
local M = {}

local vault_path = vim.fn.expand("~/vaults/the-pot")
local vault_real = vim.fn.resolve(vault_path)

-- Whether `bufnr` is a file inside the vault.
local function in_vault(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	if bufname == "" then
		return false
	end
	local real = vim.fn.resolve(bufname)
	return vim.startswith(real, vault_real .. "/") or vim.startswith(bufname, vault_real .. "/")
end

-- Highlight groups for the wikilink/markdown-link matchadd patterns below.
local function apply_highlights()
	local c = require("synthweave.palette")

	vim.api.nvim_set_hl(0, "WikiLinkBrackets", { fg = c.yellow, underline = false })
	vim.api.nvim_set_hl(0, "WikiLinkTarget", { fg = "#ff00ff", italic = false, underline = false })
	vim.api.nvim_set_hl(0, "WikiLinkPipe", { fg = c.yellow, underline = false })
	vim.api.nvim_set_hl(0, "WikiLinkAlias", { fg = "#ff00ff", bold = true, underline = false })

	vim.api.nvim_set_hl(0, "MdLinkLabel", { fg = "#ff00ff", bold = true, underline = false })
	vim.api.nvim_set_hl(0, "MdLinkUrl", { fg = "#ff00ff", italic = false, underline = false })
	vim.api.nvim_set_hl(0, "MdLinkPunct", { fg = c.yellow, underline = false })
end

-- Per-window matchadd highlighting of wikilinks and markdown links in vault notes.
local function setup_matchadd()
	local group = vim.api.nvim_create_augroup("obsidian_matchadd", { clear = true })

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
		group = group,
		pattern = "*.md",
		callback = function(args)
			if not in_vault(args.buf) then
				return
			end

			-- Avoid duplicate matchadds in the same window
			if vim.w.obsidian_matches_set then
				return
			end
			vim.w.obsidian_matches_set = true

			-- Wikilinks
			vim.fn.matchadd("WikiLinkBrackets", [=[\[\[\|\]\]]=], 11)
			vim.fn.matchadd("WikiLinkTarget", [=[\[\[\zs[^|\]]\+\ze[|\]]]=], 12)
			vim.fn.matchadd("WikiLinkPipe", [=[\[\[[^\]]*\zs|\ze[^\]]*\]\]]=], 12)
			vim.fn.matchadd("WikiLinkAlias", [=[\[\[[^|\]]\+|\zs[^\]]\+\ze\]\]]=], 12)

			-- Markdown links
			vim.fn.matchadd("MdLinkLabel", [=[\v\[\zs[^\]]+\ze\]\(]=], 12)
			vim.fn.matchadd("MdLinkUrl", [=[\v\]\(\zs[^)]+\ze\)]=], 12)
			vim.fn.matchadd("MdLinkPunct", [=[\v[\[\]()]]=], 11)
		end,
	})
end

function M.setup()
	-- Full obsidian.nvim setup only when working inside the vault.
	if vim.startswith(vim.fn.resolve(vim.fn.getcwd()), vault_real) then
		require("obsidian").setup(require("custom.obsidian.config").build(vault_path))
		require("custom.obsidian.datetime").patch_template_substitutions()
		apply_highlights()
	end

	setup_matchadd()
	require("custom.obsidian.keymaps").setup(in_vault, require("custom.obsidian.links"), vault_path)
end

return M
