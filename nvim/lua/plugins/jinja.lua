return {
  {
    "HiPhish/jinja.vim",
    ft = { "jinja", "jinja2", "html.jinja", "html.jinja2" },
    config = function()
      -- Optional: Configure file type detection
      vim.filetype.add({
        extension = {
          j2 = "jinja",
          jinja = "jinja",
          jinja2 = "jinja2",
        },
        pattern = {
          [".*%.html%.j2"] = "html.jinja2",
          [".*%.html%.jinja"] = "html.jinja",
          [".*%.html%.jinja2"] = "html.jinja2",
        },
      })
    end,
  },
}
