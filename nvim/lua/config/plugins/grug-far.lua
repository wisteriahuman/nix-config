return {
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({})
    end,
    keys = {
      { "<leader>sr", "<cmd>GrugFar<CR>", desc = "検索と置換" },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "カーソル下の単語を検索・置換",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "v",
        desc = "選択範囲を検索・置換",
      },
    },
  },
}
