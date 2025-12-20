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
