return {
  {
    'wisteriahuman/yajiuma.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>yy', '<cmd>YajiumaToggle<cr>',        desc = '野次馬 ON/OFF' },
      { '<leader>yd', '<cmd>YajiumaView danmaku<cr>',  desc = '野次馬: 弾幕' },
      { '<leader>yp', '<cmd>YajiumaView panel<cr>',    desc = '野次馬: コメント欄' },
      { '<leader>yo', '<cmd>YajiumaView off<cr>',      desc = '野次馬: OFF' },
      { '<leader>yh', '<cmd>YajiumaHeckle<cr>',        desc = '野次馬: 今すぐ1発' },
      { '<leader>yv', '<cmd>YajiumaVoice<cr>',         desc = '野次馬: 読み上げ ON/OFF' },
    },
    config = function()
      require('yajiuma').setup({
        view = 'danmaku',
        enabled = false,
        api_key_file = '~/.config/yajiuma/key', -- Groqキー（git管理外）
        voice = true,
        voice_speaker = '3',
        debounce_ms = 800,
      })
    end,
  },
}
