return {
  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({})
    end,
    keys = {
      { "<leader>sr", "<cmd>GrugFar<CR>", desc = "Search and Replace" },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Search Current Word",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "v",
        desc = "Search Selection",
      },
    },
  },
}
