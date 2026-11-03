local M = {}

M.path = vim.fn.expand("~/vaults/pot")
M.real = vim.fn.resolve(M.path)
M.name = vim.fs.basename(M.path)

local function inside(path)
	return path == M.real or vim.startswith(path, M.real .. "/")
end

function M.has_buf(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return name ~= "" and (inside(name) or inside(vim.fn.resolve(name)))
end

function M.has_cwd()
	return inside(vim.fn.resolve(vim.fn.getcwd()))
end

return M
