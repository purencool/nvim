return {
	"nvim-tree/nvim-tree.lua",
	lazy = false,
	config = function()
		vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])
		require("nvim-tree").setup({
			filters = {
				dotfiles = true,
			},
			view = {
				adaptive_size = true,
			},
        git = {
    ignore = false,
  },
		})
	end,
}
