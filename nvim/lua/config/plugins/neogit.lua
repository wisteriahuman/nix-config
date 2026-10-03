return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit" },
      { "<leader>gb", "<cmd>FzfLua git_branches<CR>", desc = "Git ブランチ一覧" },
    },
    opts = {
      integrations = {
        diffview = true,
        fzf_lua = true,
      },
    },
  },
}
