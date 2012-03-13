" example of gvimrc

" use windows friendly shortcuts with gvim
" So that your friends don't shout at you
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
noremap <C-V> "+gP
inoremap <C-V> <C-R>+

tmenu ToolBar.-Sep- Toggle display of File explorator
amenu ToolBar.-Sep- :NERDTreeTabsToggle<CR>

tmenu ToolBar.nerdtree Toggle display of File explorator
amenu ToolBar.nerdtree :NERDTreeTabsToggle<CR>

tmenu ToolBar.taglist Toggle display of the Taglist
amenu ToolBar.taglist :TlistToggle<CR>

tmenu ToolBar.tagsphp Generate php tags from current directory
amenu ToolBar.tagsphp :! ~/.vim/scripts/php-gentags.sh<CR>

tmenu ToolBar.tagsdrupal Generate DRUPAL php tags from current directory
amenu ToolBar.tagsdrupal :! ~/.vim/scripts/drupal-gentags.sh<CR>


