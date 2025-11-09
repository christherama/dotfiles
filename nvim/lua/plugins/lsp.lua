return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly", -- keep this
                useLibraryCodeForTypes = false, -- disable this for speed
                indexing = true, -- ensure indexing is on
                typeCheckingMode = "basic", -- reduce type checking overhead
              },
            },
          },
        },
      },
    },
  },
}
