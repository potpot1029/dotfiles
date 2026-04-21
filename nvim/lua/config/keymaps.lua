local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with 'jk'" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- split window
keymap.set("n", "ss", ":split<Return><C-w>w", opts)
keymap.set("n", "sv", ":vsplit<Return><C-w>w", opts)
keymap.set("n", "sx", "<cmd>close<CR>", opts)

-- move to window
keymap.set("", "<leader>s", "", { desc = "move to windows" })
keymap.set("", "<leader>sh", "<C-w>h", { desc = "Move to left window" })
keymap.set("", "<leader>sk", "<C-w>k", { desc = "Move to down window" })
keymap.set("", "<leader>sj", "<C-w>j", { desc = "Move to up window" })
keymap.set("", "<leader>sl", "<C-w>l", { desc = "Move to right window" })

-- resize window
keymap.set("n", "<C-w>e", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<C-w><left>", "<C-w><", { desc = "Split grow left" })
keymap.set("n", "<C-w><right>", "<C-w>>", { desc = "Split grow right" })
keymap.set("n", "<C-w><up>", "<C-w>+", { desc = "Split grow up" })
keymap.set("n", "<C-w><down>", "<C-w>-", { desc = "Split grow down" })
