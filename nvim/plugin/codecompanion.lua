vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	-- nvim-treesitter / nvim-web-devicons are provided by treesitter.lua / lualine.lua
	"https://github.com/OXY2DEV/markview.nvim",
	{
		src = "https://github.com/olimorris/codecompanion.nvim",
		version = vim.version.range("^19.0.0"),
	},
})

require("markview").setup({
	preview = {
		-- only render CodeCompanion chat buffers
		filetypes = { "codecompanion" },

		-- CodeCompanion chat may use a non-normal buftype,
		-- so don't ignore special buffers
		ignore_buftypes = {},
	},
})

require("codecompanion").setup({
	adapters = {
		acp = {
			codex = function()
				return require("codecompanion.adapters").extend("codex", {
					defaults = {
						-- current codex-acp auth method id
						auth_method = "chat-gpt",
					},

					env = {
						-- make codex-acp see the same auth cache as your shell
						HOME = os.getenv("HOME"),
						CODEX_HOME = os.getenv("HOME") .. "/.codex",

						-- force the ACP side to pick ChatGPT auth automatically
						DEFAULT_AUTH_REQUEST = vim.json.encode({
							methodId = "chat-gpt",
						}),
					},
				})
			end,

			claude_code = function()
				return require("codecompanion.adapters").extend("claude_code", {
					env = {
						CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN",
					},
				})
			end,
		},
	},

	interactions = {
		chat = {
			adapter = "codex",
		},
		cli = {
			agent = "codex",
			agents = {
				codex = {
					cmd = "codex",
					args = {},
					description = "OpenAI Codex CLI",
				},
				claude_code = {
					cmd = "claude",
					args = {},
					description = "Claude Code CLI",
				},
			},
		},
	},
})

-- lua/keymaps/codecompanion.lua

local map = vim.keymap.set

local chat_adapters = {
	{ label = "Claude Code", adapter = "claude_code" },
	{ label = "Codex", adapter = "codex" },
}

local cli_agents = {
	{ label = "Claude Code", agent = "claude_code" },
	{ label = "Codex", agent = "codex" },
}

local function choose(items, prompt, callback)
	vim.ui.select(items, {
		prompt = prompt,
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end

		callback(choice)
	end)
end

-- ============================================================================
-- actions
-- ============================================================================

map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", {
	desc = "ai actions",
})

-- ============================================================================
-- chat
-- ============================================================================

map("n", "<leader>ac", function()
	choose(chat_adapters, "choose chat adapter", function(choice)
		vim.cmd("CodeCompanionChat adapter=" .. choice.adapter)
	end)
end, {
	desc = "choose ai chat",
})

map("n", "<leader>aC", "<cmd>CodeCompanionChat adapter=claude_code<cr>", {
	desc = "chat with claude code",
})

map("n", "<leader>aO", "<cmd>CodeCompanionChat adapter=codex_chatgpt<cr>", {
	desc = "chat with codex",
})

map("n", "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", {
	desc = "toggle ai chat",
})

-- visual selection -> add as context to current chat
map("x", "<leader>a+", ":'<,'>CodeCompanionChat Add<cr>", {
	desc = "add selection to ai chat",
})

-- ============================================================================
-- cli
-- ============================================================================

map("n", "<leader>al", function()
	choose(cli_agents, "choose cli agent", function(choice)
		vim.cmd("CodeCompanionCLI agent=" .. choice.agent)
	end)
end, {
	desc = "choose ai cli",
})

map("n", "<leader>aL", "<cmd>CodeCompanionCLI agent=claude_code<cr>", {
	desc = "open claude code cli",
})

map("n", "<leader>ao", "<cmd>CodeCompanionCLI agent=codex<cr>", {
	desc = "open codex cli",
})

-- rich prompt input for selected agent
map({ "n", "v" }, "<leader>ap", function()
	choose(cli_agents, "prompt cli agent", function(choice)
		vim.cmd("CodeCompanionCLI agent=" .. choice.agent .. " Ask")
	end)
end, {
	desc = "prompt chosen ai cli",
})

-- send current buffer / visual selection to chosen cli
map({ "n", "v" }, "<leader>a=", function()
	choose(cli_agents, "send context to cli", function(choice)
		require("codecompanion").cli("#{this}", {
			agent = choice.agent,
			focus = false,
		})
	end)
end, {
	desc = "send context to chosen ai cli",
})

-- send diagnostics to chosen cli
map("n", "<leader>ax", function()
	choose(cli_agents, "fix diagnostics with", function(choice)
		require("codecompanion").cli("#{diagnostics} Fix these diagnostics.", {
			agent = choice.agent,
			focus = false,
			submit = true,
		})
	end)
end, {
	desc = "fix diagnostics with chosen ai cli",
})

-- send latest terminal output to chosen cli
map("n", "<leader>aT", function()
	choose(cli_agents, "send terminal output to", function(choice)
		require("codecompanion").cli("#{terminal} This is the latest terminal output. Explain the issue and fix it.", {
			agent = choice.agent,
			focus = false,
			submit = true,
		})
	end)
end, {
	desc = "send terminal output to chosen ai cli",
})

-- ============================================================================
-- command abbreviations
-- ============================================================================

vim.cmd([[cab cc CodeCompanion]])
vim.cmd([[cab ccc CodeCompanionChat]])
vim.cmd([[cab ccli CodeCompanionCLI]])
vim.cmd([[cab cca CodeCompanionActions]])
