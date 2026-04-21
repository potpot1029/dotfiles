return {
	"folke/persistence.nvim",
	event = "BufReadPre", -- this will only start session saving when an actual file was opened
	opts = {
		-- add any custom options here
	},
	keys = {
		{
			"<leader>q",
			desc = "session",
		},
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "restore session",
		},
		{
			"<leader>qS",
			function()
				require("persistence").select()
			end,
			desc = "select session",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "restore last session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "don't save current session",
		},
	},
}
