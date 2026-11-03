-- Helpers for vault notes: names, titles, headings, block ids.
local M = {}

M.BLOCK_ID_PATTERN = "%^([%w][%w-]*)%s*$"

math.randomseed(os.time())

function M.trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Note file name from a title, matching the Templater `slugify` in
-- <vault>/templates/new-file.md: "xxx (yyy)" / "xxx: yyy" -> "xxx_yyy", any other
-- run of non-alphanumerics -> "-". UTF-8 letters are kept.
function M.note_slug(title)
	local slug = title:lower()
	slug = slug:gsub("%s*[(:]", "_")
	slug = slug:gsub("[^%w_\128-\255]+", "-")
	slug = slug:gsub("%-*_%-*", "_")
	slug = slug:gsub("^[-_]+", "")
	slug = slug:gsub("[-_]+$", "")
	return slug
end

-- Plain-text label for a heading, safe inside [[...|label]].
local function heading_label(heading)
	local label = heading
	label = label:gsub("^#+%s*", "")
	label = label:gsub("^%d+[%.)]%s*", "")
	label = label:gsub("`([^`]*)`", "%1")
	label = label:gsub("%*%*([^%*]*)%*%*", "%1")
	label = label:gsub("%*([^%*]*)%*", "%1")
	label = label:gsub("_([^_]*)_", "%1")
	label = label:gsub("%s*%b()$", "")
	label = label:gsub("%[%[([^%]|]+)|?[^%]]*%]%]", "%1")
	label = label:gsub("[#*_~%[%]|]", "")
	label = label:gsub("[/%-_]+", " ")
	label = M.trim(label:gsub("%s+", " "))

	if #label > 48 then
		label = label:sub(1, 45):gsub("%s+%S*$", "") .. "…"
	end
	return label
end

-- "Note Title › Heading"
function M.heading_alias(note_title, heading)
	return ("%s › %s"):format(note_title, heading_label(heading))
end

function M.new_block_id()
	return ("%06x"):format(math.random(0xffffff))
end

-- "/vault/notes/my-note.md" -> "my-note"
function M.note_id_from_path(path)
	return vim.fn.fnamemodify(path, ":t:r")
end

function M.scan_md_files(root)
	return vim.fs.find(function(name)
		return name:match("%.md$")
	end, { path = root, type = "file", limit = 10000 })
end

-- First non-empty H1 in `lines`, or nil.
function M.title_from_lines(lines)
	for _, line in ipairs(lines) do
		local title = line:match("^#%s+(.+)$")
		title = title and M.trim(title)
		if title and title ~= "" then
			return title
		end
	end
end

-- ATX headings outside code fences: { { level = n, title = "..." }, ... }
function M.read_headings(lines)
	local headings = {}
	local fence_char -- "`" or "~" while inside a fence

	for _, line in ipairs(lines) do
		local fence = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
		if fence then
			if not fence_char then
				fence_char = fence:sub(1, 1)
			elseif fence:sub(1, 1) == fence_char then
				fence_char = nil
			end
		elseif not fence_char then
			local hashes, title = line:match("^%s*(#+)%s+(.+)$")
			title = title and M.trim(title)
			if title and title ~= "" then
				table.insert(headings, { level = #hashes, title = title })
			end
		end
	end

	return headings
end

return M
