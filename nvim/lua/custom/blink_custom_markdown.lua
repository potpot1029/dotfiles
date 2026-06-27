local text = require("custom.notes.text")
local scan = require("custom.notes.scan")

local source = {}

local Kind = require("blink.cmp.types").CompletionItemKind

function source.new(opts)
	local self = setmetatable({}, { __index = source })
	self.opts = opts or {}
	return self
end

function source:enabled()
	return vim.bo.filetype == "markdown"
end

function source:get_trigger_characters()
	return { "[", "#", "|", "^" }
end

-- the typed query characters must appear in `text` as an in-order
-- subsequence: characters may be skipped, but their order must be preserved
-- (case-insensitive). Whitespace in the query is ignored.
local function matches_in_order(haystack, query)
	if not query or query == "" then
		return true
	end
	haystack = (haystack or ""):lower()
	local pos = 1
	for ch in query:lower():gmatch("%S") do
		local s = haystack:find(ch, pos, true) -- plain find: safe for magic chars
		if not s then
			return false
		end
		pos = s + 1
	end
	return true
end

local EXACT_BONUS = 1000
local PREFIX_BONUS = 100

-- normalize for exact/prefix comparison: lowercase, drop all non-alphanumerics
-- so "My Heading", "my-heading", and "myheading" all compare equal (consistent
-- with matches_in_order ignoring whitespace).
local function normalize_match(s)
	return (s or ""):lower():gsub("[^%w]", "")
end

