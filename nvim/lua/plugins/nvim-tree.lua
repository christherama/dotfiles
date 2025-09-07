return {
  "nvim-tree/nvim-tree.lua",
  opts = {
    filters = {
      dotfiles = false, -- show all dotfiles
      custom = {
        -- Hide other dotfiles/directories except .github
        -- For example, hide .git, .cache, .env but NOT .github
        ".git",
        ".cache",
        ".env",
        -- add other dotfiles you want hidden here
      },
    },
  },
}
