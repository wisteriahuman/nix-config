return {
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup({
        picker = "fzf-lua",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          local map = vim.keymap.set

          map(
            "n",
            "<leader>ors",
            "<cmd>Octo review start<CR>",
            vim.tbl_extend("force", opts, { desc = "レビュー開始" })
          )
          map(
            "n",
            "<leader>orS",
            "<cmd>Octo review submit<CR>",
            vim.tbl_extend("force", opts, { desc = "レビュー送信" })
          )
          map(
            "n",
            "<leader>ord",
            "<cmd>Octo review discard<CR>",
            vim.tbl_extend("force", opts, { desc = "レビュー破棄" })
          )

          map("n", "<leader>oca", "<cmd>Octo comment add<CR>", vim.tbl_extend("force", opts, { desc = "コメント追加" }))
          map(
            "n",
            "<leader>ocd",
            "<cmd>Octo comment delete<CR>",
            vim.tbl_extend("force", opts, { desc = "コメント削除" })
          )

          map("n", "<leader>opm", "<cmd>Octo pr merge<CR>", vim.tbl_extend("force", opts, { desc = "PR マージ" }))
          map("n", "<leader>opc", "<cmd>Octo pr close<CR>", vim.tbl_extend("force", opts, { desc = "PR クローズ" }))
          map("n", "<leader>opd", "<cmd>Octo pr diff<CR>", vim.tbl_extend("force", opts, { desc = "PR 差分" }))
          map("n", "<leader>opr", "<cmd>Octo pr ready<CR>", vim.tbl_extend("force", opts, { desc = "PR をレビュー可能にする" }))

          map("n", "<leader>ola", "<cmd>Octo label add<CR>", vim.tbl_extend("force", opts, { desc = "ラベル追加" }))
          map(
            "n",
            "<leader>oaa",
            "<cmd>Octo assignee add<CR>",
            vim.tbl_extend("force", opts, { desc = "担当者追加" })
          )
        end,
      })
    end,
    cmd = "Octo",
    keys = {
      { "<leader>opl", "<cmd>Octo pr list<CR>", desc = "PR 一覧" },
      { "<leader>oil", "<cmd>Octo issue list<CR>", desc = "Issue 一覧" },
    },
  },
}
