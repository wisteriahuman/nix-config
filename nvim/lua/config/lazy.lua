local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none',
	'https://github.com/folke/lazy.nvim.git',
	'--branch=stable', lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('config.plugins', {
    git = { timeout = 300 },
    -- luarocks を必要とするプラグインは無いため無効化 (checkhealth の hererocks ERROR 対策)
    rocks = { enabled = false },
})
