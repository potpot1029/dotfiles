vim.pack.add({
	{ src = "https://github.com/Saghen/blink.lib" },
	{ src = "https://github.com/Saghen/blink.cmp", version = "2.*" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/Kaiser-Yang/blink-cmp-dictionary" },
})

require("luasnip.loaders.from_lua").lazy_load({
	paths = vim.fn.stdpath("config") .. "/snippets",
})

local cmp = require("blink.cmp")

-- true when the cursor sits inside an unclosed [[ wiki link
local function in_wikilink()
	local col = vim.fn.col(".") - 1
	local before = vim.api.nvim_get_current_line():sub(1, col)
	return before:match("%[%[[^%]]*$") ~= nil
end

cmp.setup({
	keymap = {
		["<c-x>"] = { "show", "show_documentation", "hide_documentation" },
		["<c-e>"] = { "cancel", "fallback" },
		["<tab>"] = {
			"snippet_forward",
			"accept",
			"fallback",
		},
		["<c-y>"] = { "select_and_accept", "fallback" },
		["<cr>"] = { "select_and_accept", "fallback" },
		["<c-k>"] = { "select_prev", "fallback" },
		["<up>"] = { "select_prev", "fallback" },
		["<c-j>"] = { "select_next", "fallback" },
		["<down>"] = { "select_next", "fallback" },
	},

	snippets = { preset = "luasnip" },
	signature = { enabled = true },

	completion = {
		trigger = {
			show_on_trigger_character = true,
			show_on_blocked_trigger_characters = function()
				local col = vim.fn.col(".") - 1
				local before = vim.api.nvim_get_current_line():sub(1, col)
				-- inside an unclosed [[ wiki link? keep space un-blocked so the
				-- menu survives multi-word titles / headings
				if before:match("%[%[[^%]]*$") then
					return { "\n", "\t" }
				end
				return { " ", "\n", "\t" }
			end,
		},

		menu = {
			draw = {
				columns = {
					{ "kind_icon" },
					{ "label", "label_description", gap = 1 },
					{ "source_name" },
				},
			},
		},

		documentation = {
			auto_show = true,
			auto_show_delay_ms = 300,
		},
	},

	sources = {
		default = { "lsp", "path", "snippets", "buffer" },

		per_filetype = {
			markdown = {
				"obsidian",
				"lsp",
				"path",
				"snippets",
				"buffer",
				"dictionary",
			},
		},

		providers = {
			obsidian = {
				name = "Obsidian",
				module = "custom.blink_custom_markdown",
				min_keyword_length = 0,
				score_offset = 200, -- sit above the LSP (100) inside [[ ]]
			},
			dictionary = {
				module = "blink-cmp-dictionary",
				name = "Dict",
				min_keyword_length = 3,
				opts = {
					dictionary_files = { vim.fn.stdpath("config") .. "/dictionary/en.txt" },
				},
			},
			lsp = {
				min_keyword_length = 0, -- show suggestions even with zero chars
				score_offset = 100,
				transform_items = function(_, items)
					if not in_wikilink() then
						return items
					end
					-- the custom Obsidian source already provides note-link matches;
					-- from the LSP keep only the "(create)" item for missing notes
					return vim.tbl_filter(function(item)
						return type(item.label) == "string" and item.label:find("%(create%)") ~= nil
					end, items)
				end,
			},
		},
	},
	fuzzy = {
		implementation = "prefer_rust_with_warning",
		sorts = function()
			-- inside [[ ]], rank by score before exact so the custom Obsidian
			-- source (higher score_offset) sits above the LSP's exact-flagged
			-- (create) item
			if in_wikilink() then
				return { "score", "exact", "sort_text", "label" }
			end
			return { "exact", "score", "sort_text", "label" }
		end,
		max_typos = function(keyword)
			-- inside an unclosed [[ wiki link, match strictly in-order (no typos)
			-- so e.g. "#ch-1" doesn't fuzzily keep "#ch-4"
			if in_wikilink() then
				return 0
			end
			return math.floor(#keyword / 4) -- blink default elsewhere
		end,
	},
})
