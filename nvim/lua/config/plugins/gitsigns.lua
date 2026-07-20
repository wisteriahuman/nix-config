return {
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function(bufnr)
          if vim.api.nvim_buf_get_name(bufnr):match('%.ipynb$') then
            return false
          end
        end,
      })
    end,
  },
}
