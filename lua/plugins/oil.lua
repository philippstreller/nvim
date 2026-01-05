return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    { "<leader>-", "<cmd>Oil<cr>", desc = "Open Oil" },
    { "<leader>_", "<cmd>Oil --float<cr>", desc = "Open Oil (float)" },
    {
      "<leader>\\",
      function()
        vim.cmd("vsplit")
        require("oil").open()
      end,
      desc = "Open Oil (vsplit)",
    },
  },
  opts = {
    columns = { "icon", "permissions", "size", "mtime" },
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 2,
      border = "rounded",
    },
  },
}
