return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      hidden = true,
      file_ignore_patterns = { "node_modules", ".git/", "dist" },
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob=!.git/*",
        "--glob=!node_modules/*",
        "--glob=!dist/*",
      },
    },
  },
}
