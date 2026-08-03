set noswapfile
syntax on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set guifont=Iosevka\ 20
set guioptions-=m
set guioptions-=T
set noesckeys
set relativenumber
set number
set ignorecase
set smartcase
set incsearch
set cinoptions=l1
set modeline
set iminsert=0
set imsearch=0
set autoindent
set autochdir
colorscheme habamax
nnoremap <SPACE> <Nop>
let mapleader=" "
autocmd BufEnter * if &filetype == "go" | setlocal noexpandtab
autocmd BufNewFile,BufRead ?\+.c3 setf c

map gf :e <cfile><CR>
map <leader>D :execute 'normal! a' . strftime('(%Y%m%d-%H%M%S)')<CR>



set t_Co=256
" Enable mouse in all modes
set mouse=a

" === System clipboard (Wayland / wl-clipboard) ===
" NOTE: this vim is built with -clipboard, so `set clipboard=unnamedplus`
" alone does NOT reach the system clipboard. wl-copy/wl-paste handle it:
"  - every yank (y, yy, visual y) is also pushed to the system clipboard
"  - <leader>p inserts the system clipboard below the cursor
set clipboard=unnamedplus

" Sync any yank to the system clipboard (like clipboard=unnamedplus would)
autocmd TextYankPost * if v:event.operator =~# 'y' | call system('wl-copy', @") | endif

" <leader>y still works as before (yank = also copied to system clipboard)
vnoremap <leader>y y

" Insert system clipboard below cursor (timeout guards against dead owners)
nnoremap <leader>p :put=system('timeout 2 wl-paste --no-newline 2>/dev/null')<CR>
