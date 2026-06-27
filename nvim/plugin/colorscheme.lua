vim.pack.add({ "https://github.com/samharju/synthweave.nvim" })

local synthweave = require("synthweave")
local c = require("synthweave.palette")
c.magenta = "#ff00ff"
synthweave.setup({
	transparent = true,
	overrides = {
		Statement = { bold = true, fg = c.yellow },
		DiagnosticError = { fg = c.red, italic = false },
		DiagnosticHint = { fg = c.gray, italic = false },
		DiagnosticInfo = { fg = c.carrot, italic = false },
		DiagnosticOk = { fg = c.green_bright, italic = false },
		DiagnosticVirtualTextError = { fg = c.red, italic = false, bg = c.bg1 },
		DiagnosticVirtualTextHint = { fg = c.gray, italic = false, bg = c.bg1 },
		DiagnosticVirtualTextInfo = { fg = c.carrot, italic = false, bg = c.bg1 },
		DiagnosticVirtualTextOk = { fg = c.green_bright, italic = false, bg = c.bg1 },
		DiagnosticVirtualTextWarn = { fg = c.yellow, italic = false, bg = c.bg1 },
		DiagnosticWarn = { fg = c.yellow, italic = false },

		TelescopePromptPrefix = { fg = c.magenta },

		["@markup"] = { fg = c.cyan },
		["@markup.strong"] = { fg = c.cyan, bold = true },
		["@markup.italic"] = { fg = c.yellow, italic = true },
		["@markup.heading"] = { fg = c.yellow },
		["@markup.link"] = { underline = false },

		["@property.yaml"] = { fg = c.cyan, bold = true },
		["@string.yaml"] = { fg = c.magenta, bold = false },
		["@number.yaml"] = { fg = c.magenta, bold = false },
		["@boolean.yaml"] = { fg = c.magenta, bold = false },
		["@punctuation.delimiter.yaml"] = { fg = c.gray, italic = false, bold = false },
		["@punctuation.special.yaml"] = { fg = c.gray, italic = true, bold = false },
	},
})
synthweave.load()
