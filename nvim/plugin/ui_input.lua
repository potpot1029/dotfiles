-- Use the custom floating vim.ui.input (Noice-safe). vim.ui.select is handled by
-- telescope-ui-select (see plugin/telescope.lua).
vim.ui.input = require("custom.ui_input").input
