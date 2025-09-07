return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      -- adapter + helpers Neotest needs
      "nvim-neotest/neotest-python",
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/nvim-nio",
    },
    ft = { "python" },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "unittest", -- or omit to let it auto-detect
          dap = { justMyCode = false },
        },
      },
    },
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run file tests",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle test summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true })
        end,
        desc = "Show test output",
      },
    },
  },
}
