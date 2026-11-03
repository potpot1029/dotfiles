-- Open vault notes in the Obsidian app too (toggle with :ObsidianFollow).
local vault = require("custom.obsidian.vault")

local M = {}

local OBSIDIAN_CLASS = "md.obsidian.Obsidian"

-- Hyprland's Lua config: `hyprctl dispatch` takes a Lua expression.
local function hyprctl(args)
	return vim.system(vim.list_extend({ "hyprctl" }, args), { text = true }):wait()
end

local function hypr_json(what)
	local res = hyprctl({ what, "-j" })
	local ok, data = pcall(vim.json.decode, res.code == 0 and res.stdout or "")
	return ok and data or nil
end

local function special_shown()
	for _, mon in ipairs(hypr_json("monitors") or {}) do
		if mon.specialWorkspace and mon.specialWorkspace.name == "special:obsidian" then
			return true
		end
	end
	return false
end

-- hypr/modules/rules.lua gives Obsidian `focus_on_activate` (wanted for links
-- from other apps), so after opening, wait for Obsidian to take focus and hand
-- it back, re-hiding special:obsidian if it was hidden.
local function open_keep_focus(uri)
	if not vim.env.HYPRLAND_INSTANCE_SIGNATURE or vim.fn.executable("hyprctl") == 0 then
		vim.ui.open(uri)
		return
	end

	local active = hypr_json("activewindow")
	local addr = active and active.address
	local was_shown = special_shown()
	vim.ui.open(uri)
	if not addr then
		return
	end

	local tries = 0
	local timer = assert(vim.uv.new_timer())
	timer:start(
		100,
		100,
		vim.schedule_wrap(function()
			tries = tries + 1
			local now = hypr_json("activewindow")
			local stolen = now and now.class == OBSIDIAN_CLASS
			if not stolen and tries < 15 then
				return
			end
			timer:stop()
			timer:close()
			if stolen then
				if not was_shown and special_shown() then
					hyprctl({ "dispatch", 'hl.dsp.workspace.toggle_special("obsidian")' })
				end
				hyprctl({ "dispatch", ('hl.dsp.focus({ window = "address:%s" })'):format(addr) })
			end
		end)
	)
end

function M.setup()
	vim.g.obsidian_follow = vim.g.obsidian_follow ~= false
	local pending = 0

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("obsidian_follow", { clear = true }),
		pattern = "*.md",
		callback = function(args)
			if not vim.g.obsidian_follow or not vault.has_buf(args.buf) then
				return
			end
			-- `path=` (not `vault=<name>`): Obsidian knows other vaults named "pot"
			local uri = "obsidian://open?path="
				.. vim.uri_encode(vim.fn.resolve(vim.api.nvim_buf_get_name(args.buf)), "rfc3986")
			-- debounce: a session restore or `nvim a.md b.md` opens only the last note
			pending = pending + 1
			local token = pending
			vim.defer_fn(function()
				if token == pending then
					open_keep_focus(uri)
				end
			end, 200)
		end,
	})

	vim.api.nvim_create_user_command("ObsidianFollow", function()
		vim.g.obsidian_follow = not vim.g.obsidian_follow
		vim.notify("Open notes in Obsidian: " .. (vim.g.obsidian_follow and "on" or "off"))
	end, { desc = "Toggle opening vault notes in the Obsidian app" })
end

return M
