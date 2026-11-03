-- Backlinks picker: one header row per linking note (same look as find_files)
-- with its backlink lines indented beneath. Locations come from obsidian.nvim's
-- references handler, the same one `:Obsidian backlinks` uses.
local entry = require("custom.obsidian.entry")
local notes = require("custom.obsidian.note")

local M = {}

local function child_display(item)
	return function()
		return require("telescope.pickers.entry_display").create({
			separator = " ",
			items = { { width = 3 }, { width = 6 }, { remaining = true } },
		})({ "", { tostring(item.lnum), "Comment" }, notes.trim(item.text or "") })
	end
end

-- Flat entry list, grouped by linking note. Every row of a group shares one
-- `haystack`, so filtering shows or hides the group as a unit.
local function build_entries(items)
	local order, groups = {}, {}
	for _, item in ipairs(items) do
		if not groups[item.filename] then
			groups[item.filename] = {}
			table.insert(order, item.filename)
		end
		table.insert(groups[item.filename], item)
	end
	table.sort(order)

	local entries = {}
	local function add(e)
		e.sort_index = #entries + 1
		e.ordinal = tostring(e.sort_index)
		table.insert(entries, e)
	end

	for _, filename in ipairs(order) do
		local members = groups[filename]
		local display, title = entry.note_display(filename)

		local words = { title or vim.fn.fnamemodify(filename, ":.") }
		for _, item in ipairs(members) do
			table.insert(words, item.text or "")
		end
		local haystack = table.concat(words, " "):lower()

		add({ value = filename, filename = filename, lnum = 1, col = 0, display = display, haystack = haystack })
		for _, item in ipairs(members) do
			add({
				value = item,
				filename = item.filename,
				lnum = item.lnum,
				col = item.col,
				display = child_display(item),
				haystack = haystack,
			})
		end
	end

	return entries
end

-- Keep build order; hide rows whose group lacks any word of the prompt.
local function group_sorter()
	return require("telescope.sorters").new({
		scoring_function = function(_, prompt, _, e)
			for word in prompt:lower():gmatch("%S+") do
				if not e.haystack:find(word, 1, true) then
					return -1
				end
			end
			return e.sort_index
		end,
	})
end

function M.show()
	require("obsidian.lsp.handlers._references")(nil, { tag = false }, function(_, locations)
		local items = vim.lsp.util.locations_to_items(locations or {}, "utf-8")
		if vim.tbl_isempty(items) then
			vim.notify("No backlinks to this note", vim.log.levels.INFO)
			return
		end

		require("telescope.pickers")
			.new({}, {
				prompt_title = "Backlinks",
				finder = require("telescope.finders").new_table({
					results = build_entries(items),
					entry_maker = function(e)
						return e
					end,
				}),
				sorter = group_sorter(),
				previewer = require("telescope.config").values.qflist_previewer({}),
			})
			:find()
	end)
end

return M
