-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>sy", function()
  local symbol = vim.fn.input("Symbol: ")
  if symbol ~= "" then
    require("telescope.builtin").live_grep({
      prompt_title = "Symbol Definitions",
      default_text = string.format("^(class|def)\\s+%s", symbol),
      additional_args = function()
        return { "--type", "py", "--multiline" }
      end,
    })
  end
end, { desc = "Find symbol definitions" })
