local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local function build_table(_, parent)
	local cols = tonumber(parent.snippet.env.COLS) or 2
	local rows = tonumber(parent.snippet.env.ROWS) or 2

	local nodes = {}
	local idx = 1 -- insert-node counter

	-- Header row: | h1 | h2 | h3 |
	table.insert(nodes, t("| "))
	for col = 1, cols do
		table.insert(nodes, i(idx, "h" .. col))
		idx = idx + 1
		table.insert(nodes, col < cols and t(" | ") or t(" |"))
	end

	-- Separator: | --- | --- |
	table.insert(nodes, t({ "", "|" }))
	for _ = 1, cols do
		table.insert(nodes, t(" --- |"))
	end

	-- Body rows
	for _ = 1, rows do
		table.insert(nodes, t({ "", "| " }))
		for col = 1, cols do
			table.insert(nodes, i(idx, " "))
			idx = idx + 1
			table.insert(nodes, col < cols and t(" | ") or t(" |"))
		end
	end

	return sn(nil, nodes)
end

local function in_mathzone()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before = line:sub(1, col)
	-- Count unescaped $ before cursor; odd = inside math
	local count = 0
	for _ in before:gmatch("%$") do
		count = count + 1
	end
	return count % 2 == 1
end

return {
	s({ trig = "tbl(%d+)x(%d+)", regTrig = true, hidden = false }, {
		d(1, function(args, snip)
			snip.env.COLS = snip.captures[1]
			snip.env.ROWS = snip.captures[2]
			return build_table(args, snip)
		end),
	}),
	s(
		"co",
		fmt(
			[[
> [!{}] {}
> {}
{}]],
			{
				c(1, {
					t("note"),
					t("tip"),
					t("warning"),
					t("danger"),
					t("info"),
					t("question"),
					t("quote"),
					t("example"),
				}),
				i(2, "title"),
				i(3, "body"),
				i(0),
			}
		)
	),
	s(
		"t",
		f(function()
			return "**" .. os.date("%H:%M") .. "**"
		end)
	),
	s(
		"cb",
		fmt(
			[[
```{}
{}
```
{}]],
			{ i(1, "lang"), i(2), i(0) }
		)
	),
	s("->", { t("→") }),
	s("=>", { t("⇒") }),
	s("!=", { t("≠") }),
	s(">=", { t("≥") }),
	s("<=", { t("≤") }),
	--
	-- latex
	s("mk", fmt("${}${}", { i(1), i(0) })), -- inline math
	s("dm", fmt("$$\n{}\n$$\n{}", { i(1), i(0) })), -- display math
	s({ trig = "ff", condition = in_mathzone }, fmt("\\frac{{{}}}{{{}}}{}", { i(1), i(2), i(0) })),
	s(
		{ trig = "td", condition = in_mathzone }, -- to-the
		fmt("^{{{}}}{}", { i(1), i(0) })
	),
	s(
		{ trig = "sd", condition = in_mathzone }, -- subscript
		fmt("_{{{}}}{}", { i(1), i(0) })
	),
}
