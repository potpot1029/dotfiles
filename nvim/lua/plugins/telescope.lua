return {
	"nvim-telescope/telescope.nvim",
	version = "*",
	dependencies = {
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-file-browser.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{
			";f",
			function()
				local builtin = require("telescope.builtin")
				builtin.find_files({
					no_ignore = false,
					hidden = true,
				})
			end,
			desc = "lists files in your current working directory, respects .gitignore",
		},
		{
			";r",
			function()
				local builtin = require("telescope.builtin")
				builtin.live_grep({
					additional_args = { "--hidden" },
				})
			end,
			desc = "search for a string in your current working directory and get results live as you type, respects .gitignore",
		},
		{
			"\\\\",
			function()
				local builtin = require("telescope.builtin")
				builtin.buffers()
			end,
			desc = "lists open buffers",
		},
		{
			";t",
			function()
				local builtin = require("telescope.builtin")
				builtin.help_tags()
			end,
			desc = "lists available help tags and opens a new window with the relevant help info on <cr>",
		},
		{
			";;",
			function()
				local builtin = require("telescope.builtin")
				builtin.resume()
			end,
			desc = "resume the previous telescope picker",
		},
		{
			";e",
			function()
				local builtin = require("telescope.builtin")
				builtin.diagnostics()
			end,
			desc = "lists Diagnostics for all open buffers or a specific buffer",
		},
		{
			";s",
			function()
				local builtin = require("telescope.builtin")
				builtin.treesitter()
			end,
			desc = "lists Function names, variables, from Treesitter",
		},
		{
			"sf",
			function()
				local telescope = require("telescope")

				local function telescope_buffer_dir()
					return vim.fn.expand("%:p:h")
				end

				telescope.extensions.file_browser.file_browser({
					path = "%:p:h",
					cwd = telescope_buffer_dir(),
					respect_gitignore = false,
					hidden = true,
					grouped = true,
					previewer = false,
					initial_mode = "normal",
					layout_config = { height = 40 },
				})
			end,
			desc = "Open File Browser with the path of the current buffer",
		},
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local fb_actions = require("telescope").extensions.file_browser.actions

		telescope.setup({
			defaults = {
				wrap_results = true,
				layout_strategy = "flex",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
				mappings = {
					n = {},
				},
			},
			pickers = {
				diagnostics = {
					theme = "ivy",
					initial_mode = "normal",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
				lsp_references = { jump_type = "never" },
				lsp_definitions = { jump_type = "never" },
				lsp_implementations = { jump_type = "never" },
				lsp_type_definitions = { jump_type = "never" },
			},
			extensions = {
				file_browser = {
					theme = "dropdown",
					-- disables netrw and use telescope-file-browser in its place
					hijack_netrw = true,
					mappings = {
						-- your custom insert mode mappings
						["n"] = {
							-- your custom normal mode mappings
							["N"] = fb_actions.create,
							["h"] = fb_actions.goto_parent_dir,
							["/"] = function()
								vim.cmd("startinsert")
							end,
							["<C-u>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_previous(prompt_bufnr)
								end
							end,
							["<C-d>"] = function(prompt_bufnr)
								for i = 1, 10 do
									actions.move_selection_next(prompt_bufnr)
								end
							end,
							["<PageUp>"] = actions.preview_scrolling_up,
							["<PageDown>"] = actions.preview_scrolling_down,
						},
					},
				},
			},
		})

		require("telescope").load_extension("fzf")
		require("telescope").load_extension("file_browser")
	end,
}
