"===============================
" GENERAL SETTINGS
"===============================

"Use of pathogen plugin to keep each plugin in its own folder.
"inside a 'bundle' directory. It's the only way suppress / add
"plugin in a clean way.
call pathogen#infect() 

"Use Vim settings, rather then Vi settings (much better!).
"This must be first, because it changes other options as a side effect.
set nocompatible

"Load file type plugins and indent files
filetype indent plugin on

"Syntax coloration
syntax on
   
"Our default colorscheme use 256 colors
set t_Co=256

"Default colorsheme
colorscheme xoria256

"===============================
" DRUPAL SETTINGS
"===============================

" allow to go to the declaration of a function with <ctrl-]>
" go to a project, use drupal-gentags script in scripts folder; then
" set correct path here to load tags for a given project.

" set path to your tags file here
" set tags+=~/.vim/tags/mytags.tags

"Always edit in utf-8.
set encoding=utf-8

"set the spaces instead of regular tab
set expandtab

"sets tab and shiftwidth to 2 spaces according to drupals coding standard
set tabstop=2 shiftwidth=2 softtabstop=2

"use the same indent from current line when starting a new line
set autoindent

"use smart autoindenting. Used when line ends with {
set smartindent

" ensure that drupal extensions are read as php files.
" note that snipMate use filetype to load snippets
augroup drupal
  autocmd BufRead,BufNewFile *.module set filetype=php
  autocmd BufRead,BufNewFile *.theme set filetype=php
  autocmd BufRead,BufNewFile *.inc set filetype=php
  autocmd BufRead,BufNewFile *.install set filetype=php
  autocmd BufRead,BufNewFile *.engine set filetype=php
  autocmd BufRead,BufNewFile *.profile set filetype=php
  autocmd BufRead,BufNewFile *.test set filetype=php
augroup END

"===============================
" PHP SETTINGS
"===============================

" activer l'omnicompletion pour tous les langages
set omnifunc=syntaxcomplete#Complete

" for highlighting parent error ] or )
let php_parent_error_close = 1  

" help for commenting functions
set syntax=php.doxygen

" utiliser le compilateur php pour pouvoir vérifier la syntaxe
" avec ':make' sur un fichier
" go to line with syntax error, press enter to go to next error
set makeprg=php\ -l\ %
set errorformat=%m\ in\ %f\ on\ line\ %l


"================================
" feel more cumfortable
"================================

" montrer les numéros de lignes
set nu

" illuminer les résultat de recherche
set hlsearch

" sets vim in pastemode and you avoid unwanted sideeffects
" not compatible with snipmate ??
" set paste

" wrap search
set wrapscan

" ignore case for search
set ignorecase

" but if our search is uppercase, search first for uppercase
set smartcase

" no swap file (temporary files for content recovery)
set noswapfile

" always keep at least 5 lines visible under the cursor when scrolling
set scrolloff=5

" always print status line
"set laststatus=2

" print how many characters contains a line in status line
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %{strlen(getline('.'))}\ characters\ %P

"================================
" CONFIG PLUGIN TAGLIST SETTINGS
"================================

" taglist need to know where our ctags bin is located
let Tlist_Ctags_Cmd='/usr/bin/ctags'

" show taglist at the right of the screen
let Tlist_Use_Right_Window=1

" Only print tags for current buffer
let Tlist_Show_One_File=1

" min width for taglist buffer. Drupal functions name are usually pretty long
let Tlist_WinWidth=50

" only print constants, class and functions in our taglist
let tlist_php_settings = 'php;d:Constantes;c:Classes;f:Fonctions'

"================================
" CONFIG PLUGIN XDEBUG
"================================

" for xdebug : we want to see what's inside array, until x levels
let g:debuggerMaxDepth = 10

"================================
" MAPPINGS
" Please note that some keys are already used
" by the debugger:
" F1, F2, F3, F4, F5, F6, F11, F12 
" So let's deal with F7, F8, F9 & F10
"================================

" \ is definitly too difficult to reach !
" choose a more accessible 'leader' and 'localleader'
let mapleader = ";"
let maplocalleader=";"

" jump to tag definition (for example a function) when press F2
" you need ctags to make this works through a whole project
noremap <F7> <C-w>]
inoremap <F7> <Esc><C-w>]

"F12 toogle taglist buffer
nnoremap <silent> <F9> :TlistToggle<CR>

" open Navigation window with native nerdtree
"nmap <silent><F9> :NERDTreeToggle<CR>
"imap <silent><F9> :NERDTreeToggle<CR>

" open navigation with nerdree-tabs, which make
" NerdTree behave more like in a classic IDE
nmap <silent><F8> :NERDTreeTabsToggle<CR>
imap <silent><F8> :NERDTreeTabsToggle<CR>

" open navigation tree at the emplacement of current buffer
nmap <silent><F10> :NERDTreeFind<CR>


