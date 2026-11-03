local vault = require("custom.obsidian.vault")

local M = {}

-- .png opens in nvim, .pdf in zathura on Linux, everything else as usual.
local function patch_ui_open()
	local original = vim.ui.open
	vim.ui.open = function(uri, opt)
		if vim.endswith(uri, ".png") then
			vim.cmd.edit(uri)
			return
		elseif vim.endswith(uri, ".pdf") and vim.fn.has("linux") == 1 then
			opt = { cmd = { "zathura" } }
		end
		return original(uri, opt)
	end
end

function M.setup()
	-- obsidian.nvim itself only when nvim was started inside the vault
	if vault.has_cwd() then
		require("obsidian").setup(require("custom.obsidian.config").build(vault))
	end

	patch_ui_open()
	require("custom.obsidian.highlights").setup()
	require("custom.obsidian.follow").setup()
	require("custom.obsidian.keymaps").setup()
end

return M
