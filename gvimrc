" example of gvimrc

" remove menu
" set go=T

" use windows friendly shortcuts with gvim
" So that your friends don't shout at you
" because they can't do anything with your fuc**g editor

" Use CTRL-S for saving, also in Insert mode
" use F5 to refresh browser
noremap <C-F5> :! ~/.vim/scripts/browser-refresh.sh<CR><ESC>
inoremap <C-F5> :! ~/.vim/scripts/browser-refresh.sh><CR><ESC>
vnoremap <C-F5> :! ~/.vim/scripts/browser-refresh.sh><CR><ESC>

noremap <C-S> :w<CR>
vnoremap <C-S> <ESC>:w<CR>
inoremap <C-S> <ESC>:w<CR>

" CTRL-X is Cut
vnoremap <C-X> "+x
inoremap <C-X> <C-R>+

" CTRL-C is  Copy
vnoremap <C-C> "+y
inoremap <C-C> <C-R>y

" CTRL-V is paste in insert mode.
inoremap <C-V> <C-R>+

"remove all items from toolbar menu items, except open, search and sessions.
aunmenu ToolBar.Redo
aunmenu ToolBar.Undo
aunmenu ToolBar.Save
aunmenu ToolBar.SaveAll
aunmenu ToolBar.Print
aunmenu ToolBar.Cut
aunmenu ToolBar.Paste
aunmenu ToolBar.-sep1-
aunmenu ToolBar.-sep2-
aunmenu ToolBar.-sep3-
aunmenu ToolBar.-sep4-
aunmenu ToolBar.-sep5-
aunmenu ToolBar.-sep6-
aunmenu ToolBar.-sep7-
aunmenu ToolBar.Make
aunmenu ToolBar.RunScript
aunmenu ToolBar.RunCtags
aunmenu ToolBar.TagJump
aunmenu ToolBar.Help
aunmenu ToolBar.FindHelp
aunmenu ToolBar.FindNext
aunmenu ToolBar.FindPrev

" Add our own custom toolbar icons
tmenu ToolBar.nerdtree Toggle display of File explorator
amenu ToolBar.nerdtree :NERDTreeTabsToggle<CR>

tmenu ToolBar.taglist Toggle display of the Taglist
amenu ToolBar.taglist :TlistToggle<CR>

tmenu ToolBar.tagsphp Generate php tags from current directory
amenu ToolBar.tagsphp :! ~/.vim/scripts/php-gentags.sh<CR>

tmenu ToolBar.tagsdrupal Generate DRUPAL php tags from current directory
amenu ToolBar.tagsdrupal :! ~/.vim/scripts/drupal-gentags.sh<CR>

tmenu ToolBar.browserRefresh Refresh browser
amenu ToolBar.browserRefresh :! ~/.vim/scripts/browser-refresh.sh<CR><CR>

noremap <RightMouse> <F12> 

