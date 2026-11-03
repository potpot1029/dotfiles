vim.pack.add({
	{ src = "https://github.com/Saghen/blink.lib" },
	{ src = "https://github.com/Saghen/blink.cmp", version = "main" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/Kaiser-Yang/blink-cmp-dictionary" },
})

require("luasnip.loaders.from_lua").lazy_load({
	paths = vim.fn.stdpath("config") .. "/snippets",
})

local cmp = require("blink.cmp")
cmp.build():pwait(300000)

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
			-- Blink v2 requires a static list. Leave spaces unblocked so the
			-- menu survives multi-word Obsidian titles and headings.
			show_on_blocked_trigger_characters = { "\n", "\t" },
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
				"lsp",
				"path",
				"snippets",
				"buffer",
				"dictionary",
			},
		},

		providers = {
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
			},
		},
	},
	fuzzy = {
		implementation = "prefer_rust_with_warning",
		sorts = {
			function(item_a, item_b)
				-- Blink v2 validates `sorts` as a list. Keep the old dynamic
				-- ordering in a supported custom comparator: wiki links rank
				-- provider score first; other completions rank exactness first.
				local fields = in_wikilink() and { "score", "exact" } or { "exact", "score" }
				for _, field in ipairs(fields) do
					local a, b = item_a[field], item_b[field]
					if a ~= b then
						if type(a) == "boolean" then
							return a
						end
						return (a or 0) > (b or 0)
					end
				end

				local a_sort = item_a.sort_text or item_a.label or ""
				local b_sort = item_b.sort_text or item_b.label or ""
				if a_sort ~= b_sort then
					return a_sort < b_sort
				end
				if item_a.label ~= item_b.label then
					return (item_a.label or "") < (item_b.label or "")
				end
				return nil
			end,
		},
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
