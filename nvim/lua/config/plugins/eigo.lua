local eigo_dir = vim.fn.expand("~/Projects/eigo/eigo.nvim")

return {
  {
    dir = eigo_dir,
    name = "eigo.nvim",
    cond = vim.uv.fs_stat(eigo_dir) ~= nil,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("eigo").setup()
    end,
  },
}
