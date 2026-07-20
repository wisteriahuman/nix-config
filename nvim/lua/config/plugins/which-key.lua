return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix', -- 中央に大きく浮かせる(noice のフロートと世界観を合わせる)
      win = {
        border = 'rounded',
        padding = { 1, 2 },
      },
      plugins = {
        -- marks(')/ registers(") は既定で ON。スペル候補も足す
        spelling = { enabled = true, suggestions = 20 },
      },
    },
  },
}
