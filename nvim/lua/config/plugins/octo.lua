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
            vim.tbl_extend("force", opts, { desc = "Review Start" })
          )
          map(
            "n",
            "<leader>orS",
            "<cmd>Octo review submit<CR>",
            vim.tbl_extend("force", opts, { desc = "Review Submit" })
          )
          map(
            "n",
            "<leader>ord",
            "<cmd>Octo review discard<CR>",
            vim.tbl_extend("force", opts, { desc = "Review Discard" })
          )

          map("n", "<leader>oca", "<cmd>Octo comment add<CR>", vim.tbl_extend("force", opts, { desc = "Comment Add" }))
          map(
            "n",
            "<leader>ocd",
            "<cmd>Octo comment delete<CR>",
            vim.tbl_extend("force", opts, { desc = "Comment Delete" })
          )

          map("n", "<leader>opm", "<cmd>Octo pr merge<CR>", vim.tbl_extend("force", opts, { desc = "PR Merge" }))
          map("n", "<leader>opc", "<cmd>Octo pr close<CR>", vim.tbl_extend("force", opts, { desc = "PR Close" }))
          map("n", "<leader>opd", "<cmd>Octo pr diff<CR>", vim.tbl_extend("force", opts, { desc = "PR Diff" }))
          map("n", "<leader>opr", "<cmd>Octo pr ready<CR>", vim.tbl_extend("force", opts, { desc = "PR Ready" }))

          map("n", "<leader>ola", "<cmd>Octo label add<CR>", vim.tbl_extend("force", opts, { desc = "Label Add" }))
          map(
            "n",
            "<leader>oaa",
            "<cmd>Octo assignee add<CR>",
            vim.tbl_extend("force", opts, { desc = "Assignee Add" })
          )
        end,
      })
    end,
    cmd = "Octo",
    keys = {
      { "<leader>opl", "<cmd>Octo pr list<CR>", desc = "PR List" },
      { "<leader>oil", "<cmd>Octo issue list<CR>", desc = "Issue List" },
    },
  },
}
