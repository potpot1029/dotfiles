-- Translate Obsidian's moment.js-style date/time tokens ({{date:...}},
-- {{time:...}}) into Lua os.date format and patch obsidian.nvim's template
-- substitution so those tokens render.
-- from https://github.com/SalarAlo/neovim_configuration/blob/main/lua/salar/core/obsidian.lua
local M = {}

local function translate_obsidian_datetime_format(format)
	local tokens = {
		{ "YYYY", "%Y" },
		{ "YY", "%y" },
		{ "MMMM", "%B" },
		{ "MMM", "%b" },
		{ "MM", "%m" },
		{ "M", "%-m" },
		{ "dddd", "%A" },
		{ "ddd", "%a" },
		{ "DD", "%d" },
		{ "D", "%-d" },
		{ "HH", "%H" },
		{ "H", "%-H" },
		{ "hh", "%I" },
		{ "h", "%-I" },
		{ "mm", "%M" },
		{ "ss", "%S" },
		{ "A", "%p" },
		{ "a", "__SALAR_OBSIDIAN_LOWER_AMPM__" },
	}

	local chunks = {}
	local i = 1

	while i <= #format do
		local char = format:sub(i, i)

		if char == "[" then
			local close_idx = format:find("]", i + 1, true)

			if close_idx then
				chunks[#chunks + 1] = format:sub(i + 1, close_idx - 1)
				i = close_idx + 1
			else
				chunks[#chunks + 1] = char
				i = i + 1
			end
		else
			local matched = false

			for _, token in ipairs(tokens) do
				local source, target = token[1], token[2]

				if format:sub(i, i + #source - 1) == source then
					chunks[#chunks + 1] = target
					i = i + #source
					matched = true
					break
				end
			end

			if not matched then
				chunks[#chunks + 1] = char
				i = i + 1
			end
		end
	end

	return table.concat(chunks)
end

local function render_obsidian_datetime(format)
	local strftime_format = translate_obsidian_datetime_format(format)
	local rendered = os.date(strftime_format)

	return rendered:gsub("__SALAR_OBSIDIAN_LOWER_AMPM__", function()
		return os.date("%p"):lower()
	end)
end

function M.patch_template_substitutions()
	if vim.g.salar_obsidian_template_patch_applied then
		return
	end

	local ok, templates = pcall(require, "obsidian.templates")

	if not ok then
		return
	end

	local original = templates.substitute_template_variables

	templates.substitute_template_variables = function(text, client, note)
		text = text:gsub("{{date:([^}]+)}}", function(format)
			return render_obsidian_datetime(format)
		end)
		text = text:gsub("{{time:([^}]+)}}", function(format)
			return render_obsidian_datetime(format)
		end)

		return original(text, client, note)
	end

	vim.g.salar_obsidian_template_patch_applied = true
end

return M
