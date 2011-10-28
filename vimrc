"===============================
" GENERAL SETTINGS
"===============================

" use of pathogen plugin to keep each plugin in its own folder.
call pathogen#infect() 

"Use Vim settings, rather then Vi settings (much better!).
"This must be first, because it changes other options as a side effect.
set nocompatible

"load file type plugins and indent files
filetype indent plugin on

" syntax coloration
syntax on
   
" our default colorscheme use 256 colors
set t_Co=256

" default colorsheme
colorscheme xoria256

"===============================
" DRUPAL SETTINGS
"===============================

" always edit in utf-8
set encoding=utf-8

" allow to go to the declaration of a function with <ctrl-]>
set tags+=~/.vim/tags/aef-trunk.tags

"add drupal6 function as a dictionnary. allow autocompletion via ctrl-n
set dict +=~/.vim/dictionaries/drupal6.dict

" add dictionaries to autocomplete shortcut (crtl-p, ctrl-n)
set complete-=k complete+=k

"set the spaces instead of regular tab
set expandtab

"sets tab and shiftwidth to 2 spaces according to drupals coding standard
set tabstop=2 shiftwidth=2 softtabstop=2

"use the same indent from current line when starting a new line
set autoindent

"use smart autoindenting. Used when line ends with {
set smartindent

" ensure that drupal extensions are read as php files.
" 'drupal' is added because we want snipMate to load
" snippets located in snippets/drupal directory
augroup drupal
  autocmd BufRead,BufNewFile *.module set filetype=php
  autocmd BufRead,BufNewFile *.theme set filetype=php
  autocmd BufRead,BufNewFile *.inc set filetype=php
  autocmd BufRead,BufNewFile *.install set filetype=php
  autocmd BufRead,BufNewFile *.engine set filetype=php
  autocmd BufRead,BufNewFile *.profile set filetype=php
  autocmd BufRead,BufNewFile *.test set filetype=php
augroup END

" uncomment to highlight code lines and comments > 80 characters
" highlight OverLength ctermbg=red ctermfg=white guibg=red guifg=white
" match OverLength '\%81v.*'

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
" avec ':make %' sur un fichier
set makeprg=php

"================================
" feel more cumfortable
"================================

" \ is definitly to difficult to reach !
let mapleader = ";"
let maplocalleader=";"

" montrer les numéros de lignes
set nu

" illuminer les résultat de recherche
set hlsearch

" sets vim in pastemode and you avoid unwanted sideeffects
" not compatible with snipmate ??
" set paste

" boucler sur le fichier pour naviguer dans les résultat de la recherche
set wrapscan

" ignorer la casse pour les recherches
set ignorecase

"... mais si on cherche en majuscule, donner la priorité aux mots en majuscules
set smartcase

" les swap files me cassent les c*****
set noswapfile

" Toujours laisser des lignes visibles (içi 5) au dessus/en dessous du curseur quand on
" atteint le début ou la fin de l'écran :
set scrolloff=5

"================================
" PLUGIN TAGLIST
"================================

" le plugin taglist doit connaitre l'emplacement du binaire ctags
let Tlist_Ctags_Cmd='/usr/bin/ctags'

"F12 Switch on/off de la fenêtre du plugin TagList
nnoremap <silent> <F12> :TlistToggle<CR>

" afficher la liste de tags dans le menu de GVIM
let Tlist_Show_Menu=1

" n'afficher les tags que pour le fichier courant
let Tlist_Show_One_File=1

" afficher la fenêtre de taglist dans une barre à droite
let Tlist_Use_Right_Window=1

" les noms de fonctions de drupal peuvent être loooooooooooooongs.
let Tlist_WinWidth=50

" n'afficher que les constantes, les classes et les fonctions. 
" Les variables prennent de la place et ne me servent à rien
let tlist_php_settings = 'php;d:Constantes;c:Classes;f:Fonctions'
let tlist_drupal_settings = 'php;d:Constantes;c:Classes;f:Fonctions'


"================================
" PLUGIN PROJECT
"================================

" show / hide project window
nmap <silent> <F9> <Plug>ToggleProject
