vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local map = vim.keymap.set

map('i', 'jj', '<Esc>')
map({'n', 'v'}, 'H', '^')
map({'n', 'v'}, 'L', '$')
map('n', '<leader>w', ':w<CR>')
map('n', '<leader>q', ':q<CR>')
map('n', '<Esc>', ':nohlsearch<CR>')
map('n', '<leader>sv', ':vsplit<CR>')
map('n', '<leader>sh', ':split<CR>')
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
end, { desc = 'Select all' })
map('n', '<leader>bd', '<cmd>bdelete<CR>', { desc = 'Delete buffer' })
map('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Window height +' })
map('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Window height -' })
map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Window width -' })
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Window width +' })

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

map('n', '<leader>fe', '<cmd>ReloadWithEncoding<CR>', { desc = 'Reload file with encoding' })
map('n', '<leader>fw', '<cmd>SetFileEncoding<CR>', { desc = 'Set fileencoding for write' })
map('n', '<leader>fl', '<cmd>SetFileFormat<CR>', { desc = 'Set fileformat (line endings)' })
map('n', '<leader>fi', '<cmd>ShowEncoding<CR>', { desc = 'Show current encoding info' })
