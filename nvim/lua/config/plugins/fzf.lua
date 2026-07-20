return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        keymap = {
          fzf = {
            ["ctrl-j"] = "down",
            ["ctrl-k"] = "up",
          },
        },
        actions = {
          files = {
            ["default"] = require("fzf-lua.actions").file_edit,
          },
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>ff", "<cmd>FzfLua files<CR>", { desc = "Find Files" })
      map("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", { desc = "Live Grep" })
      map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Buffers" })
      map("n", "<leader>fh", "<cmd>FzfLua help_tags<CR>", { desc = "Help Tags" })
    end,
  },
}
