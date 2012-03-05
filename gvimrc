" disable toolbar
set go=

" use windows friendly shortcuts with gvim
" So that your friends at you don't shout at you
" because they can't do anything with your fuc**g editor

" Use CTRL-S for saving, also in Insert mode
noremap <C-S> :w<CR>
vnoremap <C-S> <ESC>:w<CR>
inoremap <C-S> <ESC>:w<CR>

" CTRL-X is Cut
vnoremap <C-X> "+x
inoremap <C-X> <C-R>+

" CTRL-C is  Copy
vnoremap <C-C> "+y
inoremap <C-C> <C-R>y

" CTRL-V is paste
map <C-V> "+gP
inoremap <C-V> <C-R>+

