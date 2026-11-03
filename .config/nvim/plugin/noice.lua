vim.pack.add({
	"https://github.com/folke/noice.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/rcarriga/nvim-notify",
})

require("notify").setup({
	background_colour = "#000000",
})

require("noice").setup({
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
		signature = {
			enabled = false,
		},
	},
	routes = {
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
				},
			},
			view = "mini",
		},
	},
	views = {
		-- long prompts (e.g. W12 "file changed") wrap instead of running off-screen
		confirm = {
			win_options = { wrap = true, linebreak = false }, -- noice sizes the height assuming plain char wrap
		},
	},
	presets = {
		bottom_search = true,
		command_palette = true,
		long_message_to_split = true,
		inc_rename = false,
		lsp_doc_border = true,
	},
})

-- Noice centres confirm buttons with spaces measured against the longest
-- unwrapped line; for a long prompt (e.g. W12 with a file path) that padding
-- alone fills the popup and wraps the buttons out of view. Drop it then.
local formatters = require("noice.text.format.formatters")
local format_confirm = formatters.confirm
formatters.confirm = function(message, opts, input)
	format_confirm(message, opts, input)
	local texts = message.kind == "confirm" and message:last_line()._texts
	if texts and texts[1] and texts[1]:content():match("^ +$") and message:width() > vim.o.columns - 6 then
		table.remove(texts, 1)
	end
end

-- Noice attaches at VimEnter, so errors from before that (`+cmd` / `-c` args,
-- failing plugin files) never reach it. Re-show them once it's up.
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		-- only errors that were actually displayed; plugins can leave a
		-- pcall-swallowed one in v:errmsg
		local startup_msgs = vim.trim(vim.fn.execute("messages"))
		if not startup_msgs:find("E%d+:") and not startup_msgs:find("Error") then
			return
		end
		vim.schedule(function()
			vim.notify(startup_msgs, vim.log.levels.ERROR, { title = "Startup errors" })
		end)
	end,
})

-- Noice positions popups when they open; re-centre the visible ones on resize.
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		local ok, router = pcall(require, "noice.message.router")
		if not ok then
			return
		end
		for view in pairs(router.get_views()) do
			local win = view._nui and view._nui.winid
			if win and vim.api.nvim_win_is_valid(win) and not vim.api.nvim_win_get_config(win).hide then
				pcall(view.update_layout, view)
			end
		end
	end,
})
