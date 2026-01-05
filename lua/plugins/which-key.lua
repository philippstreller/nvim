return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 200,
    -- Add your group names and mappings in the spec
    spec = {
      { "<leader>f", group = "Find" },
      { "<leader>w", group = "Workspace" },
      { "<leader>x", group = "Diagnostics" },
      { "<leader>c", group = "Code" },
      { "<leader>b", group = "Buffer" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
