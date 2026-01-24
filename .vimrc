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
set keymap=russian-jcukenwin
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
"map <leader>D :execute 'normal! a' . strftime('(%Y%m%d-%H%M%S)')<CR>
map <leader>D :execute 'normal! a' . system('date -u "+(%Y%m%d-%H%M%S)"')<CR>


set t_Co=256
" Enable mouse in all modes
set mouse=a

" Use system clipboard for yanks and pastes
set clipboard=unnamedplus
" In visual mode, 'y' yanks to the system clipboard
vnoremap y "+y

" Yank selection to system clipboard via wl-copy
vnoremap <leader>y :w !wl-copy<CR><CR>

" Paste from system clipboard via wl-paste
nnoremap <leader>p :r !wl-paste --no-newline<CR>
