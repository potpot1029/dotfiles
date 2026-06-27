local function paste_link()
	local clip = vim.fn.getreg("+")
	if clip == "" then
		return
	end

	clip = clip:gsub("^%s+", ""):gsub("%s+$", "")
	local is_url = clip:match("^https?://%S+$") ~= nil
	local mode = vim.api.nvim_get_mode().mode

	-- ── Visual mode: wrap the selection ─────────────────────────────────
	if mode == "v" or mode == "V" then
		-- Yank selection into the unnamed register so we can read it
		vim.cmd('noautocmd normal! "zy')
		local selection = vim.fn.getreg("z")
		if not is_url then
			-- No URL on clipboard — paste clipboard as label, leave url empty
			vim.cmd('normal! gv"_c[' .. selection .. "](" .. clip .. ")")
			return
		end
		-- Replace the selection with [selection](url)
		vim.cmd('normal! gv"_c[' .. selection .. "](" .. clip .. ")")
		return
	end

	-- ── Normal / insert mode: paste empty-label link ────────────────────
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
end, { desc = "insert current time" })
vim.keymap.set({ "n", "i", "x" }, "<C-g>p", paste_link, { desc = "paste URL as markdown link" })

vim.g.markdown_recommended_style = 0

vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"
vim.opt.foldlevelstart = 99
vim.opt.foldlevel = 99
vim.opt.foldenable = true -- keep folds enabled so the expr runs, just default-open

vim.opt.wrap = true
vim.opt.linebreak = true -- line break
