-- telescope-fzf-native ships C source; compile it whenever it is installed/updated
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(args)
		local data = args.data
		if data and data.spec.name == "telescope-fzf-native.nvim" and data.kind ~= "delete" then
			vim.system({ "make" }, { cwd = data.path })
		end
	end,
})

vim.pack.add({
	"https://github.com/nvim-telescope/telescope.nvim",
	-- dependencies
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	-- optional
	"https://github.com/nvim-telescope/telescope-file-browser.nvim",
	"https://github.com/nvim-telescope/telescope-ui-select.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
})

local telescope = require("telescope")
local actions = require("telescope.actions")
local fb_actions = telescope.extensions.file_browser.actions
local builtin = require("telescope.builtin")

local note_entry = require("custom.obsidian.entry")

telescope.setup({
	defaults = {
		wrap_results = true,
		layout_strategy = "vertical",
		layout_config = { prompt_position = "top" },
		sorting_strategy = "ascending",
	},
	pickers = {
		diagnostics = {
			theme = "ivy",
			initial_mode = "normal",
			layout_config = {
				preview_cutoff = 9999,
			},
		},
		find_files = {
			entry_maker = note_entry.entry_maker,
		},
		lsp_references = { jump_type = "never" },
		lsp_definitions = { jump_type = "never" },
		lsp_implementations = { jump_type = "never" },
		lsp_type_definitions = { jump_type = "never" },
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
		file_browser = {
			theme = "dropdown",
			hijack_netrw = true,
			mappings = {
				["n"] = {
					["N"] = fb_actions.create,
					["h"] = fb_actions.goto_parent_dir,
					["/"] = function()
						vim.cmd("startinsert")
					end,
					["<C-u>"] = function(prompt_bufnr)
						for _ = 1, 10 do
							actions.move_selection_previous(prompt_bufnr)
						end
					end,
					["<C-d>"] = function(prompt_bufnr)
						for _ = 1, 10 do
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

-- load extensions
pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "file_browser")
pcall(telescope.load_extension, "ui-select")

-- keymaps
vim.keymap.set("n", "<leader>sf", function()
	builtin.find_files({
		no_ignore = false,
		hidden = true,
	})
end, { desc = "[s]earch [f]iles (show hidden + .gitignore)" })
vim.keymap.set("n", "<leader>sg", function()
	builtin.live_grep({
		additional_args = { "--hidden" },
	})
end, { desc = "[s]earch by [g]rep" })

vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[s]earch current [w]ord" })
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[s]earch [h]elp" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[s]earch [r]esume" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[s]earch [k]eymaps" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[s]earch [d]iagnostics" })
vim.keymap.set("n", "<leader>st", builtin.treesitter, { desc = "[s]earch [t]reesitter" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] find existing buffers" })

vim.keymap.set("n", "<leader>sb", function()
	telescope.extensions.file_browser.file_browser({
		path = "%:p:h",
		cwd = vim.fn.expand("%:p:h"),
		respect_gitignore = false,
		hidden = true,
		grouped = true,
		previewer = false,
		initial_mode = "normal",
		layout_config = { height = 40 },
	})
end, { desc = "[s]earch file [b]rowser" })