-- score bump to float the best matches to the top: an exact match (whole query
-- equals a target) outranks a prefix match (a target starts with the query).
-- Accepts multiple targets (e.g. heading title and slug) and takes the best.
local function rank_bonus(query, ...)
	local q = normalize_match(query)
	if q == "" then
		return 0
	end
	local bonus = 0
	for _, target in ipairs({ ... }) do
		local t = normalize_match(target)
		if t == q then
			return EXACT_BONUS
		elseif t:sub(1, #q) == q then
			bonus = PREFIX_BONUS
		end
	end
	return bonus
end

-- a note is "identified" (for heading mode) by its title or an alias,
-- never by filename/id alone
local function note_identified(note, query)
	-- heading search requires a real note: an empty/blank note part identifies
	-- nothing, so don't spray every note's headings.
	if not query or text.trim(query) == "" then
		return false
	end
	-- re-entering an existing link: the note part is the exact note id
	if text.trim(query):lower() == note.id:lower() then
		return true
	end
	if matches_in_order(note.title, query) then
		return true
	end
	for _, alias in ipairs(note.aliases) do
		if matches_in_order(alias, query) then
			return true
		end
	end
	return false
end

-- Collect referenceable blocks: every content line (skipping frontmatter, code
-- fences and ATX headings) becomes a block candidate. `id` is the existing
-- trailing ^id if present, otherwise nil (created on accept).
local function read_blocks(lines)
	local blocks = {}
	local in_fence = false
	local fence_marker = nil
	local in_frontmatter = false

	for idx, line in ipairs(lines) do
		if idx == 1 and line == "---" then
			in_frontmatter = true
		elseif in_frontmatter then
			if line == "---" then
				in_frontmatter = false
			end
		else
			local fence = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
			if fence then
				if not in_fence then
					in_fence = true
					fence_marker = fence:sub(1, 1)
				elseif line:match("^%s*" .. fence_marker:rep(3)) then
					in_fence = false
					fence_marker = nil
				end
			elseif not in_fence then
				-- skip blank lines and headings (those are heading refs)
				if not line:match("^%s*$") and not line:match("^%s*#+%s") then
					local id = line:match(text.BLOCK_ID_PATTERN)
					local block_text = text.trim((line:gsub(text.BLOCK_ID_PATTERN, "")))
					if block_text ~= "" then
						table.insert(blocks, { text = block_text, id = id, line = idx })
					end
				end
			end
		end
	end

	return blocks
end

local function read_aliases(lines)
	local aliases = {}

	-- Frontmatter must start at line 1 with `---`
	if lines[1] ~= "---" then
		return aliases
	end

	local in_aliases = false
	for i = 2, #lines do
		local line = lines[i]

		-- End of frontmatter
		if line == "---" then
			break
		end

		-- Detect start of aliases field
		local inline = line:match("^aliases:%s*%[(.-)%]%s*$")
		if inline then
			-- Inline list: aliases: [a, b, c]
			for item in inline:gmatch("[^,]+") do
				local clean = text.trim(item):gsub("^[\"']", ""):gsub("[\"']$", "")
				if clean ~= "" then
					table.insert(aliases, clean)
				end
			end
			in_aliases = false
		elseif line:match("^aliases:%s*$") then
			-- Block list: aliases: \n  - a \n  - b
			in_aliases = true
		elseif in_aliases then
			local item = line:match("^%s*%-%s+(.+)$")
			if item then
				item = text.trim(item):gsub("^[\"']", ""):gsub("[\"']$", "")
				if item ~= "" then
					table.insert(aliases, item)
				end
			else
				-- Non-list line ends the aliases block
				in_aliases = false
			end
		end
	end

	return aliases
end

local function build_note_index(root)
	local notes = {}

	for _, file in ipairs(scan.scan_md_files(root)) do
		local id = scan.note_id_from_path(file)
		local lines = scan.read_lines(file)
		local title = scan.title_from_lines(lines) or text.make_note_alias(id)
		local aliases = read_aliases(lines)

		table.insert(notes, {
			id = id,
			path = file,
			title = title,
			aliases = aliases,
			headings = scan.read_headings(lines),
			blocks = read_blocks(lines),
		})
	end

	return notes
end

local function get_context(ctx)
	local line = ctx.line or vim.api.nvim_get_current_line()
	local cursor = ctx.cursor or vim.api.nvim_win_get_cursor(0)
	local cursor_line, cursor_col = unpack(cursor)

	-- ctx.cursor: line is 1-indexed, column is 0-indexed
	local before = line:sub(1, cursor_col)
	local after = line:sub(cursor_col + 1)

	-- Find the latest unfinished [[... before cursor.
	local start_col_1based, query = before:match(".*()%[%[([^%]]*)$")

	if not start_col_1based or query == nil then
		return nil
	end

	-- Remove existing alias part from the query if user already has:
	-- [[note|alias
	-- [[note|alias#
	--
	-- For matching, only the link target before | matters.
	local target_query = query:match("^([^|]*)") or query

	-- Split on the first `#`. A suffix starting with `^` is a block link
	-- ([[note#^id]]); otherwise it's a heading link ([[note#heading]]).
	local note_query, sub = query:match("^(.-)#(.*)$")
	local is_heading_link, is_block_link = false, false
	local heading_query, block_query = "", ""

	if note_query ~= nil then
		if sub:sub(1, 1) == "^" then
			is_block_link = true
			block_query = sub:sub(2)
		else
			is_heading_link = true
			heading_query = sub
		end
	else
		note_query = target_query
	end

	-- Consume the remainder of an existing link (e.g. re-entering to add a
	-- heading) so accepting replaces the whole [[...]] instead of leaving a
	-- trailing |alias]] behind. Falls back to the plain autopaired ]] case.
	local end_col = cursor_col
	local rest = after:match("^([^%]]*%]%])")
	if rest then
		end_col = cursor_col + #rest
	end

	return {
		cursor_line = cursor_line,
		cursor_col = cursor_col,
		start_col = start_col_1based - 1,
		end_col = end_col,

		query = query,
		target_query = target_query,

		is_heading_link = is_heading_link,
		is_block_link = is_block_link,
		note_query = note_query or "",
		heading_query = heading_query or "",
		block_query = block_query or "",
	}
end

local function make_item(wiki, label, insert_text, filter_text, sort_text, description, score_offset)
	return {
		label = label,
		kind = Kind.Reference,
		score_offset = score_offset,

		insertText = insert_text,
		insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,

		textEdit = {
			newText = insert_text,
			range = {
				start = {
					line = wiki.cursor_line - 1,
					character = wiki.start_col,
				},
				["end"] = {
					line = wiki.cursor_line - 1,
					character = wiki.end_col,
				},
			},
		},

		filterText = filter_text,
		sortText = sort_text,
		label_description = description or "Wiki",

		detail = "Obsidian",

		documentation = {
			kind = "markdown",
			value = "```md\n" .. insert_text .. "\n```",
		},
	}
end

function source:get_completions(ctx, callback)
	local wiki = get_context(ctx)

	if not wiki then
		callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
		return
	end

	local root = scan.get_root()
	local notes = build_note_index(root)
	local items = {}

	for _, note in ipairs(notes) do
		-- Build the "all searchable text" for this note: id, title, aliases
		local note_haystack = note.id

		if wiki.is_block_link then
			-- Block mode: `[[note#^query]]`. The note part selects the note; the
			-- part after `#^` filters its blocks by an in-order match of the block
			-- text or existing id. Blocks without an id get one created on accept.
			if note_identified(note, wiki.note_query) then
				for idx, block in ipairs(note.blocks) do
					if
						matches_in_order(block.text, wiki.block_query)
						or (block.id and matches_in_order(block.id, wiki.block_query))
					then
						local alias = text.heading_alias(note.title, block.text)
						-- block links carry no |alias, just [[note#^id]]
						local insert_text = ("[[%s#^%s]]"):format(note.id, block.id or "")

						local item = make_item(
							wiki,
							"[[" .. alias .. "]]",
							insert_text, -- finalized in :execute (id may be generated)
							block.text .. " " .. (block.id or ""),
							("%s %04d"):format(note.title, idx),
							"Block",
							rank_bonus(wiki.block_query, block.text, block.id or "")
						)
						item.data = {
							kind = "block",
							note_id = note.id,
							path = note.path,
							line = block.line,
							text = block.text,
							id = block.id,
						}
						table.insert(items, item)
					end
				end
			end
		elseif wiki.is_heading_link then
			-- Heading mode: the part before `#` selects the note (by title or
			-- alias, in order — never filename alone), the part after filters
			-- headings *within* that note by an in-order match of the heading
			-- title or its slug.
			if note_identified(note, wiki.note_query) then
				for idx, heading in ipairs(note.headings) do
					local heading_slug = text.slugify(heading.title)
					if
						matches_in_order(heading.title, wiki.heading_query)
						or matches_in_order(heading_slug, wiki.heading_query)
					then
						local full_haystack = note_haystack .. "#" .. heading_slug
						local alias = text.heading_alias(note.title, heading.title)
						local insert_text = ("[[%s#%s|%s]]"):format(note.id, heading_slug, alias)

						table.insert(
							items,
							make_item(
								wiki,
								"[[" .. alias .. "]]",
								insert_text,
								full_haystack,
								-- group per note, then order by document position
								("%s %04d"):format(note.title, idx),
								"Heading",
								rank_bonus(wiki.heading_query, heading.title, heading_slug)
							)
						)
					end
				end
			end
		else
			-- Non-heading mode: keep the note only when the query is an in-order
			-- match of the title itself (not scattered words, not filename-only).
			if matches_in_order(note.title, wiki.note_query) then
				local insert_text = ("[[%s|%s]]"):format(note.id, note.title)
				table.insert(
					items,
					make_item(
						wiki,
						"[[" .. note.title .. "]]",
						insert_text,
						note_haystack,
						note.title,
						"Note",
						rank_bonus(wiki.note_query, note.title)
					)
				)
			end

			-- Aliases match independently: surface an alias when the query is an
			-- in-order match of that alias, even if the title doesn't match.
			for _, alias_name in ipairs(note.aliases) do
				if alias_name ~= note.title and matches_in_order(alias_name, wiki.note_query) then
					local insert_text2 = ("[[%s|%s]]"):format(note.id, alias_name)
					table.insert(
						items,
						make_item(
							wiki,
							"[[" .. alias_name .. "]]",
							insert_text2,
							note_haystack,
							alias_name,
							"Alias",
							rank_bonus(wiki.note_query, alias_name)
						)
					)
				end
			end
		end
	end

	callback({
		items = items,
		is_incomplete_forward = false,
		is_incomplete_backward = false,
	})
end

-- On accept: for block items, resolve/create the block id in the target note and
-- finalize the inserted link before applying the edit.
function source:execute(_, item, resolve, default_implementation)
	local d = item.data
	if d and d.kind == "block" then
		local id = d.id or scan.ensure_block_id(d.path, d.line, d.text)
		item.textEdit.newText = ("[[%s#^%s]]"):format(d.note_id, id)
	end
	default_implementation()
	resolve()
end

return source
