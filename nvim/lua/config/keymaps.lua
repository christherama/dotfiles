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
-- Copy Python dotted path
vim.keymap.set("n", "<leader>yp", function()
  local ts = vim.treesitter
  local node = ts.get_node()

  -- Build symbol path from treesitter
  local parts = {}
  while node do
    local type = node:type()
    if type == "function_definition" or type == "class_definition" then
      local name_node = node:field("name")[1]
      if name_node then
        table.insert(parts, 1, ts.get_node_text(name_node, 0))
      end
    end
    node = node:parent()
  end

  -- Get project root from LSP
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local root = vim.fn.getcwd() -- fallback
  if clients[1] and clients[1].config.root_dir then
    root = clients[1].config.root_dir
  end

  -- Get module path from file path
  local filepath = vim.fn.expand("%:p")
  local relpath = filepath:gsub("^" .. vim.pesc(root) .. "/", ""):gsub("%.py$", ""):gsub("/", ".")

  local full_path = relpath .. "." .. table.concat(parts, ".")
  vim.fn.setreg("+", full_path)
  print("Copied: " .. full_path)
end, { desc = "Yank Python dotted path" })
