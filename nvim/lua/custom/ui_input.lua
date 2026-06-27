-- A small floating-window vim.ui.input. Unlike the native cmdline prompt it is a
-- real window/buffer, so typed text stays visible under Noice.
local M = {}

function M.input(opts, on_confirm)
	vim.validate({ on_confirm = { on_confirm, "function" } })
	opts = opts or {}
	local default = opts.default or ""
	-- Trim the trailing ": " convention so it reads well as a window title.
	local prompt = (opts.prompt or "Input"):gsub("%s*:?%s*$", "")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"

	local width = math.max(#default + 4, #prompt + 4, 30)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		row = 1,
		col = 0,
		width = width,
		height = 1,
		style = "minimal",
		border = "rounded",
		title = " " .. prompt .. " ",
	})
	vim.wo[win].winhighlight = "NormalFloat:Normal,FloatBorder:Comment"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })
	vim.cmd("startinsert")
	vim.api.nvim_win_set_cursor(win, { 1, #default })

	local done = false
	local function finish(value)
		if done then
			return
		end
		done = true
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		vim.schedule(function()
			on_confirm(value)
		end)
	end

	vim.keymap.set({ "i", "n" }, "<CR>", function()
		local value = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
		vim.cmd("stopinsert")
		finish(value)
	end, { buffer = buf })

	vim.keymap.set({ "i", "n" }, "<Esc>", function()
		vim.cmd("stopinsert")
		finish(nil)
	end, { buffer = buf })

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		once = true,
		callback = function()
			finish(nil)
		end,
	})
end

return M
