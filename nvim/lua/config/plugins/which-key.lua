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
      spec = {
        { '<leader>b', group = 'バッファ' },
        { '<leader>D', group = 'データベース' },
        { '<leader>f', group = '検索 / ファイル' },
        { '<leader>g', group = 'Git' },
        { '<leader>l', group = 'LSP / コード' },
        { '<leader>m', group = 'メモ' },
        { '<leader>n', group = 'テスト / 通知' },
        { '<leader>o', group = 'GitHub (Octo)' },
        { '<leader>p', group = 'プレビュー' },
        { '<leader>s', group = '分割 / 置換' },
        { '<leader>t', group = '翻訳 / ターミナル' },
        { '<leader>u', group = 'トグル' },
        { '<leader>x', group = 'Trouble' },
        { '<leader>y', group = '野次馬' },
        { '<leader>Y', group = 'YouTube' },
        { 'gr', group = 'LSP' },
      },
    },
  },
}
