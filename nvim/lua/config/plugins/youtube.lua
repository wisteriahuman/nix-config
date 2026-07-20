return {
  {
    'wisteriahuman/yt.nvim',
    cmd = { 'Yt', 'YtPlayer', 'YtStop', 'YtSwitch' },
    keys = {
      -- <leader>Y はグループにして単独マッピングを置かない（キー待ち遅延回避）
      { '<leader>Ys', function() require('yt').search() end,        desc = 'YouTube検索→再生' },
      { '<leader>Yq', function() require('yt').stop() end,          desc = 'YouTube停止' },
      { '<leader>Yv', function() require('yt').switch('pane') end,  desc = 'YouTube→映像(ペイン)' },
      { '<leader>Ya', function() require('yt').switch('audio') end, desc = 'YouTube→音だけ' },
      { '<leader>Yt', function() require('yt').switch('tct') end,   desc = 'YouTube→tct描画' },
    },
    config = function()
      require('yt').setup({ player = 'pane', pane_percent = 42 })
    end,
  },
}
