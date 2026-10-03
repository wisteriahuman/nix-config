return {
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    config = function()
      require('trouble').setup()

      local map = vim.keymap.set
      map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', { desc = '診断一覧 (Trouble)' })
      map('n', '<leader>xd', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', { desc = 'このファイルの診断 (Trouble)' })
    end,
  },
}
