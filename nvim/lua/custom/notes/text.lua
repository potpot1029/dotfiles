-- Pure string helpers shared between the blink completion source and the
-- obsidian config. No buffer/file access lives here.
local M = {}

function M.trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Filename/heading -> URL-ish slug: lowercase, drop punctuation, spaces/periods
-- collapse to single hyphens.
function M.slugify(text)
	local slug = text:lower()
	slug = slug:gsub("[^a-z0-9%s-]", "")
	slug = slug:gsub("[%s%.]+", "-") -- whitespace OR periods → hyphen
	slug = slug:gsub("%-+", "-")
	slug = slug:gsub("^%-", "")
	slug = slug:gsub("%-$", "")

	return slug
end

-- Heading text -> human-readable alias: strip markdown (headings markers, list
-- numbering, code/bold/italic, trailing parens, wikilink syntax) and the
-- characters that would break an `[[note|alias]]` link, then squash separators
-- to spaces. Truncated to ~48 chars with an ellipsis.
function M.make_alias(heading)
	local alias = heading

	alias = alias:gsub("^#+%s*", "")
	alias = alias:gsub("^%d+[%.)]%s*", "")
	alias = alias:gsub("`([^`]*)`", "%1")
	alias = alias:gsub("%*%*([^%*]*)%*%*", "%1")
	alias = alias:gsub("%*([^%*]*)%*", "%1")
	alias = alias:gsub("_([^_]*)_", "%1")
	alias = alias:gsub("%s*%b()$", "")
	alias = alias:gsub("%[%[([^%]|]+)|?[^%]]*%]%]", "%1")
	alias = alias:gsub("[#*_~]", "")
	alias = alias:gsub("[%[%]|]", "") -- strip chars that would break [[..|alias]]
	alias = alias:gsub("[/%-_]+", " ")
	alias = alias:gsub("%s+", " ")
	alias = M.trim(alias)

	if #alias > 48 then
		alias = alias:sub(1, 45):gsub("%s+%S*$", "") .. "…"
	end

	return alias
end

-- Note id/filename -> display alias: drop a leading timestamp/id prefix and turn
-- separators into spaces (e.g. "1779610268-obsidian-setup" -> "obsidian setup").
function M.make_note_alias(note)
	local alias = note

	alias = alias:gsub("^%d+[-_ ]*", "")
	alias = alias:gsub("[_%-%/]+", " ")
	alias = alias:gsub("%s+", " ")
	alias = M.trim(alias)

	return alias
end

-- The display alias for a heading link: "Note Title › Clean Heading".
function M.heading_alias(note_title, raw_heading)
	return ("%s › %s"):format(note_title, M.make_alias(raw_heading))
end

-- A trailing Obsidian block id like " ^my-block" (caret not captured).
M.BLOCK_ID_PATTERN = "%^([%w][%w-]*)%s*$"

math.randomseed(os.time())

function M.new_block_id()
	return ("%06x"):format(math.random(0xffffff))
end

return M
