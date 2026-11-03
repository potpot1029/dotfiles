local function paste_link()
	local clip = vim.fn.getreg("+")
	if clip == "" then
		return
	end

	clip = clip:gsub("^%s+", ""):gsub("%s+$", "")
	local is_url = clip:match("^https?://%S+$") ~= nil
	local mode = vim.api.nvim_get_mode().mode

	-- visual: replace the selection with [selection](clipboard)
	if mode == "v" or mode == "V" then
		vim.cmd('noautocmd normal! "zy')
		local selection = vim.fn.getreg("z")
		vim.cmd('normal! gv"_c[' .. selection .. "](" .. clip .. ")")
		return
	end

	-- normal / insert: URL becomes [](url) with the cursor in the label
	if is_url then
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		local after = mode == "n"
		vim.api.nvim_put({ "[](" .. clip .. ")" }, "c", after, false)
		vim.api.nvim_win_set_cursor(0, { row, col + 1 })
		if mode == "n" then
			vim.cmd("startinsert")
		end
	else
		vim.api.nvim_put({ clip }, "c", mode == "n", true)
	end
end

vim.keymap.set({ "n", "i" }, "<C-g>t", function()
	vim.api.nvim_put({ "**" .. vim.fn.strftime("%H:%M") .. "**" }, "c", false, true)
end, { buffer = true, desc = "insert current time" })
vim.keymap.set({ "n", "i", "x" }, "<C-g>p", paste_link, { buffer = true, desc = "paste URL as markdown link" })

-- Bold/italic in normal mode: select the word under the cursor and reuse
-- markdowny's visual-mode formatters (toggles the markers on/off).
vim.keymap.set("n", "<C-b>", function()
	vim.cmd("normal! viw")
	require("markdowny").bold()
end, { buffer = true, silent = true, desc = "toggle bold on word" })

vim.keymap.set("n", "<C-i>", function()
	vim.cmd("normal! viw")
	require("markdowny").italic()
end, { buffer = true, silent = true, desc = "toggle italic on word" })

vim.g.markdown_recommended_style = 0

vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldlevel = 99
vim.opt_local.foldenable = true

vim.opt_local.wrap = true
vim.opt_local.linebreak = true
