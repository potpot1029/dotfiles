-- Buffer/file helpers for reading markdown notes, shared between the blink
-- completion source and the obsidian config.
local text = require("custom.notes.text")

local M = {}

-- "/vault/1779610268_my-note.md" -> "1779610268_my-note"
function M.note_id_from_path(path)
	return vim.fn.fnamemodify(path, ":t:r")
end

-- Vault root for the current buffer, falling back to cwd.
function M.get_root()
	return vim.fs.root(0, { ".obsidian", ".git" }) or vim.fn.getcwd()
end

-- All markdown files under `root`.
function M.scan_md_files(root)
	return vim.fs.find(function(name, _)
		return name:match("%.md$")
	end, {
		path = root,
		type = "file",
		limit = 10000,
	})
end

-- The loaded buffer backing `path`, or nil.
function M.buf_for_path(path)
	local target = vim.fn.fnamemodify(path, ":p")
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(b) then
			local name = vim.api.nvim_buf_get_name(b)
			if name ~= "" and vim.fn.fnamemodify(name, ":p") == target then
				return b
			end
		end
	end
	return nil
end

-- Prefer a loaded buffer's live lines (so block line numbers stay in sync with
-- what `ensure_block_id` will edit); fall back to reading the file from disk.
function M.read_lines(path)
	local bufnr = M.buf_for_path(path)
	if bufnr then
		return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	end

	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end

	return lines
end

-- First non-empty H1 (`# title`) in `lines`, or nil.
function M.title_from_lines(lines)
	for _, line in ipairs(lines) do
		local title = line:match("^#%s+(.+)$")
		if title then
			title = text.trim(title)
			if title ~= "" then
				return title
			end
		end
	end

	return nil
end

-- All ATX headings outside code fences: { level = n, title = "..." }.
function M.read_headings(lines)
	local headings = {}
	local in_fence = false
	local fence_marker = nil -- track which delimiter opened the fence (``` or ~~~)

	for _, line in ipairs(lines) do
		-- Detect fence boundaries (lines starting with ``` or ~~~)
		local fence = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
		if fence then
			if not in_fence then
				-- Opening fence
				in_fence = true
				fence_marker = fence:sub(1, 1) -- remember whether it was ` or ~
			elseif line:match("^%s*" .. fence_marker:rep(3)) then
				-- Closing fence — must match the opener's character
				in_fence = false
				fence_marker = nil
			end
		-- Skip the fence line itself (don't treat it as content)
		elseif not in_fence then
			-- Only check for headings when outside a fence
			local hashes, title = line:match("^%s*(#+)%s+(.+)$")
			if hashes and title then
				title = text.trim(title)
				if title ~= "" then
					table.insert(headings, {
						level = #hashes,
						title = title,
					})
				end
			end
		end
	end

	return headings
end

-- Ensure the line at `line_nr` of note `path` ends with a block id, creating one
-- if missing. Operates on the loaded buffer when present (no save), otherwise on
-- the file on disk. Returns the block id (without the caret).
function M.ensure_block_id(path, line_nr, content)
	local bufnr = M.buf_for_path(path)

	local lines
	if not bufnr then
		local ok, l = pcall(vim.fn.readfile, path)
		if not ok then
			return text.new_block_id()
		end
		lines = l
	end

	local function line_at(n)
		if bufnr then
			return (vim.api.nvim_buf_get_lines(bufnr, n - 1, n, false))[1]
		end
		return lines[n]
	end

	-- Locate the target line; fall back to matching by content if it drifted.
	local target = line_nr
	local cur = line_at(target)
	if not cur or text.trim((cur:gsub(text.BLOCK_ID_PATTERN, ""))) ~= content then
		local total = bufnr and vim.api.nvim_buf_line_count(bufnr) or #lines
		for n = 1, total do
			local l = line_at(n)
			if l and text.trim((l:gsub(text.BLOCK_ID_PATTERN, ""))) == content then
				target, cur = n, l
				break
			end
		end
	end
	if not cur then
		return text.new_block_id()
	end

	-- Already tagged? reuse the existing id.
	local existing = cur:match(text.BLOCK_ID_PATTERN)
	if existing then
		return existing
	end

	local id = text.new_block_id()
	local new_line = cur:gsub("%s*$", "") .. " ^" .. id
	if bufnr then
		vim.api.nvim_buf_set_lines(bufnr, target - 1, target, false, { new_line })
	else
		lines[target] = new_line
		pcall(vim.fn.writefile, lines, path)
	end
	return id
end

return M
