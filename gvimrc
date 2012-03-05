" disable toolbar
set go=

" Use CTRL-S for saving, also in Insert mode
noremap <C-S> :w<CR>
vnoremap <C-S> <ESC>:w<CR>
inoremap <C-S> <ESC>:w<CR>

" CTRL-X is Cut
vnoremap <C-X> "+x

" CTRL-C is  Copy
vnoremap <C-C> "+y

" CTRL-V is paste
map <C-V>		"+gP
inoremap <C-V>		"+gP

