local ok, jdtls = pcall(require, "jdtls")
if not ok then
	return
end


local jdtls_dir = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
if vim.fn.isdirectory(jdtls_dir) == 0 then
	vim.notify("jdtls not installed. Run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end
local launcher_jar = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar")

local os_config = vim.fn.has("mac") == 1 and "config_mac"
	or vim.fn.has("win32") == 1 and "config_win"
	or "config_linux"

-- unique workspace per project so jdtls keeps separate caches
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls/workspace/" .. project_name

jdtls.start_or_attach({
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher_jar,
		"-configuration",
		jdtls_dir .. "/" .. os_config,
		"-data",
		workspace_dir,
	},
	root_dir = vim.fs.dirname(
		vim.fs.find({ "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" }, { upward = true })[1]
	),
	settings = {
		java = {
			eclipse = { downloadSources = true },
			maven = { downloadSources = true },
			configuration = { updateBuildConfiguration = "interactive" },
		},
		signatureHelp = { enabled = true },
	},
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
})
