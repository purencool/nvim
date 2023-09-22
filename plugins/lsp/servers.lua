local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
	return
end

local rust_tools_setup, rust_tools = pcall(require, "rust-tools")
if not rust_tools_setup then
	return
end

local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
	return
end

local typescript_setup, typescript = pcall(require, "typescript")
if not typescript_setup then
	return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
local on_attach = function(client, bufnr)
	-- keybind options
	local opts = { noremap = true, silent = true, buffer = bufnr }

	-- set keybinds
	keymap.set("n", "gf", "<cmd>Lspsaga lsp_finder<CR>", opts) -- show definition, references
	keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts) -- got to declaration
	keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>", opts) -- see definition and make edits in window
	keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts) -- go to implementation
	keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts) -- see available code actions
	keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts) -- smart rename
	keymap.set("n", "<leader>D", "<cmd>Lspsaga show_line_diagnostics<CR>", opts) -- show  diagnostics for line
	keymap.set("n", "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>", opts) -- show diagnostics for cursor
	keymap.set("n", "pd", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts) -- jump to previous diagnostic in buffer
	keymap.set("n", "nd", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts) -- jump to next diagnostic in buffer
	keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts) -- show documentation for what is under cursor
	keymap.set("n", "<leader>lo", "<cmd>LSoutlineToggle<CR>", opts) -- see outline on right hand side

	-- typescript specific keymaps (e.g. rename file and update imports)
	if client.name == "tsserver" then
		keymap.set("n", "<leader>gD", ":TypescriptGoToSourceDefinition<CR>") -- go to definition
		keymap.set("n", "<leader>rf", ":TypescriptRenameFile<CR>") -- rename file and update imports
		keymap.set("n", "<leader>oi", ":TypescriptOrganizeImports<CR>") -- organize imports
		keymap.set("n", "<leader>ru", ":TypescriptRemoveUnused<CR>") -- remove unused variables
	end

	if client.name == "solidity" then
		keymap.set("n", "<leader>gD", ":Lspsaga goto_definition <CR>") -- go to definition
	end

	if client.name == "pyright" then
		keymap.set("n", "<Leader>oi", "<cmd>PyrightOrganizeImports<CR>", {
			buffer = bufnr,
			silent = true,
			noremap = true,
		})
	end

	if client.name == "rust_analyzer" then
		vim.keymap.set("n", "<Leader>k", rust_tools.hover_actions.hover_actions, opts)
		vim.keymap.set("n", "<Leader>ca", rust_tools.code_action_group.code_action_group, opts)
		vim.keymap.set("n", "K", rust_tools.hover_actions.hover_actions, opts)
	end
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- configure rust server
rust_tools.setup({
	server = {
		capabilities = capabilities,
		on_attach = on_attach,
	},
	filetypes = { "rust" },
	tools = {
		hover_actions = {
			auto_focus = true,
		},
	},
})

-- configure efm server
lspconfig.efm.setup({
	filetypes = { "solidity" },
	init_options = { documentFormatting = true },
	settings = {
		languages = {
			solidity = {
				{
					lintStdin = true,
					lintIgnoreExitCode = true,
					lintCommand = "solhint -f stylish stdin",
					lintFormats = {
						-- " %#" is equivalent to regex "\s*"  i.e. any number of whitespace.
						-- "%l" matches line number in the output of solhint (needed to align the error on the right line number, otherwise they bunch up at 0)
						-- "%c" matches column number
						-- "%t" matches [wWeEnN] for warning, error, and note.  (changes color of diagnostic)
						-- "%m" catches everything else for the body of the error.
						" %#%l:%c %#%tarning %#%m",
						" %#%l:%c %#%trror %#%m",
						" %#%l:%c %#%tote %#%m",
						" %#%l:%c %m",
					},
					lintSource = "solhint",
				},
			},
		},
	},
})

-- configure html server
lspconfig.html.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "html" },
})

-- config tailwindcss server
lspconfig.tailwindcss.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "html", "typescriptreact", "javascriptreact", "svelte" },
})

-- configure python server
lspconfig.pyright.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		pyright = {
			disableOrganizeImports = false,
			analysis = {
				useLibraryCodeForTypes = true,
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				autoImportCompletions = true,
			},
		},
	},
})

-- configure typescript server with plugin
typescript.setup({
	disable_commands = false, -- prevent the plugin from creating Vim commands
	debug = false, -- enable debug logging for commands
	go_to_source_definition = {
		fallback = true, -- fall back to standard LSP definition on failure
	},
	server = {
		capabilities = capabilities,
		on_attach = on_attach,
	},
})

-- configure solidity server
lspconfig.solidity.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "solidity" },
})

-- configure css server
lspconfig.cssls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure emmet language server
lspconfig.emmet_ls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
})

-- configure docker server
lspconfig.dockerls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure vim server
lspconfig.vimls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure lua server
lspconfig.lua_ls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = { -- custom settings for lua
		Lua = {
			-- make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make language server aware of runtime files
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
})
