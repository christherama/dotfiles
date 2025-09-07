-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "sh" },
  callback = function()
    vim.b.autoformat = false -- for conform.nvim
    -- or
    vim.b.disable_autoformat = true -- for other formatters
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function()
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
    if first_line:match("^#!/.*sh") or first_line:match("^#!/bin/bash") or first_line:match("^#!/usr/bin/env%s+bash") then
      vim.b.autoformat = false
      vim.b.disable_autoformat = true
    end
  end,
})
