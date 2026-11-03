-- Wikilink / markdown-link highlighting in vault notes (matchadd, per window).
local vault = require("custom.obsidian.vault")

local M = {}

local function set_hl_groups()
	local c = require("synthweave.palette")
	local link = "#ff00ff"

	vim.api.nvim_set_hl(0, "WikiLinkBrackets", { fg = c.yellow })
	vim.api.nvim_set_hl(0, "WikiLinkTarget", { fg = link })
	vim.api.nvim_set_hl(0, "WikiLinkPipe", { fg = c.yellow })
	vim.api.nvim_set_hl(0, "WikiLinkAlias", { fg = link, bold = true })

	vim.api.nvim_set_hl(0, "MdLinkLabel", { fg = link, bold = true })
	vim.api.nvim_set_hl(0, "MdLinkUrl", { fg = link })
	vim.api.nvim_set_hl(0, "MdLinkPunct", { fg = c.yellow })
end

local function add_matches()
	vim.fn.matchadd("WikiLinkBrackets", [=[\[\[\|\]\]]=], 11)
	vim.fn.matchadd("WikiLinkTarget", [=[\[\[\zs[^|\]]\+\ze[|\]]]=], 12)
	vim.fn.matchadd("WikiLinkPipe", [=[\[\[[^\]]*\zs|\ze[^\]]*\]\]]=], 12)
	vim.fn.matchadd("WikiLinkAlias", [=[\[\[[^|\]]\+|\zs[^\]]\+\ze\]\]]=], 12)

	vim.fn.matchadd("MdLinkLabel", [=[\v\[\zs[^\]]+\ze\]\(]=], 12)
	vim.fn.matchadd("MdLinkUrl", [=[\v\]\(\zs[^)]+\ze\)]=], 12)
	vim.fn.matchadd("MdLinkPunct", [=[\v[\[\]()]]=], 11)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("obsidian_highlights", { clear = true })

	set_hl_groups()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl_groups })

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
		group = group,
		pattern = "*.md",
		callback = function(args)
			if vim.w.obsidian_matches_set or not vault.has_buf(args.buf) then
				return
			end
			vim.w.obsidian_matches_set = true
			add_matches()
		end,
	})
end

return M
