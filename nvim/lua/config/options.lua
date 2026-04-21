vim.g.mapleader = " "

vim.cmd("autocmd!")

vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.number = true -- show line number
vim.opt.relativenumber = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.hlsearch = true -- highlight all search results
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 3
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.shell = "zsh"
vim.opt.backupskip = { "/tmp/", "/private/tmp/" }
vim.opt.inccommand = "split"
vim.opt.ignorecase = true -- case insensitive search
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = false -- no wrap lines
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.path:append({ "**" }) -- search down into subfolders when finding files
vim.opt.splitright = true -- split vertical window to the right
vim.opt.splitbelow = true -- split horizontal window to the bottom

vim.opt.clipboard:append("unnamedplus") -- use system clipboard as default register

vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.winblend = 0
vim.opt.wildoptions = "pum"
vim.opt.pumblend = 5
vim.opt.background = "dark"

-- add asterisks in block commends
vim.opt.formatoptions:append({ "r" })
