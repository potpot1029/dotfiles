vim.pack.add({ { src = "https://github.com/folke/persistence.nvim" } })

require("persistence").setup()

vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.fn.argc() == 0 then
			require("persistence").load()
		end
	end,
})
vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
	callback = function()
		require("persistence").save()
	end,
})

vim.keymap.set("n", "<leader>qs", function()
	require("persistence").load()
end, { desc = "[q]uick [s]ession restore (cwd)" })
vim.keymap.set("n", "<leader>ql", function()
	require("persistence").load({ last = true })
end, { desc = "[q]uick session restore [l]ast" })
