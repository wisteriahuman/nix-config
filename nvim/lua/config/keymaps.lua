vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local map = vim.keymap.set

map('i', 'jj', '<Esc>')
map({'n', 'v'}, 'H', '^')
map({'n', 'v'}, 'L', '$')
map('n', '<leader>w', ':w<CR>', { desc = '保存' })
map('n', '<leader>q', ':q<CR>', { desc = '終了' })
map('n', '<Esc>', ':nohlsearch<CR>')
map('n', '<leader>sv', ':vsplit<CR>', { desc = '左右に分割' })
map('n', '<leader>sh', ':split<CR>', { desc = '上下に分割' })
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')
map('v', '<', '<gv')
map('v', '>', '>gv')
map('v', '<A-j>', ":m '>+1<CR>gv=gv")
map('v', '<A-k>', ":m '<-2<CR>gv=gv")
map('v', 'p', '"_dp')
map('n', 'Y', 'y$')
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', '<C-e>', '3<C-e>')
map('n', '<C-y>', '3<C-y>')
map('n', 'n', 'nzz')
map('n', 'N', 'Nzz')
map({'n', 'x'}, '<leader>a', function()
  local saved = vim.b.snacks_scroll
  vim.b.snacks_scroll = false  -- 全選択ジャンプはスクロールアニメーションさせない
  if vim.fn.mode() ~= 'n' then
    vim.cmd('normal! \27')
  end
  vim.cmd('keepjumps normal! ggVG')
  vim.schedule(function() vim.b.snacks_scroll = saved end)
end, { desc = '全選択' })
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'バッファを閉じる' })
map('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'ウィンドウの高さ +' })
map('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'ウィンドウの高さ -' })
map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'ウィンドウの幅 -' })
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'ウィンドウの幅 +' })

local encodings = { 'utf-8', 'cp932', 'sjis', 'euc-jp', 'iso-2022-jp', 'utf-16', 'utf-16le', 'latin1' }
local fileformats = { 'unix', 'dos', 'mac' }

local function current_info()
  local fenc = vim.bo.fileencoding ~= '' and vim.bo.fileencoding or '(none)'
  return {
    fileencoding = fenc,
    encoding = vim.o.encoding,
    fileformat = vim.bo.fileformat,
    bomb = vim.bo.bomb,
  }
end

local function pick_encoding(prompt, on_choice)
  local info = current_info()
  local full_prompt = string.format('%s [current: %s]', prompt, info.fileencoding)
  vim.ui.select(encodings, { prompt = full_prompt }, function(choice)
    if choice then on_choice(choice) end
  end)
end

vim.api.nvim_create_user_command('ReloadWithEncoding', function(opts)
  local enc = opts.args ~= '' and opts.args or nil
  local apply = function(e) vim.cmd('edit ++enc=' .. e) end
  if enc then apply(enc) else pick_encoding('Reload with encoding:', apply) end
end, { nargs = '?', complete = function() return encodings end })

vim.api.nvim_create_user_command('SetFileEncoding', function(opts)
  local enc = opts.args ~= '' and opts.args or nil
  local apply = function(e)
    vim.bo.fileencoding = e
    vim.notify('fileencoding = ' .. e .. ' (write to apply)', vim.log.levels.INFO)
  end
  if enc then apply(enc) else pick_encoding('Save with encoding:', apply) end
end, { nargs = '?', complete = function() return encodings end })

vim.api.nvim_create_user_command('SetFileFormat', function(opts)
  local ff = opts.args ~= '' and opts.args or nil
  local apply = function(f)
    vim.bo.fileformat = f
    vim.notify('fileformat = ' .. f .. ' (write to apply)', vim.log.levels.INFO)
  end
  if ff then
    apply(ff)
  else
    vim.ui.select(fileformats, {
      prompt = string.format('Set fileformat: [current: %s]', vim.bo.fileformat),
    }, function(choice) if choice then apply(choice) end end)
  end
end, { nargs = '?', complete = function() return fileformats end })

vim.api.nvim_create_user_command('ShowEncoding', function()
  local info = current_info()
  local lines = {
    'File encoding info',
    '  fileencoding : ' .. info.fileencoding,
    '  encoding     : ' .. info.encoding .. '  (Neovim internal)',
    '  fileformat   : ' .. info.fileformat,
    '  bomb         : ' .. tostring(info.bomb),
  }
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end, {})

map('n', '<leader>fe', '<cmd>ReloadWithEncoding<CR>', { desc = '文字コードを指定して開き直す' })
map('n', '<leader>fw', '<cmd>SetFileEncoding<CR>', { desc = '保存時の文字コードを設定' })
map('n', '<leader>fl', '<cmd>SetFileFormat<CR>', { desc = '改行コードを設定' })
map('n', '<leader>fi', '<cmd>ShowEncoding<CR>', { desc = '現在の文字コード情報を表示' })
