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
        lsp = {
          code_actions = {
            -- いまの位置では使えない (disabled) 候補は出さない
            filter = function(action)
              return not action.disabled
            end,
          },
        },
        actions = {
          files = {
            ["default"] = require("fzf-lua.actions").file_edit,
          },
        },
      })

      -- vim.ui.select(番号入力の一覧)を fzf の選択画面に置き換える
      require("fzf-lua").register_ui_select()

      local map = vim.keymap.set
      map("n", "<leader>ff", "<cmd>FzfLua files<CR>", { desc = "Find Files" })
      map("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", { desc = "Live Grep" })
      map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Buffers" })
      map("n", "<leader>fh", "<cmd>FzfLua help_tags<CR>", { desc = "Help Tags" })
      map("n", "<leader>?", "<cmd>FzfLua keymaps<CR>", { desc = "キーマップを検索" })
    end,
  },
}
