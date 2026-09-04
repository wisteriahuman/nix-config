local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.clipboard = "unnamedplus"
opt.list = true
opt.listchars = { tab = "»-", trail = "-", eol = "↲" }
opt.virtualedit = "block"
opt.whichwrap = "b,s,[,],<,>"
opt.backspace = { "indent", "eol", "start" }
opt.wildmenu = true
opt.hidden = true
opt.history = 1000
opt.title = true
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.smoothscroll = true
opt.jumpoptions = "stack,view"
opt.signcolumn = "yes"
opt.termguicolors = true
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.cursorline = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 200
opt.timeoutlen = 300
opt.confirm = true
opt.showmatch = true
opt.matchtime = 2
opt.laststatus = 3
opt.winminwidth = 5
opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess:append("c")
opt.fillchars = {
  eob = " ",
  fold = " ",
  foldsep = " ",
}
opt.mouse = "a"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = { "ucs-bom", "utf-8", "iso-2022-jp", "euc-jp", "cp932", "sjis", "default", "latin1" }
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.hlsearch = true
opt.incsearch = true
opt.showmode = false
opt.pumheight = 15
opt.conceallevel = 0

local nvim_python = vim.fn.expand("~/.local/share/nvim/python/.venv/bin/python")
if vim.fn.executable(nvim_python) == 1 then
  vim.g.python3_host_prog = nvim_python
end

local compose_ft = "yaml.docker-compose"
vim.filetype.add({
  pattern = {
    [".*compose.*%.yaml"] = compose_ft,
    [".*compose.*%.yml"] = compose_ft,
  },
})
