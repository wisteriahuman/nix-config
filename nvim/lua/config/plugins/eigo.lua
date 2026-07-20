return {
  {
    dir = vim.fn.expand("~/Projects/eigo/eigo.nvim"),
    name = "eigo.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("eigo").setup()
    end,
  },
}
