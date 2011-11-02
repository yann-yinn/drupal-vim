" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/manpageviewPlugin.vim	[[[1
32
" manpageviewPlugin.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Sep 16, 2008
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_manpageviewPlugin")
 finish
endif
let s:keepcpo= &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Public Interface: {{{1
if !hasmapto('<Plug>ManPageView') && &kp =~ '^man\>'
 nmap <unique> K <Plug>ManPageView
endif
nno <silent> <script> <Plug>ManPageView	:<c-u>call manpageview#ManPageView(1,v:count1,expand("<cword>"))<CR>

com! -nargs=* -count=0	Man		call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	HMan	let g:manpageview_winopen="hsplit" |call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	HEMan	let g:manpageview_winopen="hsplit="|call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	OMan	let g:manpageview_winopen="only"   |call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	RMan	let g:manpageview_winopen="reuse"  |call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	VMan	let g:manpageview_winopen="vsplit="|call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=* -count=0	VEMan	let g:manpageview_winopen="vsplit" |call manpageview#ManPageView(0,<count>,<f-args>)
com! -nargs=? -count=0	KMan	call manpageview#KMan(<q-args>)

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
autoload/manpageview.vim	[[[1
1154
" manpageview.vim : extra commands for manual-handling
" Author:	Charles E. Campbell, Jr.
" Date:		Jul 20, 2011
" Version:	24c	ASTRO-ONLY
"
" Please read :help manpageview for usage, options, etc
"
" GetLatestVimScripts: 489 1 :AutoInstall: manpageview.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_manpageview")
 finish
endif
let g:loaded_manpageview = "v24c"
if v:version < 702
 echohl WarningMsg
 echo "***warning*** this version of manpageview needs vim 7.2 or later"
 echohl Normal
 finish
endif
let s:keepcpo= &cpo
set cpo&vim
"DechoTabOn

" ---------------------------------------------------------------------
" Set up default manual-window opening option: {{{1
if !exists("g:manpageview_winopen")
 let g:manpageview_winopen= "hsplit"
elseif g:manpageview_winopen == "only" && !has("mksession")
 echomsg "***g:manpageview_winopen<".g:manpageview_winopen."> not supported w/o +mksession"
 let g:manpageview_winopen= "hsplit"
endif

" ---------------------------------------------------------------------
" Sanity Check: {{{1
if !exists("*shellescape")
 fun! manpageview#ManPageView(viamap,bknum,...) range
   echohl ERROR
   echo "You need to upgrade your vim to v7.1 or later (manpageview uses the shellescape() function)"
 endfun
 finish
endif

" ---------------------------------------------------------------------
" Default Variable Values: {{{1
if !exists("g:manpageview_iconv")
 if executable("iconv")
  let s:iconv= "iconv -c"
 else
  let s:iconv= ""
 endif
else
 let s:iconv= g:manpageview_iconv
endif
if s:iconv != ""
 let s:iconv= "| ".s:iconv
endif
if !exists("g:manpageview_pgm") && executable("man")
 let g:manpageview_pgm= "man"
endif
if !exists("g:manpageview_multimanpage")
 let g:manpageview_multimanpage= 1
endif
if !exists("g:manpageview_options")
 let g:manpageview_options= ""
endif
if !exists("g:manpageview_pgm_i") && executable("info")
" call Decho("installed info help support via manpageview")
 let g:manpageview_pgm_i     = "info"
 let g:manpageview_options_i = "--output=-"
 let g:manpageview_syntax_i  = "info"
 let g:manpageview_K_i       = "<sid>ManPageInfo(0)"
 let g:manpageview_init_i    = "call ManPageInfoInit()"

 let s:linkpat1 = '\*[Nn]ote \([^():]*\)\(::\|$\)' " note
 let s:linkpat2 = '^\* [^:]*: \(([^)]*)\)'         " filename
 let s:linkpat3 = '^\* \([^:]*\)::'                " menu
 let s:linkpat4 = '^\* [^:]*:\s*\([^.]*\)\.$'      " index
endif
if !exists("g:manpageview_pgm_pl") && executable("perldoc")
" call Decho("installed perl help support via manpageview")
 let g:manpageview_pgm_pl     = "perldoc"
 let g:manpageview_options_pl = ";-f;-q"
endif
if !exists("g:manpageview_pgm_php") && (executable("links") || executable("elinks"))
"  call Decho("installed php help support via manpageview")
 let g:manpageview_pgm_php     = (executable("links")? "links" : "elinks")." -dump http://www.php.net/"
 let g:manpageview_syntax_php  = "manphp"
 let g:manpageview_nospace_php = 1
 let g:manpageview_K_php       = "manpageview#ManPagePhp()"
endif
if !exists("g:manpageview_pgm_gl") && (executable("links") || executable("elinks"))
 let g:manpageview_pgm_gl     = (executable("links")? "links" : "elinks")." -dump http://www.opengl.org/sdk/docs/man/xhtml/"
 let g:manpageview_syntax_gl  = "mangl"
 let g:manpageview_nospace_gl = 1
 let g:manpageview_K_gl       = "manpageview#ManPagePhp()"
 let g:manpageview_sfx_gl     = ".xml"
endif
if !exists("g:manpageview_pgm_py") && executable("pydoc")
" call Decho("installed python help support via manpageview")
 let g:manpageview_pgm_py     = "pydoc"
 let g:manpageview_K_py       = "manpageview#ManPagePython()"
endif
if exists("g:manpageview_hypertext_tex") && !exists("g:manpageview_pgm_tex") && (executable("links") || executable("elinks"))
" call Decho("installed tex help support via manpageview")
 let g:manpageview_pgm_tex    = (executable("links")? "links" : "elinks")." ".g:manpageview_hypertext_tex
 let g:manpageview_lookup_tex = "manpageview#ManPageTexLookup"
 let g:manpageview_K_tex      = "manpageview#ManPageTex()"
endif
if has("win32") && !exists("g:manpageview_rsh")
" call Decho("installed rsh help support via manpageview")
 let g:manpageview_rsh= "rsh"
endif

" =====================================================================
"  Functions: {{{1

" ---------------------------------------------------------------------
" manpageview#ManPageView: view a manual-page, accepts three formats: {{{2
"    :call manpageview#ManPageView(viamap,"topic")
"    :call manpageview#ManPageView(viamap,booknumber,"topic")
"    :call manpageview#ManPageView(viamap,"topic(booknumber)")
"
"    viamap=0: called via a command
"    viamap=1: called via a map
"    bknum   : if non-zero, then its the book number of the manpage (default=1)
"              if zero, but viamap==1, then use lastline-firstline+1
fun! manpageview#ManPageView(viamap,bknum,...) range
"  call Dfunc("manpageview#ManPageView(viamap=".a:viamap." bknum=".a:bknum.") a:0=".a:0. " version=".g:loaded_manpageview)
  set lz
  let manpageview_fname = expand("%")
  let bknum             = a:bknum
  call s:MPVSaveSettings()

  " fix topic {{{3
  if a:0 > 0
"   call Decho("(fix topic) case a:0 > 0: (a:1<".a:1.">)")
   if &ft != "info"
	if a:0 == 2 && bknum > 0
	 let bknum = bknum.a:1
	 let topic = a:2
	else
     let topic= substitute(a:1,'[^-a-zA-Z.0-9_:].*$','','')
"     call Decho("a:1<".a:1."> topic<".topic."> (after fix)")
	endif
   else
   	let topic= a:1
   endif
   if topic =~ '($'
    let topic= substitute(topic,'($','','')
   endif
"   call Decho("topic<".topic.">  bknum=".bknum." (after fix topic)")
  endif

  if !exists("topic") || topic == ""
   echohl WarningMsg
   echo "***warning*** missing topic"
   echohl None
   sleep 2
"   call Dret("manpageview#ManPageView : missing topic")
   return
  endif

  " interpret the input arguments - set up manpagetopic and manpagebook {{{3
  if a:0 > 0 && strpart(topic,0,1) == '"'
"   call Decho("(interpret input arguments) topic<".topic.">")
   " merge quoted arguments:  Man "some topic here"
"   call Decho('(merge quoted args) case a:0='.a:0." strpart(".topic.",0,1)<".strpart(topic,0,1))
   let manpagetopic = strpart(topic,1)
   if manpagetopic =~ '($'
    let manpagetopic= substitute(manpagetopic,'($','','')
   endif
"   call Decho("manpagetopic<".manpagetopic.">")
   if bknum != ""
   	let manpagebook= string(bknum)
   else
    let manpagebook= ""
   endif
"   call Decho("manpagebook<".manpagebook.">")
   let i= 2
   while i <= a:0
   	let manpagetopic= manpagetopic.' '.a:{i}
	if a:{i} =~ '"$'
	 break
	endif
   	let i= i + 1
   endwhile
   let manpagetopic= strpart(manpagetopic,0,strlen(manpagetopic)-1)
"   call Decho("merged quoted arguments<".manpagetopic.">")

  elseif a:0 == 0
"   call Decho('case a:0==0')
   if exists("g:ManCurPosn") && has("mksession")
"    call Decho("(ManPageView) a:0=".a:0."  g:ManCurPosn exists")
	call s:ManRestorePosn()
   else
    echomsg "***usage*** :Man topic  -or-  :Man topic nmbr"
"    call Decho("(ManPageView) a:0=".a:0."  g:ManCurPosn doesn't exist")
   endif
   call s:MPVRestoreSettings()
"   call Dret("manpageview#ManPageView")
   return

  elseif a:0 == 1
   " ManPageView("topic") -or-  ManPageView("topic(booknumber)")
"   call Decho("case a:0==1 (topic  -or-  topic(booknumber))")
"   call Decho("(ManPageView) a:0=".a:0." topic<".topic.">")
   if a:1 =~ "("
	" abc(3)
"	call Decho("has parenthesis: a:1<".a:1.">  ft<".&ft.">")
	let a1 = substitute(a:1,'[-+*/;,.:]\+$','','e')
"	call Decho("has parenthesis: a:1<".a:1.">  a1<".a1.">")
	if &ft == 'sh'
"	 call Decho('has parenthesis: but ft<'.&ft."> isn't <man>")
	 let manpagetopic = substitute(a:1,'(.*$','','')
	 let manpagebook  = ""
	elseif &ft != 'man'
"	 call Decho('has parenthesis: but ft<'.&ft."> isn't <man>")
	 let manpagetopic = substitute(a:1,'(.*$','','')
	 if a:viamap == 0
      let manpagebook = substitute(a1,'^.*(\([^)]\+\))\=.*$','\1','e')
	 else
	  let manpagebook  = "3"
	 endif
    elseif a1 =~ '[,"]'
"	 call Decho('has parenthesis: a:1 matches [,"]')
     let manpagetopic= substitute(a1,'[(,"].*$','','e')
	else
"	 call Decho('has parenthesis: a:1 does not match [,"]')
     let manpagetopic= substitute(a1,'^\(.*\)(\d\w*),\=.*$','\1','e')
     let manpagebook = substitute(a1,'^.*(\(\d\w*\)),\=.*$','\1','e')
	endif
    if manpagetopic =~ '($'
"	 call Decho('has parenthesis: manpagetopic<'.a:1.'> matches "($"')
     let manpagetopic= substitute(manpagetopic,'($','','')
    endif
    if manpagebook =~ '($'
"	 call Decho('has parenthesis: manpagebook<'.manpagebook.'> matches "($"')
     let manpagebook= ""
    endif
	if manpagebook =~ '\d\+\a\+'
	 let manpagebook= substitute(manpagebook,'\a\+','','')
	endif

   else
    " ManPageView(booknumber,"topic")
"	call Decho('(ManPageView(booknumber,"topic")) case a:0='.a:0)
    let manpagetopic= topic
    if a:viamap == 1 && a:lastline > a:firstline
     let manpagebook= string(a:lastline - a:firstline + 1)
    elseif a:bknum > 0
     let manpagebook= string(a:bknum)
	else
     let manpagebook= ""
    endif
   endif

  else
   " 3 abc  -or-  abc 3
"   call Decho("(3 abc -or- abc 3) case a:0=".a:0)
   if     topic =~ '^\d\+'
"	call Decho("case 1: topic =~ ^\d\+")
    let manpagebook = topic
    let manpagetopic= a:2
   elseif a:2 =~ '^\d\+$'
"	call Decho("case 2: topic =~ \d\+$")
    let manpagebook = a:2
    let manpagetopic= topic
   elseif topic == "-k"
"	call Decho("case 3: topic == -k")
"    call Decho("user requested man -k")
    let manpagetopic = a:2
    let manpagebook  = "-k"
   elseif bknum != ""
"	call Decho('case 4: bknum != ""')
	let manpagetopic = topic
	let manpagebook  = bknum
   else
	" default: topic book
"	call Decho("default case: topic book")
    let manpagebook = a:2
    let manpagetopic= topic
   endif
  endif
"  call Decho("manpagetopic<".manpagetopic.">")
"  call Decho("manpagebook <".manpagebook.">")

  " for the benefit of associated routines (such as InfoIndexLink()) {{{3
  let s:manpagetopic = manpagetopic
  let s:manpagebook  = manpagebook

  " default program g:manpageview_pgm=="man" may be overridden {{{3
  " if an extension is matched
  if exists("g:manpageview_pgm")
   let pgm = g:manpageview_pgm
  else
   let pgm = ""
  endif
  let ext = ""
  if manpagetopic =~ '\.'
   let ext = substitute(manpagetopic,'^.*\.','','e')
  endif
  if exists("g:manpageview_pgm_gl") && manpagetopic =~ '^gl'
	  let ext = "gl"
  endif

  " infer the appropriate extension based on the filetype {{{3
  if ext == ""
"   call Decho("attempt to infer on filetype<".&ft.">")

   " filetype: vim
   if &ft == "vim"
   	if g:manpageview_winopen == "only"
	 exe "help ".fnameescape(manpagetopic)
	 only
	elseif g:manpageview_winopen == "vsplit"
	 exe "vert help ".fnameescape(manpagetopic)
	elseif g:manpageview_winopen == "vsplit="
	 exe "vert help ".fnameescape(manpagetopic)
	 wincmd =
	elseif g:manpageview_winopen == "hsplit="
	 exe "help ".fnameescape(manpagetopic)
	 wincmd =
	else
	 exe "help ".fnameescape(manpagetopic)
	endif
"	call Dret("manpageview#ManPageView")
	return

   " filetype: perl
   elseif &ft == "perl" || &ft == "perldoc"
   	let ext = "pl"

   " filetype:  php
   elseif &ft == "php" || &ft == "manphp"
   	let ext = "php"

	" filetype:  python
   elseif &ft == "python" || &ft == "pydoc"
   	let ext = "py"

   " filetype: tex
  elseif &ft == "tex"
   let ext= "tex"
   endif
  endif
"  call Decho("ext<".ext.">")

  " elide extension from manpagetopic {{{3
  if exists("g:manpageview_pgm_{ext}")
   let pgm          = g:manpageview_pgm_{ext}
   let manpagetopic = substitute(manpagetopic,'.'.ext.'$','','')
  endif
  let nospace= exists("g:manpageview_nospace_{ext}")? g:manpageview_nospace_{ext} : 0
"  call Decho("pgm<".pgm."> manpagetopic<".manpagetopic.">")

  " special exception for info {{{3
  if a:viamap == 0 && ext == "i"
   let s:manpageview_pfx_i = "(".manpagetopic.")"
   let manpagetopic        = "Top"
"   call Decho("top-level info: manpagetopic<".manpagetopic.">")
  endif

  if exists("s:manpageview_pfx_{ext}") && s:manpageview_pfx_{ext} != ""
   let manpagetopic= s:manpageview_pfx_{ext}.manpagetopic
  elseif exists("g:manpageview_pfx_{ext}") && g:manpageview_pfx_{ext} != ""
   " prepend any extension-specified prefix to manpagetopic
   let manpagetopic= g:manpageview_pfx_{ext}.manpagetopic
  endif

  if exists("g:manpageview_sfx_{ext}") && g:manpageview_sfx_{ext} != ""
   " append any extension-specified suffix to manpagetopic
   let manpagetopic= manpagetopic.g:manpageview_sfx_{ext}
  endif

  if exists("g:manpageview_K_{ext}") && g:manpageview_K_{ext} != ""
   " override usual K map
"   call Decho("override K map to call ".g:manpageview_K_{ext})
   exe "nmap <silent> K :call ".g:manpageview_K_{ext}."\<cr>"
  endif

  if exists("g:manpageview_syntax_{ext}") && g:manpageview_syntax_{ext} != ""
   " allow special-suffix extensions to optionally control syntax highlighting
   let manpageview_syntax= g:manpageview_syntax_{ext}
  else
   let manpageview_syntax= "man"
  endif

  " support for searching for options from conf pages {{{3
  if manpagebook == "" && manpageview_fname =~ '\.conf$'
   let manpagesrch = '^\s\+'.manpagetopic
   let manpagetopic= manpageview_fname
  endif
"  call Decho("manpagebook<".manpagebook."> manpagetopic<".manpagetopic.">")

  " it was reported to me that some systems change display sizes when a {{{3
  " filtering command is used such as :r! .  I record the height&width
  " here and restore it afterwards.  To make use of it, put
  "   let g:manpageview_dispresize= 1
  " into your <.vimrc>
  let dwidth  = &cwh
  let dheight = &co
"  call Decho("dwidth=".dwidth." dheight=".dheight)

  " Set up the window for the manpage display (only hsplit split etc) {{{3
"  call Decho("set up window for manpage display (g:manpageview_winopen<".g:manpageview_winopen."> ft<".&ft."> manpageview_syntax<".manpageview_syntax.">)")
  if     g:manpageview_winopen == "only"
"   call Decho("only mode")
   silent! windo w
   if !exists("g:ManCurPosn") && has("mksession")
    call s:ManSavePosn()
   endif
   " Record current file/position/screen-position
   if &ft != manpageview_syntax
    silent! only!
   endif
   enew!
  elseif g:manpageview_winopen == "hsplit"
"   call Decho("hsplit mode")
   if &ft != manpageview_syntax
    wincmd s
    enew!
    wincmd _
    3wincmd -
   else
    enew!
   endif
  elseif g:manpageview_winopen == "hsplit="
"   call Decho("hsplit= mode")
   if &ft != manpageview_syntax
    wincmd s
   endif
   enew!
  elseif g:manpageview_winopen == "vsplit"
"   call Decho("vsplit mode")
   if &ft != manpageview_syntax
    wincmd v
    enew!
    wincmd |
    20wincmd <
   else
    enew!
   endif
  elseif g:manpageview_winopen == "vsplit="
"   call Decho("vsplit= mode")
   if &ft != "man"
    wincmd v
   endif
   enew!
  elseif g:manpageview_winopen == "reuse"
"   call Decho("reuse mode")
   " determine if a Manpageview window already exists
   let g:manpageview_manwin= -1
   exe "windo if &ft == '".fnameescape(manpageview_syntax)."'|let g:manpageview_manwin= winnr()|endif"
   if g:manpageview_manwin != -1
	" found a pre-existing Manpageview window, re-using it
	exe fnameescape(g:manpageview_manwin)."wincmd w"
    enew!
   elseif &l:mod == 1
   	" file has been modified, would be lost if we re-used window.  Use hsplit instead.
    wincmd s
    enew!
    wincmd _
    3wincmd -
   elseif &ft != manpageview_syntax
	" re-using current window (but hiding it first)
   	setlocal bh=hide
    enew!
   else
    enew!
   endif
  else
   echohl ErrorMsg
   echo "***sorry*** g:manpageview_winopen<".g:manpageview_winopen."> not supported"
   echohl None
   sleep 2
   call s:MPVRestoreSettings()
"   call Dret("manpageview#ManPageView : manpageview_winopen<".g:manpageview_winopen."> not supported")
   return
  endif

  " let manpages format themselves to specified window width
  " this setting probably only affects the linux "man" command.
  let $MANWIDTH= winwidth(0)

  " add some maps for multiple manpage handling {{{3
  if g:manpageview_multimanpage
   nmap <silent> <script> <buffer> <PageUp>				:call search("^NAME$",'bW')<cr>z<cr>5<c-y>
   nmap <silent> <script> <buffer> <PageDown>			:call search("^NAME$",'W')<cr>z<cr>5<c-y>
  endif

  " allow K to use <cWORD> when in man pages
  if manpageview_syntax == "man"
   nmap <silent> <script> <buffer>	K   :<c-u>let g:mpv_before_k_posn= SaveWinPosn(0)<bar>call manpageview#ManPageView(1,v:count,expand("<cWORD>"))<CR>
  endif

  " allow user to specify file encoding {{{3
  if exists("g:manpageview_fenc")
   exe "setlocal fenc=".fnameescape(g:manpageview_fenc)
  endif

  " when this buffer is exited it will be wiped out {{{3
  if v:version >= 602
   setlocal bh=wipe
  endif
  let b:did_ftplugin= 2
  let $COLUMNS=winwidth(0)

  " special manpageview buffer maps {{{3
  nnoremap <buffer> <space>     <c-f>
  nnoremap <buffer> <c-]>       :call manpageview#ManPageView(1,expand("<cWORD>"))<cr>

  " -----------------------------------------
  " Invoke the man command to get the manpage {{{3
  " -----------------------------------------

  " the buffer must be modifiable for the manpage to be loaded via :r! {{{4
  setlocal ma

  let cmdmod= ""
  if v:version >= 603
   let cmdmod= "silent keepjumps "
  endif

  " extension-based initialization (expected: buffer-specific maps) {{{4
  if exists("g:manpageview_init_{ext}")
   if !exists("b:manpageview_init_{ext}")
"    call Decho("exe manpageview_init_".ext."<".g:manpageview_init_{ext}.">")
	exe g:manpageview_init_{ext}
	let b:manpageview_init_{ext}= 1
   endif
  elseif ext == ""
   silent! unmap K
   nmap <unique> K <Plug>ManPageView
  endif

  " default program g:manpageview_options (empty string) may be overridden {{{4
  " if an extension is matched
  let opt= g:manpageview_options
  if exists("g:manpageview_options_{ext}")
   let opt= g:manpageview_options_{ext}
  endif
"  call Decho("opt<".opt.">")

  let cnt= 0
  while cnt < 3 && (strlen(opt) > 0 || cnt == 0)
   let cnt   = cnt + 1
   let iopt  = substitute(opt,';.*$','','e')
   let opt   = substitute(opt,'^.\{-};\(.*\)$','\1','e')
"   call Decho("cnt=".cnt." iopt<".iopt."> opt<".opt."> s:iconv<".s:iconv.">")

   " use pgm to read/find/etc the manpage (but only if pgm is not the empty string)
   " by default, pgm is "man"
   if pgm != ""

	" ---------------------------
	" use manpage_lookup function {{{4
	" ---------------------------
   	if exists("g:manpageview_lookup_{ext}")
"	 call Decho("lookup: exe call ".g:manpageview_lookup_{ext}."(".manpagebook.",".manpagetopic.")")
	 exe "call ".fnameescape(g:manpageview_lookup_{ext}."(".manpagebook.",".manpagetopic.")")

    elseif has("win32") && exists("g:manpageview_server") && exists("g:manpageview_user")
"     call Decho("win32: manpagebook<".manpagebook."> topic<".manpagetopic.">")
     exe cmdmod."r!".g:manpageview_rsh." ".g:manpageview_server." -l ".g:manpageview_user." ".pgm." ".iopt." ".shellescape(manpagebook,1)." ".shellescape(manpagetopic,1)
     exe cmdmod.'silent!  %s/.\b//ge'

"   elseif has("conceal")
"    exe cmdmod."r!".pgm." ".iopt." ".shellescape(manpagebook,1)." ".shellescape(manpagetopic,1)

	"--------------------------
	" use pgm to obtain manpage {{{4
	"--------------------------
    else
	 if manpagebook != ""
	  let mpb= shellescape(manpagebook,1)
	 else
	  let mpb= ""
	 endif
     if nospace
"      call Decho("(nospace) exe silent! ".cmdmod."r!".pgm.iopt.mpb.manpagetopic.s:iconv)
      exe cmdmod."r!".pgm.iopt.mpb.shellescape(manpagetopic,1).s:iconv
     elseif has("win32")
"	   call Decho("(win32) exe ".cmdmod."r!".pgm." ".iopt." ".mpb." \"".manpagetopic."\" ".s:iconv)
       exe cmdmod."r!".pgm." ".iopt." ".mpb." ".shellescape(manpagetopic,1)." ".s:iconv
	 else
"	  call Decho("(nrml) exe ".cmdmod."r!".pgm." ".iopt." ".mpb." '".manpagetopic."' ".s:iconv)
      exe cmdmod."r!".pgm." ".iopt." ".mpb." ".shellescape(manpagetopic,1)." ".s:iconv
	endif
     exe cmdmod.'silent!  %s/.\b//ge'
    endif
	setlocal ro nomod noswf
   endif

   " check if manpage actually found {{{3
   if line("$") != 1 || col("$") != 1
"    call Decho("manpage found")
    break
   endif
"   call Decho("manpage not found")
   if cnt == 3 && !exists("g:manpageview_iconv") && s:iconv != ""
	let s:iconv= ""
"	call Decho("trying with no iconv")
   endif
  endwhile

  " here comes the vim display size restoration {{{3
  if exists("g:manpageview_dispresize")
   if g:manpageview_dispresize == 1
"    call Decho("restore display size to ".dheight."x".dwidth)
    exe "let &co=".dwidth
    exe "let &cwh=".dheight
   endif
  endif

  " clean up (ie. remove) any ansi escape sequences {{{3
  silent! %s/\e\[[0-9;]\{-}m//ge
  silent! %s/\%xe2\%x80\%x90/-/ge
  silent! %s/\%xe2\%x88\%x92/-/ge
  silent! %s/\%xe2\%x80\%x99/'/ge
  silent! %s/\%xe2\%x94\%x82/ /ge

  " set up options and put cursor at top-left of manpage {{{3
  if manpagebook == "-k"
   setlocal ft=mankey
  else
   exe cmdmod."setlocal ft=".fnameescape(manpageview_syntax)
  endif
  exe cmdmod."setlocal ro"
  exe cmdmod."setlocal noma"
  exe cmdmod."setlocal nomod"
  exe cmdmod."setlocal nolist"
  exe cmdmod."setlocal nonu"
  exe cmdmod."setlocal fdc=0"
"  exe cmdmod."setlocal isk+=-,.,(,)"
  exe cmdmod."setlocal nowrap"
  set nolz
  exe cmdmod."1"
  exe cmdmod."norm! 0"

  if line("$") == 1 && col("$") == 1
   " looks like there's no help for this topic
   if &ft == manpageview_syntax
	if exists("s:manpageview_curtopic")
	 call manpageview#ManPageView(0,0,s:manpageview_curtopic)
	else
	 q
	endif
   endif
   call SaveWinPosn()
"   call Decho("***warning*** no manpage exists for <".manpagetopic."> book=".manpagebook)
   echohl ErrorMsg
   echo "***warning*** sorry, no manpage exists for <".manpagetopic.">"
   echohl None
   sleep 2
   if exists("g:mpv_before_k_posn")
	sil! call RestoreWinPosn(g:mpv_before_k_posn)
	unlet g:mpv_before_k_posn
   endif
  elseif manpagebook == ""
"   call Decho('exe file '.fnameescape('Manpageview['.manpagetopic.']'))
   exe 'file '.fnameescape('Manpageview['.manpagetopic.']')
   let s:manpageview_curtopic= manpagetopic
  else
"   call Decho('exe file '.fnameescape('Manpageview['.manpagetopic.'('.fnameescape(manpagebook).')]'))
   exe 'file '.fnameescape('Manpageview['.manpagetopic.'('.fnameescape(manpagebook).')]')
   let s:manpageview_curtopic= manpagetopic."(".manpagebook.")"
  endif

  " if there's a search pattern, use it {{{3
  if exists("manpagesrch")
   if search(manpagesrch,'w') != 0
    exe "norm! z\<cr>"
   endif
  endif

  " restore settings {{{3
  call s:MPVRestoreSettings()
"  call Dret("manpageview#ManPageView")
endfun

" ---------------------------------------------------------------------
" s:MPVSaveSettings: save and standardize certain user settings {{{2
fun! s:MPVSaveSettings()

  if !exists("s:sxqkeep")
"   call Dfunc("s:MPVSaveSettings()")
   let s:manwidth          = expand("$MANWIDTH")
   let s:sxqkeep           = &sxq
   let s:srrkeep           = &srr
   let s:repkeep           = &report
   let s:gdkeep            = &gd
   let s:cwhkeep           = &cwh
   let s:magickeep         = &l:magic
   setlocal srr=> report=10000 nogd magic
   if &cwh < 2
    " avoid hit-enter prompts
    setlocal cwh=2
   endif
  if has("win32") || has("win95") || has("win64") || has("win16")
   let &sxq= '"'
  else
   let &sxq= ""
  endif
  let s:curmanwidth = $MANWIDTH
  let $MANWIDTH     = winwidth(0)
"  call Dret("s:MPVSaveSettings")
 endif

endfun

" ---------------------------------------------------------------------
" s:MPV_RestoreSettings: {{{2
fun! s:MPVRestoreSettings()
  if exists("s:sxqkeep")
"   call Dfunc("s:MPV_RestoreSettings()")
   let &sxq      = s:sxqkeep     | unlet s:sxqkeep
   let &srr      = s:srrkeep     | unlet s:srrkeep
   let &report   = s:repkeep     | unlet s:repkeep
   let &gd       = s:gdkeep      | unlet s:gdkeep
   let &cwh      = s:cwhkeep     | unlet s:cwhkeep
   let &l:magic  = s:magickeep   | unlet s:magickeep
   let $MANWIDTH = s:curmanwidth | unlet s:curmanwidth
"   call Dret("s:MPV_RestoreSettings")
  endif
endfun

" ---------------------------------------------------------------------
" s:ManRestorePosn: restores file/position/screen-position {{{2
"                 (uses g:ManCurPosn)
fun! s:ManRestorePosn()
"  call Dfunc("s:ManRestorePosn()")

  if exists("g:ManCurPosn")
"   call Decho("g:ManCurPosn<".g:ManCurPosn.">")
   if v:version >= 603
	exe 'keepjumps silent! source '.fnameescape(g:ManCurPosn)
   else
	exe 'silent! source '.fnameescape(g:ManCurPosn)
   endif
   unlet g:ManCurPosn
   silent! cunmap q
  endif

"  call Dret("s:ManRestorePosn")
endfun

" ---------------------------------------------------------------------
" s:ManSavePosn: saves current file, line, column, and screen position {{{2
fun! s:ManSavePosn()
"  call Dfunc("s:ManSavePosn()")

  let g:ManCurPosn= tempname()
  let keep_ssop   = &ssop
  let &ssop       = 'winpos,buffers,slash,globals,resize,blank,folds,help,options,winsize'
  if v:version >= 603
   exe 'keepjumps silent! mksession! '.fnameescape(g:ManCurPosn)
  else
   exe 'silent! mksession! '.fnameescape(g:ManCurPosn)
  endif
  let &ssop       = keep_ssop
  cnoremap <silent> q call <SID>ManRestorePosn()<CR>

"  call Dret("s:ManSavePosn")
endfun

" ---------------------------------------------------------------------
" s:ManPageInfo: {{{2
fun! s:ManPageInfo(type)
"  call Dfunc("s:ManPageInfo(type=".a:type.")")
  let s:before_K_posn= SaveWinPosn(0)

  if &ft != "info"
   " restore K and do a manpage lookup for word under cursor
"   call Decho("ft!=info: restore K and do a manpage lookup of word under cursor")
   setlocal kp=manpageview#ManPageView
   if exists("s:manpageview_pfx_i")
    unlet s:manpageview_pfx_i
   endif
   call manpageview#ManPageView(1,0,expand("<cWORD>"))
"   call Dret("s:ManPageInfo : restored K")
   return
  endif

  if !exists("s:manpageview_pfx_i")
   let s:manpageview_pfx_i= g:manpageview_pfx_i
  endif

  " -----------
  " Follow Link
  " -----------
  if a:type == 0
   " extract link
   let curline  = getline(".")
"   call Decho("type==0: curline<".curline.">")
   let ipat     = 1
   while ipat <= 4
    let link= matchstr(curline,s:linkpat{ipat})
"	call Decho("..attempting s:linkpat".ipat.":<".s:linkpat{ipat}.">")
    if link != ""
     if ipat == 2
      let s:manpageview_pfx_i = substitute(link,s:linkpat{ipat},'\1','')
      let node                = "Top"
     else
      let node                = substitute(link,s:linkpat{ipat},'\1','')
 	 endif
"   	 call Decho("ipat=".ipat."link<".link."> node<".node."> pfx<".s:manpageview_pfx_i.">")
 	 break
    endif
    let ipat= ipat + 1
   endwhile

  " ---------------
  " Go to next node
  " ---------------
  elseif a:type == 1
"   call Decho("type==1: goto next node")
   let node= matchstr(getline(2),'Next: \zs[^,]\+\ze,')
   let fail= "no next node"

  " -------------------
  " Go to previous node
  " -------------------
  elseif a:type == 2
"   call Decho("type==2: goto previous node")
   let node= matchstr(getline(2),'Prev: \zs[^,]\+\ze,')
   let fail= "no previous node"

  " ----------
  " Go up node
  " ----------
  elseif a:type == 3
"   call Decho("type==3: go up one node")
   let node= matchstr(getline(2),'Up: \zs.\+$')
   let fail= "no up node"
   if node == "(dir)"
	echo "***sorry*** can't go up from this node"
"    call Dret("s:ManPageInfo : can't go up a node")
    return
   endif

  " --------------
  " Go to top node
  " --------------
  elseif a:type == 4
"   call Decho("type==4: go to top node")
   let node= "Top"
  endif
"  call Decho("node<".(exists("node")? node : '--n/a--').">")

  " use ManPageView() to view selected node
  if !exists("node")
   echohl ErrorMsg
   echo "***sorry*** unable to view selection"
   echohl None
   sleep 2
  elseif node == ""
   echohl ErrorMsg
   echo "***sorry*** ".fail
   echohl None
   sleep 2
  else
   call manpageview#ManPageView(1,0,node.".i")
  endif

"  call Dret("s:ManPageInfo")
endfun

" ---------------------------------------------------------------------
" ManPageInfoInit: {{{2
fun! ManPageInfoInit()
"  call Dfunc("ManPageInfoInit()")

  " some mappings to imitate the default info reader
  nmap    <buffer> 			<cr>	K
  noremap <buffer> <silent>	>		:call <SID>ManPageInfo(1)<cr>
  noremap <buffer> <silent>	n		:call <SID>ManPageInfo(1)<cr>
  noremap <buffer> <silent>	<		:call <SID>ManPageInfo(2)<cr>
  noremap <buffer> <silent>	p		:call <SID>ManPageInfo(2)<cr>
  noremap <buffer> <silent>	u		:call <SID>ManPageInfo(3)<cr>
  noremap <buffer> <silent>	t		:call <SID>ManPageInfo(4)<cr>
  noremap <buffer> <silent>	?		:he manpageview-info<cr>
  noremap <buffer> <silent>	d		:call manpageview#ManPageView(0,0,"dir.i")<cr>
  noremap <buffer> <silent>	<BS>	<C-B>
  noremap <buffer> <silent>	<Del>	<C-B>
  noremap <buffer> <silent>	<Tab>	:call <SID>NextInfoLink()<CR>
  noremap <buffer> <silent>	i		:call <SID>InfoIndexLink('i')<CR>
  noremap <buffer> <silent>	,		:call <SID>InfoIndexLink(',')<CR>
  noremap <buffer> <silent>	;		:call <SID>InfoIndexLink(';')<CR>

"  call Dret("ManPageInfoInit")
endfun

" ---------------------------------------------------------------------
" s:NextInfoLink: {{{2
fun! s:NextInfoLink()
    let ln = search('\('.s:linkpat1.'\|'.s:linkpat2.'\|'.s:linkpat3.'\|'.s:linkpat4.'\)', 'w')
    if ln == 0
		echohl ErrorMsg
	   	echo '***sorry*** no links found' 
	   	echohl None
		sleep 2
    endif
endfun

" ---------------------------------------------------------------------
" s:InfoIndexLink: supports info's "i" for index-search-for-topic {{{2
fun! s:InfoIndexLink(cmd)
"  call Dfunc("s:InfoIndexLink(cmd<".a:cmd.">)")
"  call Decho("indx vars: line #".(exists("s:indxline")? s:indxline : '---'))
"  call Decho("indx vars: cnt  =".(exists("s:indxcnt")? s:indxcnt : '---'))
"  call Decho("indx vars: find =".(exists("s:indxfind")? s:indxfind : '---'))
"  call Decho("indx vars: link <".(exists("s:indxlink")? s:indxlink : '---').">")
"  call Decho("indx vars: where<".(exists("s:wheretopic")? s:wheretopic : '---').">")
"  call Decho("indx vars: srch <".(exists("s:indxsrchdir")? s:indxsrchdir : '---').">")

  " sanity checks
  if !exists("s:manpagetopic")
   echohl Error
   echo "(InfoIndexLink) no manpage topic available!"
   echohl NONE
"   call Dret("s:InfoIndexLink : no manpagetopic")
   return

  elseif !executable("info")
   echohl Error
   echo '(InfoIndexLink) the info command is not executable!'
   echohl NONE
"   call Dret("s:InfoIndexLink : info not exe")
   return
  endif

  if a:cmd == 'i'
   call inputsave()
   let s:infolink= input("Index entry: ","","shellcmd")
   call inputrestore()
   let s:indxfind= -1
  endif
"  call Decho("infolink<".s:infolink.">")

  if s:infolink != ""

   if a:cmd == 'i'
	let mpt= substitute(s:manpagetopic,'\.i','','')
"	call Decho('system("info '.mpt.' --where")')
	let s:wheretopic    = substitute(system("info ".shellescape(mpt)." --where"),'\n','','g')
    let s:indxline      = 1
    let s:indxcnt       = 0
	let s:indxsrchdir   = 'cW'
"	call Decho("new indx vars: cmd<i> where<".s:wheretopic.">")
"	call Decho("new indx vars: cmd<i> line#".s:indxline)
"	call Decho("new indx vars: cmd<i> cnt =".s:indxcnt)
"	call Decho("new indx vars: cmd<i> srch<".s:indxsrchdir.">")
   elseif a:cmd == ','
	let s:indxsrchdir= 'W'
"	call Decho("new indx vars: cmd<,> srch<".s:indxsrchdir.">")
   elseif a:cmd == ';'
	let s:indxsrchdir= 'bW'
"	call Decho("new indx vars: cmd<;> srch<".s:indxsrchdir.">")
   endif

   let cmdmod= ""
   if v:version >= 603
    let cmdmod= "silent keepjumps "
   endif

   let wheretopic= s:wheretopic
   if s:indxcnt != 0
	let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info-'.s:indxcnt.".",'')
   else
	let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info.','')
   endif
"   call Decho("initial wheretopic<".wheretopic."> indxcnt=".s:indxcnt)

   " search for topic in various files loop
   while filereadable(wheretopic)
"	call Decho("--- while loop: where<".wheretopic."> indxcnt=".s:indxcnt." indxline#".s:indxline)

	" read file <topic.info-#.gz>
    setlocal ma
    silent! %d
	if s:indxcnt != 0
	 let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info-'.s:indxcnt.".",'')
	else
	 let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info.','')
	endif
"    call Decho("    exe ".cmdmod."r ".fnameescape(wheretopic))
    try
	 exe cmdmod."r ".fnameescape(wheretopic)
	catch /^Vim\%((\a\+)\)\=:E484/
	 break
	finally
	 if search('^File:','W') != 0
	  silent 1,/^File:/-1d
	  1put! =''
	 else
	  1d
	 endif
	endtry
	setlocal noma nomod

	if s:indxline < 0
	 if a:cmd == ','
	  " searching forwards
	  let s:indxline= 1
"	  call Decho("    searching forwards from indxline#".s:indxline)
	 elseif a:cmd == ';'
	  " searching backwards
	  let s:indxline= line("$")
"	  call Decho("    searching backwards from indxline#".s:indxline)
	 endif
	endif

	if s:indxline != 0
"     call Decho("    indxline=".s:indxline." infolink<".s:infolink."> srchflags<".s:indxsrchdir.">")
	 exe fnameescape(s:indxline)
     let s:indxline= search('^\n\zs'.s:infolink.'\>\|^[0-9.]\+.*\zs\<'.s:infolink.'\>',s:indxsrchdir)
"     call Decho("    search(".s:infolink.",".s:indxsrchdir.") yields: s:indxline#".s:indxline)
     if s:indxline != 0
	  let s:indxfind= s:indxcnt
	  echo ",=Next Match  ;=Previous Match"
"      call Dret("s:InfoIndexLink : success!  (indxfind=".s:indxfind.")")
      return
     endif
	endif

	if a:cmd == 'i' || a:cmd == ','
	 let s:indxcnt  = s:indxcnt + 1
	 let s:indxline = 1
	elseif a:cmd == ';'
	 let s:indxcnt  = s:indxcnt - 1
	 if s:indxcnt < 0
	  let s:indxcnt= 0
"	  call Decho("    new indx vars: cmd<".a:cmd."> indxcnt=".s:indxcnt)
	  break
	 endif
	 let s:indxline = -1
	endif
"	call Decho("    new indx vars: cmd<".a:cmd."> indxcnt =".s:indxcnt)
"	call Decho("    new indx vars: cmd<".a:cmd."> indxline#".s:indxline)
   endwhile
  endif
"  call Decho("end-while indx vars: find=".s:indxfind." cnt=".s:indxcnt)

  " clear screen
  setlocal ma
  silent! %d
  setlocal noma nomod

  if s:indxfind < 0
   " unsuccessful :(
   echohl WarningMsg
   echo "(InfoIndexLink) unable to find info for topic<".s:manpagetopic."> indx<".s:infolink.">"
   echohl NONE
"   call Dret("s:InfoIndexLink : unable to find info for ".s:manpagetopic.":".s:infolink)
   return
  elseif a:cmd == ','
   " no more matches
   let s:indxcnt = s:indxcnt - 1
   let s:indxline= 1
   echohl WarningMsg
   echo "(InfoIndexLink) no more matches"
   echohl NONE
"   call Dret("s:InfoIndexLink : no more matches")
   return
  elseif a:cmd == ';'
   " no more matches
   let s:indxcnt = s:indxfind
   let s:indxline= -1
   echohl WarningMsg
   echo "(InfoIndexLink) no previous matches"
   echohl NONE
"   call Dret("s:InfoIndexLink : no previous matches")
   return
  endif
endfun

" ---------------------------------------------------------------------
" manpageview#ManPageTex: {{{2
fun! manpageview#ManPageTex()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = '\'.expand("<cWORD>")
"  call Dfunc("manpageview#ManPageTex() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPageTex")
endfun

" ---------------------------------------------------------------------
" manpageview#ManPageTexLookup: {{{2
fun! manpageview#ManPageTexLookup(book,topic)
"  call Dfunc("manpageview#ManPageTexLookup(book<".a:book."> topic<".a:topic.">)")
"  call Dret("manpageview#ManPageTexLookup ".lookup)
endfun

" ---------------------------------------------------------------------
" manpageview#:ManPagePhp: {{{2
fun! manpageview#ManPagePhp()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = substitute(expand("<cWORD>"),'()\=.*$','.php','')
"  call Dfunc("manpageview#ManPagePhp() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPagePhp")
endfun

" ---------------------------------------------------------------------
" manpageview#:ManPagePython: {{{2
fun! manpageview#ManPagePython()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = substitute(expand("<cWORD>"),'()\=.*$','.py','')
"  call Dfunc("manpageview#ManPagePython() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPagePython")
endfun

" ---------------------------------------------------------------------
" manpageview#KMan: set default extension for K map {{{2
fun! manpageview#KMan(ext)
"  call Dfunc("manpageview#KMan(ext<".a:ext.">)")

  let s:before_K_posn = SaveWinPosn(0)
  if a:ext == "perl"
   let ext= "pl"
  elseif a:ext == "gvim"
   let ext= "vim"
  elseif a:ext == "info" || a:ext == "i"
   let ext    = "i"
   set ft=info
  elseif a:ext == "man"
   let ext= ""
  else
   let ext= a:ext
  endif
"  call Decho("ext<".ext.">")

  " change the K map
  silent! nummap K
  silent! nunmap <buffer> K
  if exists("g:manpageview_K_{ext}") && g:manpageview_K_{ext} != ""
   exe "nmap <silent> <buffer> K :call ".g:manpageview_K_{ext}."\<cr>"
"   call Decho("nmap <silent> K :call ".g:manpageview_K_{ext})
  else
   nmap <unique> K <Plug>ManPageView
"   call Decho("nmap <unique> K <Plug>ManPageView")
  endif

"  call Dret("manpageview#KMan ")
endfun

let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
" Modeline: {{{1
" vim: ts=4 fdm=marker
syntax/man.vim	[[[1
106
" Vim syntax file
"  Language:	Manpageview
"  Maintainer:	Charles E. Campbell, Jr.
"  Last Change:	Aug 12, 2008
"  Version:    	6	ASTRO-ONLY
"
"  History:
"    2: * Now has conceal support
"       * complete substitute for distributed <man.vim>
" ---------------------------------------------------------------------
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif
if !has("conceal")
 " hide control characters, especially backspaces
 if version >= 600
  run! syntax/ctrlh.vim
 else
  so <sfile>:p:h/ctrlh.vim
 endif
endif

syn case ignore
" following four lines taken from Vim's <man.vim>:
syn match  manReference		"\f\+([1-9]\l\=)"
syn match  manSectionTitle	'^\u\{2,}\(\s\+\u\{2,}\)*'
syn match  manSubSectionTitle	'^\s+\zs\u\{2,}\(\s\+\u\{2,}\)*'
syn match  manTitle		"^\f\+([0-9]\+\l\=).*"
syn match  manSectionHeading	"^\l[a-z ]*\l$"
syn match  manOptionDesc	"^\s*\zs[+-]\{1,2}\w\S*"

syn match  manSectionHeading	"^\s\+\d\+\.[0-9.]*\s\+\u.*$"		contains=manSectionNumber
syn match  manSectionNumber	"^\s\+\d\+\.\d*"			contained
syn region manDQString		start='[^a-zA-Z"]"[^", )]'lc=1		end='"'		end='^$' contains=manSQString
syn region manSQString		start="[ \t]'[^', )]"lc=1		end="'"		end='^$'
syn region manSQString		start="^'[^', )]"lc=1			end="'"		end='^$'
syn region manBQString		start="[^a-zA-Z`]`[^`, )]"lc=1		end="[`']"	end='^$'
syn region manBQString		start="^`[^`, )]"			end="[`']"	end='^$'
syn region manBQSQString	start="``[^),']"			end="''"	end='^$'
syn match  manBulletZone	"^\s\+o\s"				transparent contains=manBullet
syn case match

syn keyword manBullet		o					contained
syn match   manBullet		"\[+*]"					contained
syn match   manSubSectionStart	"^\*"					skipwhite nextgroup=manSubSection
syn match   manSubSection	".*$"					contained
syn match   manOptionWord	"\s[+-]\a\+\>"

if has("conceal")
 setlocal cole=3
 syn match manSubTitle		/\(.\b.\)\+/	contains=manSubTitleHide
 syn match manUnderline		/\(_\b.\)\+/	contains=manSubTitleHide
 syn match manSubTitleHide	/.\b/		conceal contained
endif

" my RH8 linux's man page puts some pretty oddball characters into its
" manpages...
silent! %s/’/'/ge
silent! %s/−/-/ge
silent! %s/‐$/-/e
silent! %s/‘/`/ge
silent! %s/‐/-/ge
norm! 1G

set ts=8

com! -nargs=+ HiLink hi def link <args>

HiLink manTitle		Title
"  HiLink manSubTitle		Statement
HiLink manUnderline		Type
HiLink manSectionHeading	Statement
HiLink manOptionDesc		Constant

HiLink manReference		PreProc
HiLink manSectionTitle	Function
HiLink manSectionNumber	Number
HiLink manDQString		String
HiLink manSQString		String
HiLink manBQString		String
HiLink manBQSQString		String
HiLink manBullet		Special
if has("win32") || has("win95") || has("win64") || has("win16")
 if &shell == "bash"
  hi manSubSectionStart	term=NONE      cterm=NONE      gui=NONE      ctermfg=black ctermbg=black guifg=navyblue guibg=navyblue
  hi manSubSection		term=underline cterm=underline gui=underline ctermfg=green guifg=green
  hi manSubTitle		term=NONE      cterm=NONE      gui=NONE      ctermfg=cyan  ctermbg=blue  guifg=cyan     guibg=blue
 else
  hi manSubSectionStart	term=NONE      cterm=NONE      gui=NONE      ctermfg=black ctermbg=black guifg=black    guibg=black
  hi manSubSection		term=underline cterm=underline gui=underline ctermfg=green guifg=green
  hi manSubTitle		term=NONE      cterm=NONE      gui=NONE      ctermfg=cyan  ctermbg=blue  guifg=cyan     guibg=blue
 endif
else
 hi manSubSectionStart	term=NONE      cterm=NONE      gui=NONE      ctermfg=black ctermbg=black guifg=navyblue guibg=navyblue
 hi manSubSection		term=underline cterm=underline gui=underline ctermfg=green guifg=green
 hi manSubTitle		term=NONE      cterm=NONE      gui=NONE      ctermfg=cyan  ctermbg=blue  guifg=cyan     guibg=blue
endif
"  hi link manSubSectionTitle	manSubTitle

delcommand HiLink

let b:current_syntax = "man"

" vim:ts=8
syntax/mangl.vim	[[[1
34
" mangl.vim : a vim syntax highlighting file for man pages on GL
"   Author: Charles E. Campbell, Jr.
"   Date:   Nov 23, 2010
"   Version: 1a	NOT RELEASED
" ---------------------------------------------------------------------
syn clear
let b:current_syntax = "mangl"

syn keyword manglGLType		GLbyte GLenum GLshort GLint GLdouble GLubyte GLuint GLfloat GLushort
syn keyword manglCType		const void char short int long double unsigned
syn match	manglCType		'\s\*\s'
syn match	manglGLKeyword	'\<[A-Z_]\{2,}\>'
syn keyword	manglNormal		GL

syn match	manglTitle		'^\s*\%(Name\|C Specification\|Parameters\|Description\|Notes\|Associated Gets\|See Also\|Copyright\|Errors\|References\)\s*$'
syn match	manglNmbr		'\<\d\+\%(\.\d*\)\=\>'
syn match	manglDelim		'[()]'

hi def link manglGLType		Type
hi def link manglCType		Type
hi def link manglTitle		Title
hi def link manglNmbr		Number
hi def link manglDelim		Delimiter
hi def link manglGLKeyword	Keyword

" cleanup
if !exists("g:mangl_nocleanup")
 setlocal mod ma noro
 %s/ ? /   /ge
 %s/\[\d\+]//ge
 %s/\(\d\+\)\s\+\*\s\+/\1*/ge
 %s@\<N\> \(\d\)@N/\1@ge
 setlocal nomod noma ro
endif
syntax/mankey.vim	[[[1
39
" Vim syntax file
"  Language:	Man keywords page
"  Maintainer:	Charles E. Campbell, Jr.
"  Last Change:	Aug 12, 2008
"  Version:    	2
"    (used by plugin/manpageview.vim)
"
"  History:
"    2: hi default link -> hi default link
"    1:	The Beginning
" ---------------------------------------------------------------------
"  Initialization:
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif
syn clear

" ---------------------------------------------------------------------
"  Highlighting Groups: matches, ranges, and keywords
syn match mankeyTopic	'^\S\+'		skipwhite nextgroup=mankeyType,mankeyBook
syn match mankeyType	'\[\S\+\]'	contained skipwhite nextgroup=mankeySep,mankeyBook contains=mankeyTypeDelim
syn match mankeyTypeDelim	'[[\]]'	contained
syn region mankeyBook	matchgroup=Delimiter start='(' end=')'	contained skipwhite nextgroup=mankeySep
syn match mankeySep		'\s\+-\s\+'	

" ---------------------------------------------------------------------
"  Highlighting Colorizing Links:
command! -nargs=+ HiLink hi default link <args>

HiLink mankeyTopic		Statement
HiLink mankeyType		Type
HiLink mankeyBook		Special
HiLink mankeyTypeDelim	Delimiter
HiLink mankeySep		Delimiter

delc HiLink
let b:current_syntax = "mankey"
syntax/info.vim	[[[1
32
" Info.vim : syntax highlighting for info
"  Language:	info
"  Maintainer:	Charles E. Campbell, Jr.
"  Last Change:	Aug 09, 2007
"  Version:		2b	ASTRO-ONLY
" syntax highlighting based on Slavik Gorbanyov's work
let g:loaded_syntax_info= "v1"

syn clear
syn case match
syn match  infoMenuTitle	/^\* Menu:/hs=s+2
syn match  infoTitle		/^[A-Z][0-9A-Za-z `',/&]\{,43}\([a-z']\|[A-Z]\{2}\)$/
syn match  infoTitle		/^[-=*]\{,45}$/
syn match  infoString		/`[^`]*'/
syn region infoLink			start=/\*[Nn]ote/ end=/::/
syn match  infoLink			/\*[Nn]ote \([^():]*\)\(::\|$\)/
syn match  infoLink			/^\* \([^:]*\)::/hs=s+2
syn match  infoLink			/^\* [^:]*: \(([^)]*)\)/hs=s+2
syn match  infoLink			/^\* [^:]*:\s\+[^(]/hs=s+2,he=e-2
syn region infoHeader		start=/^File:/ end="$" contains=infoHeaderLabel
syn match  infoHeaderLabel	/\<\%(File\|Node\|Next\|Prev\|Up\):\s/ contained

if !exists("g:did_info_syntax_inits")
  let g:did_info_syntax_inits = 1
  hi def link infoMenuTitle		Title
  hi def link infoTitle			Comment
  hi def link infoLink			Directory
  hi def link infoString		String
  hi def link infoHeader		infoLink
  hi def link infoHeaderLabel	Statement
endif
" vim: ts=4
syntax/manphp.vim	[[[1
74
" Vim syntax file
"  Language:	Man page syntax for php
"  Maintainer:	Charles E. Campbell, Jr.
"  Last Change:	Aug 12, 2008
"  Version:    	3
" ---------------------------------------------------------------------
syn clear
let b:current_syntax = "manphp"

syn keyword manphpKey			Description Returns
syn match   manphpFunction			"\<\S\+\ze\s*--"	skipwhite nextgroup=manphpDelimiter
syn match   manphpSkip				"^\s\+\*\s*\S\+\s*"
syn match   manphpSeeAlso			"\<See also\>"		skipwhite skipnl nextgroup=manphpSeeAlsoList
syn match   manphpSeeAlsoSep	contained	",\%( and\)\="		skipwhite skipnl nextgroup=manphpSeeAlsoList,manphpSeeAlsoSkip
syn match   manphpSeeAlsoList	contained	"\s*\zs[^,]\+\ze\%(,\%( and \)\=\)"	skipwhite skipnl nextgroup=manphpSeeAlsoSep
syn match   manphpSeeAlsoList	contained  	"\s*\zs[^,.]\+\ze\."
syn match   manphpSeeAlsoSkip	contained	"^\s\+\*\s*\S\+\s*"     skipwhite skipnl nextgroup=manphpSeeAlsoList
syn match   manphpDelimiter	contained	"\s\zs--\ze\s"		skipwhite nextgroup=manphpDesc
syn match   manphpDesc		contained	".*$"
syn match   manphpUserNote			"User Contributed Notes"
syn match   manphpEditor			"\[Editor's Note:.\{-}]"
syn match   manphpUser				"\a\+ at \a\+ dot .*$"
syn match   manphpFuncList			"PHP Function List"

hi default link manphpKey		Title
hi default link manphpFunction		Function
hi default link manphpDelimiter		Delimiter
hi default link manphpDesc		manphpFunction
hi default link manphpSeeAlso		Title
hi default link manphpSeeAlsoList	PreProc
hi default link manphpUserNote		Title
hi default link manphpEditor		Special
hi default link manphpUser		Search
hi default link manphpSeeAlsoSkip	Ignore
hi default link manphpSkip		Ignore
hi default link manphpFuncList		Title

" cleanup
if !exists("g:manphp_nocleanup")
 setlocal mod ma noro
 %s/\[\d\+]//ge
 %s/_\{2,}/__/ge
 %s/\<\%(add a note\)\+\>//ge
 1
 if search('(PHP','W')
  norm! k
  1,.d
 endif
 if search('\<References\>','W')
  /\<References\>/,$d
 endif
 if search('\<Description\>','w')
  exe '%s/^.*\%'.virtcol(".").'v//e'
  g/^\s\s\*\s/s/^.*$//
 endif
 %s/^\s*\(User Contributed Notes\)/\1/e
 %s/^\s*\(Returns\|See also\)\>/\1/e
 $
 if search('\S','bW')
  norm! j
  if line(".") != line("$")
   silent! .,$d
  endif
 endif
 if search('PHP Function List')
  if line(".") != 1
   1,.-1d
  endif
 endif
 setlocal nomod noma ro
endif

" ---------------------------------------------------------------------
" vim:ts=8
doc/manpageview.txt	[[[1
468
*manpageview.txt*	Man Page Viewer			Mar 29, 2011

Author:  Charles E. Campbell, Jr.  <NdrchipO@ScampbellPfamily.AbizM>
	  (remove NOSPAM from Campbell's email first)
Copyright: (c) 2004-2011 by Charles E. Campbell, Jr.	*manpageview-copyright*
           The VIM LICENSE applies to ManPageView.vim and ManPageView.txt
           (see |copyright|) except use "ManPageView" instead of "Vim"
	   no warranty, express or implied.  use at-your-own-risk.

==============================================================================
1. Contents			*manpageview* *manpageview-contents* {{{1

	1. Contents.................................: |manpageview-contents|
	2. ManPageView Usage........................: |manpageview-usage|
	     General Format.........................: |manpageview-format|
	     Man....................................: |manpageview-man|
	     Opening Style..........................: |manpageview-open|
	     K Map..................................: |manpageview-K|
	     Perl...................................: |manpageview-perl|
	     Info...................................: |manpageview-info|
	     Php....................................: |manpageview-php|
	     Extending ManPageView..................: |manpageview-extend|
	     Manpageview Suggestion.................: |manpageview-suggest|
	3. ManPageView Options......................: |manpageview-options|
	4. ManPageView History......................: |manpageview-history|

==============================================================================
2. ManPageView Usage				*manpageview-usage* {{{1

        GENERAL FORMAT				*manpageview-format* {{{2

		(command) :[count][HORV]Man [topic] [booknumber]
		(map)     [count]K

	MAN						*manpageview-man* {{{2
>
	:[count]Man topic
	:Man topic booknumber
	:Man booknumber topic
	:Man topic(booknumber)
	:Man      -- will restore position prior to use of :Man
	             (only for g:manpageview_winopen == "only")
<
	Put cursor on topic, press "K" while in normal mode.
	(This works if (a) you've not mapped some other key
	to <Plug>ManPageView, and (b) if |'keywordprg'| is "man",
	which it is by default)

	If a count is present (ie. 7K), the count will be used
	as the booknumber.

	If your "man" command requires options, you may specify them
	with the g:manpageview_options variable in your <.vimrc>.


	OPENING STYLE				*manpageview-open* {{{2

	In addition, one may specify open help and specify an
	opening style (see g:manpageview_winopen below): >

		:[count]HMan topic     -- g:manpageview_winopen= "hsplit"
		:[count]HEMan topic    -- g:manpageview_winopen= "hsplit="
		:[count]VMan topic     -- g:manpageview_winopen= "vsplit"
		:[count]VEMan topic    -- g:manpageview_winopen= "vsplit="
		:[count]OMan topic     -- g:manpageview_winopen= "osplit"
		:[count]RMan topic     -- g:manpageview_winopen= "reuse"
<
	To support perl, manpageview now can switch to using perldoc
	instead of man.  In fact, the facility is generalized to
	allow multiple help viewing systems.

	INFO					*manpageview-info* {{{2

	Info pages are supported by appending a ".i" suffix: >
		:Man info.i
<	A number of maps are provided: >
		MAP	EFFECT
		> n	go to next node
		< p	go to previous node
		d       go to the top-level directory
		u	go to up node
		t	go to top node
		H	give help
		i	ask for "index" help
		<bs>    go up one page
		<del>   go up one page
		<tab>   go to next hyperlink
<
	The "index" help isn't currently using index information; instead,
	its doing some searching in the various info files.  The "," and ";"
	operators are provided to go to the next and previous matches,
	respectively.

	K MAP					*manpageview-K* {{{2
>
		[count]K
<
	ManPageView also supports the use of "K", as a map, to
	invoke ManPageView.  The topic is taken from the word
	currently under the cursor.  If a [count] is present, it
	will be used as the booknumber.

	PERL					*manpageview-perl* {{{2

	For perl, the following command, >
		:Man sprintf.pl
<	will bring up the perldoc version of sprintf.  The perl
	support includes a "path" of options to use with perldoc: >
		g:manpageview_options_pl= ";-f;-q"
<	Thus just the one suffix (.pl) with manpageview handles
	embedded perl documentation, perl builtin functions, and
	perl FAQ keywords.

	If the filetype is "perl", which is determined by vim
	for syntax highlighting, the ".pl" suffix may be dropped.
	For example, when editing a "abc.pl" file, >
		:Man sprintf
<	will return the perl help for sprintf.

	PHP					*manpageview-php* {{{2

	For php help, Manpageview uses links to get help from
	http://www.php.net (by default).  The filetype as determined
	for syntax highlighting is used to signal manpageview to use
	php help.  As an example, >
		:Man bzopen.php
<	will get help for php's bzopen command.  When one is editing
	a php file, then man will default to getting help for php
	(ie. when the filetype is php, :Man bzopen will get the help
	for php's bzopen).

	Manpageview uses "links -dump http://www.php.net/TOPIC" by
	default; hence, to obtain help for php you need to have a
	copy of the links WWW browser.  The homepage for Elinks is
	http://elinks.cz/.

	PYTHON					*manpageview-python*

	For python help, Manpageview depends upon pydoc.  As an
	example, try >
		:Man pprint.py
<

	EXTENDING MANPAGEVIEW			*manpageview-extend* {{{2

	To extend manpageview to handle other documentation systems,
	manpageview has some special variables with a common extension: >

		g:manpageview_pgm_{ext}
		g:manpageview_options_{ext}
		g:manpageview_sfx_{ext}
<
	For perl, the {ext} is ".pl", and the variables are set to: >

     	     let g:manpageview_pgm_pl     = "perldoc"
     	     let g:manpageview_options_pl = ";-f;-q"
<
	For info, that {ext} is ".i", and the extension variables are
	set to: >

     	     let g:manpageview_pgm_i     = "info"
     	     let g:manpageview_options_i = "--output=-"
     	     let g:manpageview_syntax_i  = "info"
     	     let g:manpageview_K_i       = "<sid>ManPageInfo(0)"
     	     let g:manpageview_init_i    = "call ManPageInfoInit()"
<
	The help on |manpageview_extend| covers these variables in more
	detail.

	MULTIPLE MAN PAGES		*manpageview-pageup* *manpageview-pagedown*

        With >
		man -a topic
<	one may get multiple man pages in a single buffer.  Manpageview
	provides two maps to facilitate moving amongst these pages: >

		PageUp  : move to preceding  manpage
		PageDown: move to succeeding manpage
<
	MANPAGEVIEW SUGGESTION		*manpageview-suggest*

	As an example, for C: put in .vim/ftplugin/c/c.vim: >
		nno <buffer> K  :<c-u>exe v:count."Man ".expand("<cword>")<cr>
<	This map allows K to immediately use manpageview with functions in a
	C program.  One may make similar maps for other languages, of course,
	or simply put the map in one's <.vimrc>.



==============================================================================
3. ManPageView Options				*manpageview-options* {{{1

						*g:manpageview_iconv*
	g:manpageview_iconv   : some systems seem to include unwanted
		    characters. The iconv program can be used to filter out
		    such characters; by default, manpageview will use >
			iconv -c
<		    You may avoid manpageview's use of iconv by putting: >
			let g:manpageview_iconv= ""
<		    in your <.vimrc> file; you may also specify any other
		    filter you wish with this variable.  Also, if iconv
		    happens to not be |executable()|, then no filtering
		    will be done.  (Thanks to Matthew Wozniski).

		    As an example, Hong Xu reports that he has found that >
		      let g:manpageview_iconv= "iconv -c UTF-8 -t UTF-8"
<		    useful when using NetBSD.

						*g:manpageview_multimanpage*
	g:manpageview_multimanpage (=1 by default)
		    This option means that the PageUp and PageDown keys
		    will be mapped to move to the next and previous manpage
		    in a multi-man-page buffer.  Such buffers result with
		    the "man -a" option.  As an example: >
		    	:Man -a printf
<
						*g:manpageview_options*
	g:manpageview_options : extra options that will be passed on when
	                        invoking the man command
	  examples:
	            let g:manpageview_options= "-P 'cat -'"
	            let g:manpageview_options= "-c"
	            let g:manpageview_options= "-Tascii"

						*g:manpageview_pgm*
	g:manpageview_pgm : by default, its "man", but it may be changed
		     by the user.  This program is what is called to actually
		     extract the manpage.

						*g:manpageview_winopen*
	g:manpageview_winopen : may take on one of six values:

	   "only"    man page will become sole window.
	             Side effect: All windows' contents will be saved first!
		     (windo w) Use :q to terminate the manpage and restore the
		     window setup.  Note that mksession is used for this
		     option, hence the +mksession configure-option is required.
	   "hsplit"  man page will appear in a horizontally          split window (default)
	   "vsplit"  man page will appear in a vertically            split window
	   "hsplit=" man page will appear in a horizontally & evenly split window
	   "vsplit=" man page will appear in a vertically   & evenly split window
	   "reuse"   man page will re-use current window.  Use <ctrl-o> to return.
	             (for the reuse option, thanks go to Alan Schmitt)

				*g:manpageview_server* *g:manpgeview_user*

	g:manpageview_server : for WinNT; uses rsh to read manpage remotely
	g:manpageview_user   : use given server (host) and username
	  examples:
	            let g:manpageview_server= "somehostname"
	            let g:manpageview_user  = "username"

	*g:manpageview_init_EXT* *g:manpageview_K_EXT*   *g:manpageview_options_EXT*
	*g:manpageview_pfx_EXT*  *g:manpageview_pgm_EXT* *g:manpageview_sfx_EXT*
	*g:manpageview_syntax_EXT*
	g:manpageview_init_{ext}:			*manpageview_extend*
	g:manpageview_K_{ext}:
	g:manpageview_options_{ext}:
	g:manpageview_pfx_{ext}:
	g:manpageview_pgm_{ext}:
	g:manpageview_sfx_{ext}:
	g:manpageview_syntax_{ext}:

		With these options, one may specify an extension on a topic
		and have a special program and customized options for that
		program used instead of man itself.  As an example, consider
		perl: >

			let g:manpageview_pgm_pl = "perldoc"
			let g:manpageview_options= ";-f;-q"
<
		Note that, for perl, the options consist of a sequence of
		options to be tried, separated by semi-colons.

		The g:manpageview_init_{ext} specifies a function to be called
		for initialization.  The info handler, for example, uses this
		function to specify buffer-local maps.

		The g:manpageview_K_{ext} specifies a function to be invoked
		when the "K" key is tapped.  By default, it calls
		s:ManPageView().

		The g:manpageview_options_{ext} specifies what options are
		needed.

		The g:manpageview_pfx_{ext} specifies a prefix to prepend to
		the nominal manpage name.

		The g:manpageview_pgm_{ext} specifies which program to run for
		help.

		The g:manpageview_sfx_{ext} specifies a suffix to append to
		the nominal manpage name.  Without this last option, the
		provided suffix (ie. Man sprintf.pl 's  ".pl") will be elided.
		With this option, the g:manpageview_sfx_{ext} will be
		appended.

		The g:manpageview_syntax_{ext} specifies a highlighting file
		to be used for this particular extension type.

	You may map some key other than "K" to invoke ManPageView; as an
	example: >
		nmap V <Plug>ManPageView
<	Put this in your <.vimrc>.


==============================================================================
4. ManPageView History				*manpageview-history* {{{1

	Thanks go to the various people who have contributed changes,
	pointed out problems, and made suggestions!

	v24: Jan 03, 2011  * some extra protection against trying to use
			     a program that is not executable
	v23: May 18, 2009  * on the third attempt to get a manpage, if
	                     the user provided no explicit
			     |g:manpageview_iconv| setting, then the
			     an attempt is made with iconv off.
			   * Fixed K mapping for php, tex, etc.
			   * (in progress) KMan [ext] to set default
			     extension for the K map
	     Oct 21, 2010  * added python help via pydoc (suffix: .py)
	     Oct 25, 2010  * Version 23 released
	v22: Nov 10, 2008  * if g:manpageview_K_{ext} (ext is some
			     extension) exists, previously that would
			     be enough to institute a K map.  Now, if
			     that string is "", then the K map will not
			     be generated.
	     Nov 17, 2008  * handles non-existing manpage requests better
	v21: Sep 11, 2008  * when at a top node with info help, the up
			     directory shows as "(dir)".  A "u" issued a
			     warning and closes the window.  It now issues
			     a warning but leaves the window unchanged.
			   * improved shellescape() use
			   * new option: g:manpageview_multimanpage
	     Sep 27, 2008  * The K map now uses <cword> expansion except when
			     used inside a manpage (where it uses <cWORD>).
	v19: Jun 06, 2008  * uses the shellescape() function for better
			     security.  Thus vim 7.1 is required.
			   * when shellescape() isn't available, manpageview
			     will only issue a warning message when invoked
			     instead of every time vim is invoked.
			   * syntax/manphp.vim was using "set" instead of
			     "setlocal" and so new buffers were inadvertently
			     being prevented from being modifiable.
	     Aug 05, 2008  * fixed a problem with using K multiple times with
			     php files
	v18: Jun 06, 2008  * <PageUp> and <PageDown> support added to jump
			     between multiple man pages loaded into one buffer
			     such as may occur with :Man -a printf
			   * links -dump used instead of links for php
	v17: Apr 18, 2007  * changed the topic cleanup to use 'g' instead
	                     of '' in the substitute().
			   * Fixed bug with info pages - wasn't able to
			     use the > and < maps to go to pages named
			     with spaces.
			   * Included the g:manpageview_iconv option
	     Sep 07, 2007  * viewing window now is read-only and swapfile
	                     is turned off
	     Sep 07, 2007  * The "::" in some help pages (ex. File::stat)
			     was being parsed out, leaving only the left
			     hand side word.  Manpageview now accepts them.
	     Nov 12, 2007  * At the request of F. Mehner, with
			     g:manpageview_winopen is "reuse", manpageview
			     will re-use any man-page windows that are still
			     open.
			   * (F.Mehner) in "reuse" mode, a K on a blank
			     character terminated vim.  Fixed!
	     May 09, 2008  * Added <PageUp> and <PageDown> maps
	v16: Jun 28, 2006  * bypasses sxq with '"' for windows internally
	     Sep 26, 2006  * implemented <count>K to look up a topic
	                     under the cursor but in the <count>-th book
	     Nov 21, 2006  * removed s:mank related code; man -k being
	                     handled without it.
	     Dec 04, 2006  * added fdc=0 to manpageview settings bypass
	     Feb 21, 2007  * removed modifications to isk; instead,
	                     manpageview attempts to fix the topic and
			     uses expand("<cWORD>") instead:w
	v15: Jan 23, 2006  * works around nomagic option
	                   * works around cwh=1 to avoid Hit-Enter prompts
	     Feb 13, 2006  * the test for keywordprg was for "man"; now its
	                     for a regular expression "^man\>" (so its
	        	     immune to the use of options)
	     Apr 11, 2006  * HMan, OMan, VMan, Rman commands implemented
	     Jun 27, 2006  * escaped any spaces coming from tempname()
	v14: Nov 23, 2005  * "only" was occasionally issuing an "Already one
	                     window" message, which is now prevented
	     Nov 29, 2005  * Aaron Griffin found that setting gdefault
	        	     gave manpageview problems with ctrl-hs.  Fixed.
	     Dec 16, 2005  * Suresh Govindachar asked about letting
	                     manpageview also handle perldoc -q manpages.
	        	     IMHO this was getting cumbersome, so I extended
	        	     opt to allow a semi-colon separated "path" of
	        	     up to three options to try.
	     Dec 20, 2005  * In consultation with Gareth Oakes, manpageview
	                     needed some quoting and backslash-fixes to work
	        	     properly with windows and perldoc.
	     Dec 29, 2005  * added links-based help for php functions

	v13: Jul 19, 2005  * included niebie's changes to manpageview -
	                     <bs>, <del> to scroll one page up,
	        	     <tab> to go to the next hyperlink
	        	     d     to go to the top-level directory
	        	     and some bugfixes ([] to \[ \], and redirecting
	        	     stderr to /dev/null by default)
	     Aug 17, 2005  * report option workaround
	     Sep 26, 2005  * :Man -k  now uses "man -k" to generate a keyword
	                     listing
	        	   * included syntax/man.vim and syntax/mankey.vim
	v12: Jul 11, 2005  unmap K was causing "noise" when it was first
			   used.  Fixed.
	v11: * K now <buffer>-mapped to call ManPageView()
	v10: * support for perl/perldoc:
	      g:manpageview_{ pgm | options | sfx }_{ extension }
	    * support for info: g:manpageview_{ K | pfx | syntax }
	    * configuration option drilling -- if you're in a
	      *.conf file, pressing "K" atop an option will go
	      to the associated help page and option, if there's
	      help for that configuration file
	v9: * for vim versions >= 6.3, keepjumps is used to reduce the
	      impact on the jumplist
	    * manpageview now turns off linewrap for the manpage, since
	      re-formatting doesn't seem to work usually.
	    * apparently some systems resize the [g]vim display when
	      any filter is used, including manpageview's :r!... .
	      Setting g:manpageview_dispresize=1 will force retention
	      of display size.
	    * before mapping K to use manpageview, a check that
	      keywordprg is "man" is also made. (tnx to Suresh Govindachar)
	v8: * apparently bh=wipe is "new", so I've put a version
	      test around that setting to allow older vim's to avoid
	      an error message
	    * manpageview now turns numbering off in the manpage buffer (nonu)
	v7: * when a manpageview window is exit'd, it will be wiped out
	      so that it doesn't clutter the buffer list
	    * when g:manpageview_winopen was "reuse", the manpage would
	      reuse the window, even when it wasn't a manpage window.
	      Manpageview will now use hsplit if the window was marked
	      "modified"; otherwise, the associated buffer will be marked
	      as "hidden" (so that its still available via the buffer list)
	v6: * Erik Remmelzwal provided a fix to the g:manpageview_server
	      support for NT
	    * implemented Erik's suggestion to re-use manpage windows
	    * Nathan Huizinga pointed out, <cWORD> was picking up too much for
	      the K map. <cword> is now used
	    * Denilson F de Sa suggested that the man-page window be set as
	      readonly and nonmodifiable

	v5: includes g:manpageview_winmethod option (only, hsplit, vsplit)

	v4: Erik Remmelzwaal suggested including, for the benefit of NT users,
	    a command to use rsh to read the manpage remotely.  Set
	    g:manpageview_server to hostname  (in your <.vimrc>)
	    g:manpageview_user   to username

	v3: * ignores (...) if it contains commas or double quotes.  elides
	      any commas, colons, and semi-colons at end

	    * g:manpageview_options supported

	v2: saves current session prior to invoking man pages :Man    will
	    restore session.  Requires +mksession for this new command to
	    work.

	v1: the epoch

==============================================================================
vim:tw=78:ts=8:ft=help:fdm=marker
plugin/cecutil.vim	[[[1
536
" cecutil.vim : save/restore window position
"               save/restore mark position
"               save/restore selected user maps
"  Author:	Charles E. Campbell, Jr.
"  Version:	18h	ASTRO-ONLY
"  Date:	Apr 05, 2010
"
"  Saving Restoring Destroying Marks: {{{1
"       call SaveMark(markname)       let savemark= SaveMark(markname)
"       call RestoreMark(markname)    call RestoreMark(savemark)
"       call DestroyMark(markname)
"       commands: SM RM DM
"
"  Saving Restoring Destroying Window Position: {{{1
"       call SaveWinPosn()        let winposn= SaveWinPosn()
"       call RestoreWinPosn()     call RestoreWinPosn(winposn)
"		\swp : save current window/buffer's position
"		\rwp : restore current window/buffer's previous position
"       commands: SWP RWP
"
"  Saving And Restoring User Maps: {{{1
"       call SaveUserMaps(mapmode,maplead,mapchx,suffix)
"       call RestoreUserMaps(suffix)
"
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim
"
" You believe that God is one. You do well. The demons also {{{1
" believe, and shudder. But do you want to know, vain man, that
" faith apart from works is dead?  (James 2:19,20 WEB)
"redraw!|call inputsave()|call input("Press <cr> to continue")|call inputrestore()

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_cecutil")
 finish
endif
let g:loaded_cecutil = "v18h"
let s:keepcpo        = &cpo
set cpo&vim
"DechoRemOn

" =======================
"  Public Interface: {{{1
" =======================

" ---------------------------------------------------------------------
"  Map Interface: {{{2
if !hasmapto('<Plug>SaveWinPosn')
 map <unique> <Leader>swp <Plug>SaveWinPosn
endif
if !hasmapto('<Plug>RestoreWinPosn')
 map <unique> <Leader>rwp <Plug>RestoreWinPosn
endif
nmap <silent> <Plug>SaveWinPosn		:call SaveWinPosn()<CR>
nmap <silent> <Plug>RestoreWinPosn	:call RestoreWinPosn()<CR>

" ---------------------------------------------------------------------
" Command Interface: {{{2
com! -bar -nargs=0 SWP	call SaveWinPosn()
com! -bar -nargs=? RWP	call RestoreWinPosn(<args>)
com! -bar -nargs=1 SM	call SaveMark(<q-args>)
com! -bar -nargs=1 RM	call RestoreMark(<q-args>)
com! -bar -nargs=1 DM	call DestroyMark(<q-args>)

com! -bar -nargs=1 WLR	call s:WinLineRestore(<q-args>)

if v:version < 630
 let s:modifier= "sil! "
else
 let s:modifier= "sil! keepj "
endif

" ===============
" Functions: {{{1
" ===============

" ---------------------------------------------------------------------
" SaveWinPosn: {{{2
"    let winposn= SaveWinPosn()  will save window position in winposn variable
"    call SaveWinPosn()          will save window position in b:cecutil_winposn{b:cecutil_iwinposn}
"    let winposn= SaveWinPosn(0) will *only* save window position in winposn variable (no stacking done)
fun! SaveWinPosn(...)
"  echomsg "Decho: SaveWinPosn() a:0=".a:0
  if line("$") == 1 && getline(1) == ""
"   echomsg "Decho: SaveWinPosn : empty buffer"
   return ""
  endif
  let so_keep   = &l:so
  let siso_keep = &siso
  let ss_keep   = &l:ss
  setlocal so=0 siso=0 ss=0

  let swline = line(".")                           " save-window line in file
  let swcol  = col(".")                            " save-window column in file
  if swcol >= col("$")
   let swcol= swcol + virtcol(".") - virtcol("$")  " adjust for virtual edit (cursor past end-of-line)
  endif
  let swwline   = winline() - 1                    " save-window window line
  let swwcol    = virtcol(".") - wincol()          " save-window window column
  let savedposn = ""
"  echomsg "Decho: sw[".swline.",".swcol."] sww[".swwline.",".swwcol."]"
  let savedposn = "call GoWinbufnr(".winbufnr(0).")"
  let savedposn = savedposn."|".s:modifier.swline
  let savedposn = savedposn."|".s:modifier."norm! 0z\<cr>"
  if swwline > 0
   let savedposn= savedposn.":".s:modifier."call s:WinLineRestore(".(swwline+1).")\<cr>"
  endif
  if swwcol > 0
   let savedposn= savedposn.":".s:modifier."norm! 0".swwcol."zl\<cr>"
  endif
  let savedposn = savedposn.":".s:modifier."call cursor(".swline.",".swcol.")\<cr>"

  " save window position in
  " b:cecutil_winposn_{iwinposn} (stack)
  " only when SaveWinPosn() is used
  if a:0 == 0
   if !exists("b:cecutil_iwinposn")
	let b:cecutil_iwinposn= 1
   else
	let b:cecutil_iwinposn= b:cecutil_iwinposn + 1
   endif
"   echomsg "Decho: saving posn to SWP stack"
   let b:cecutil_winposn{b:cecutil_iwinposn}= savedposn
  endif

  let &l:so = so_keep
  let &siso = siso_keep
  let &l:ss = ss_keep

"  if exists("b:cecutil_iwinposn")                                                                  " Decho
"   echomsg "Decho: b:cecutil_winpos{".b:cecutil_iwinposn."}[".b:cecutil_winposn{b:cecutil_iwinposn}."]"
"  else                                                                                             " Decho
"   echomsg "Decho: b:cecutil_iwinposn doesn't exist"
"  endif                                                                                            " Decho
"  echomsg "Decho: SaveWinPosn [".savedposn."]"
  return savedposn
endfun

" ---------------------------------------------------------------------
" RestoreWinPosn: {{{2
"      call RestoreWinPosn()
"      call RestoreWinPosn(winposn)
fun! RestoreWinPosn(...)
"  echomsg "Decho: RestoreWinPosn() a:0=".a:0
"  echomsg "Decho: getline(1)<".getline(1).">"
"  echomsg "Decho: line(.)=".line(".")
  if line("$") == 1 && getline(1) == ""
"   echomsg "Decho: RestoreWinPosn : empty buffer"
   return ""
  endif
  let so_keep   = &l:so
  let siso_keep = &l:siso
  let ss_keep   = &l:ss
  setlocal so=0 siso=0 ss=0

  if a:0 == 0 || a:1 == ""
   " use saved window position in b:cecutil_winposn{b:cecutil_iwinposn} if it exists
   if exists("b:cecutil_iwinposn") && exists("b:cecutil_winposn{b:cecutil_iwinposn}")
"    echomsg "Decho: using stack b:cecutil_winposn{".b:cecutil_iwinposn."}<".b:cecutil_winposn{b:cecutil_iwinposn}.">"
	try
	 exe s:modifier.b:cecutil_winposn{b:cecutil_iwinposn}
	catch /^Vim\%((\a\+)\)\=:E749/
	 " ignore empty buffer error messages
	endtry
	" normally drop top-of-stack by one
	" but while new top-of-stack doesn't exist
	" drop top-of-stack index by one again
	if b:cecutil_iwinposn >= 1
	 unlet b:cecutil_winposn{b:cecutil_iwinposn}
	 let b:cecutil_iwinposn= b:cecutil_iwinposn - 1
	 while b:cecutil_iwinposn >= 1 && !exists("b:cecutil_winposn{b:cecutil_iwinposn}")
	  let b:cecutil_iwinposn= b:cecutil_iwinposn - 1
	 endwhile
	 if b:cecutil_iwinposn < 1
	  unlet b:cecutil_iwinposn
	 endif
	endif
   else
	echohl WarningMsg
	echomsg "***warning*** need to SaveWinPosn first!"
	echohl None
   endif

  else	 " handle input argument
"   echomsg "Decho: using input a:1<".a:1.">"
   " use window position passed to this function
   exe a:1
   " remove a:1 pattern from b:cecutil_winposn{b:cecutil_iwinposn} stack
   if exists("b:cecutil_iwinposn")
	let jwinposn= b:cecutil_iwinposn
	while jwinposn >= 1                     " search for a:1 in iwinposn..1
	 if exists("b:cecutil_winposn{jwinposn}")    " if it exists
	  if a:1 == b:cecutil_winposn{jwinposn}      " and the pattern matches
	   unlet b:cecutil_winposn{jwinposn}            " unlet it
	   if jwinposn == b:cecutil_iwinposn            " if at top-of-stack
		let b:cecutil_iwinposn= b:cecutil_iwinposn - 1      " drop stacktop by one
	   endif
	  endif
	 endif
	 let jwinposn= jwinposn - 1
	endwhile
   endif
  endif

  " Seems to be something odd: vertical motions after RWP
  " cause jump to first column.  The following fixes that.
  " Note: was using wincol()>1, but with signs, a cursor
  " at column 1 yields wincol()==3.  Beeping ensued.
  let vekeep= &ve
  set ve=all
  if virtcol('.') > 1
   exe s:modifier."norm! hl"
  elseif virtcol(".") < virtcol("$")
   exe s:modifier."norm! lh"
  endif
  let &ve= vekeep

  let &l:so   = so_keep
  let &l:siso = siso_keep
  let &l:ss   = ss_keep

"  echomsg "Decho: RestoreWinPosn"
endfun

" ---------------------------------------------------------------------
" s:WinLineRestore: {{{2
fun! s:WinLineRestore(swwline)
"  echomsg "Decho: s:WinLineRestore(swwline=".a:swwline.")"
  while winline() < a:swwline
   let curwinline= winline()
   exe s:modifier."norm! \<c-y>"
   if curwinline == winline()
	break
   endif
  endwhile
"  echomsg "Decho: s:WinLineRestore"
endfun

" ---------------------------------------------------------------------
" GoWinbufnr: go to window holding given buffer (by number) {{{2
"   Prefers current window; if its buffer number doesn't match,
"   then will try from topleft to bottom right
fun! GoWinbufnr(bufnum)
"  call Dfunc("GoWinbufnr(".a:bufnum.")")
  if winbufnr(0) == a:bufnum
"   call Dret("GoWinbufnr : winbufnr(0)==a:bufnum")
   return
  endif
  winc t
  let first=1
  while winbufnr(0) != a:bufnum && (first || winnr() != 1)
  	winc w
	let first= 0
   endwhile
"  call Dret("GoWinbufnr")
endfun

" ---------------------------------------------------------------------
" SaveMark: sets up a string saving a mark position. {{{2
"           For example, SaveMark("a")
"           Also sets up a global variable, g:savemark_{markname}
fun! SaveMark(markname)
"  call Dfunc("SaveMark(markname<".a:markname.">)")
  let markname= a:markname
  if strpart(markname,0,1) !~ '\a'
   let markname= strpart(markname,1,1)
  endif
"  call Decho("markname=".markname)

  let lzkeep  = &lz
  set lz

  if 1 <= line("'".markname) && line("'".markname) <= line("$")
   let winposn               = SaveWinPosn(0)
   exe s:modifier."norm! `".markname
   let savemark              = SaveWinPosn(0)
   let g:savemark_{markname} = savemark
   let savemark              = markname.savemark
   call RestoreWinPosn(winposn)
  else
   let g:savemark_{markname} = ""
   let savemark              = ""
  endif

  let &lz= lzkeep

"  call Dret("SaveMark : savemark<".savemark.">")
  return savemark
endfun

" ---------------------------------------------------------------------
" RestoreMark: {{{2
"   call RestoreMark("a")  -or- call RestoreMark(savemark)
fun! RestoreMark(markname)
"  call Dfunc("RestoreMark(markname<".a:markname.">)")

  if strlen(a:markname) <= 0
"   call Dret("RestoreMark : no such mark")
   return
  endif
  let markname= strpart(a:markname,0,1)
  if markname !~ '\a'
   " handles 'a -> a styles
   let markname= strpart(a:markname,1,1)
  endif
"  call Decho("markname=".markname." strlen(a:markname)=".strlen(a:markname))

  let lzkeep  = &lz
  set lz
  let winposn = SaveWinPosn(0)

  if strlen(a:markname) <= 2
   if exists("g:savemark_{markname}") && strlen(g:savemark_{markname}) != 0
	" use global variable g:savemark_{markname}
"	call Decho("use savemark list")
	call RestoreWinPosn(g:savemark_{markname})
	exe "norm! m".markname
   endif
  else
   " markname is a savemark command (string)
"	call Decho("use savemark command")
   let markcmd= strpart(a:markname,1)
   call RestoreWinPosn(markcmd)
   exe "norm! m".markname
  endif

  call RestoreWinPosn(winposn)
  let &lz       = lzkeep

"  call Dret("RestoreMark")
endfun

" ---------------------------------------------------------------------
" DestroyMark: {{{2
"   call DestroyMark("a")  -- destroys mark
fun! DestroyMark(markname)
"  call Dfunc("DestroyMark(markname<".a:markname.">)")

  " save options and set to standard values
  let reportkeep= &report
  let lzkeep    = &lz
  set lz report=10000

  let markname= strpart(a:markname,0,1)
  if markname !~ '\a'
   " handles 'a -> a styles
   let markname= strpart(a:markname,1,1)
  endif
"  call Decho("markname=".markname)

  let curmod  = &mod
  let winposn = SaveWinPosn(0)
  1
  let lineone = getline(".")
  exe "k".markname
  d
  put! =lineone
  let &mod    = curmod
  call RestoreWinPosn(winposn)

  " restore options to user settings
  let &report = reportkeep
  let &lz     = lzkeep

"  call Dret("DestroyMark")
endfun

" ---------------------------------------------------------------------
" QArgSplitter: to avoid \ processing by <f-args>, <q-args> is needed. {{{2
" However, <q-args> doesn't split at all, so this one returns a list
" with splits at all whitespace (only!), plus a leading length-of-list.
" The resulting list:  qarglist[0] corresponds to a:0
"                      qarglist[i] corresponds to a:{i}
fun! QArgSplitter(qarg)
"  call Dfunc("QArgSplitter(qarg<".a:qarg.">)")
  let qarglist    = split(a:qarg)
  let qarglistlen = len(qarglist)
  let qarglist    = insert(qarglist,qarglistlen)
"  call Dret("QArgSplitter ".string(qarglist))
  return qarglist
endfun

" ---------------------------------------------------------------------
" ListWinPosn: {{{2
"fun! ListWinPosn()                                                        " Decho 
"  if !exists("b:cecutil_iwinposn") || b:cecutil_iwinposn == 0             " Decho 
"   call Decho("nothing on SWP stack")                                     " Decho
"  else                                                                    " Decho
"   let jwinposn= b:cecutil_iwinposn                                       " Decho 
"   while jwinposn >= 1                                                    " Decho 
"    if exists("b:cecutil_winposn{jwinposn}")                              " Decho 
"     call Decho("winposn{".jwinposn."}<".b:cecutil_winposn{jwinposn}.">") " Decho 
"    else                                                                  " Decho 
"     call Decho("winposn{".jwinposn."} -- doesn't exist")                 " Decho 
"    endif                                                                 " Decho 
"    let jwinposn= jwinposn - 1                                            " Decho 
"   endwhile                                                               " Decho 
"  endif                                                                   " Decho
"endfun                                                                    " Decho 
"com! -nargs=0 LWP	call ListWinPosn()                                    " Decho 

" ---------------------------------------------------------------------
" SaveUserMaps: this function sets up a script-variable (s:restoremap) {{{2
"          which can be used to restore user maps later with
"          call RestoreUserMaps()
"
"          mapmode - see :help maparg for details (n v o i c l "")
"                    ex. "n" = Normal
"                    The letters "b" and "u" are optional prefixes;
"                    The "u" means that the map will also be unmapped
"                    The "b" means that the map has a <buffer> qualifier
"                    ex. "un"  = Normal + unmapping
"                    ex. "bn"  = Normal + <buffer>
"                    ex. "bun" = Normal + <buffer> + unmapping
"                    ex. "ubn" = Normal + <buffer> + unmapping
"          maplead - see mapchx
"          mapchx  - "<something>" handled as a single map item.
"                    ex. "<left>"
"                  - "string" a string of single letters which are actually
"                    multiple two-letter maps (using the maplead:
"                    maplead . each_character_in_string)
"                    ex. maplead="\" and mapchx="abc" saves user mappings for
"                        \a, \b, and \c
"                    Of course, if maplead is "", then for mapchx="abc",
"                    mappings for a, b, and c are saved.
"                  - :something  handled as a single map item, w/o the ":"
"                    ex.  mapchx= ":abc" will save a mapping for "abc"
"          suffix  - a string unique to your plugin
"                    ex.  suffix= "DrawIt"
fun! SaveUserMaps(mapmode,maplead,mapchx,suffix)
"  call Dfunc("SaveUserMaps(mapmode<".a:mapmode."> maplead<".a:maplead."> mapchx<".a:mapchx."> suffix<".a:suffix.">)")

  if !exists("s:restoremap_{a:suffix}")
   " initialize restoremap_suffix to null string
   let s:restoremap_{a:suffix}= ""
  endif

  " set up dounmap: if 1, then save and unmap  (a:mapmode leads with a "u")
  "                 if 0, save only
  let mapmode  = a:mapmode
  let dounmap  = 0
  let dobuffer = ""
  while mapmode =~ '^[bu]'
   if     mapmode =~ '^u'
    let dounmap = 1
    let mapmode = strpart(a:mapmode,1)
   elseif mapmode =~ '^b'
    let dobuffer = "<buffer> "
    let mapmode  = strpart(a:mapmode,1)
   endif
  endwhile
"  call Decho("dounmap=".dounmap."  dobuffer<".dobuffer.">")
 
  " save single map :...something...
  if strpart(a:mapchx,0,1) == ':'
"   call Decho("save single map :...something...")
   let amap= strpart(a:mapchx,1)
   if amap == "|" || amap == "\<c-v>"
    let amap= "\<c-v>".amap
   endif
   let amap                    = a:maplead.amap
   let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|:silent! ".mapmode."unmap ".dobuffer.amap
   if maparg(amap,mapmode) != ""
    let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|:".mapmode."map ".dobuffer.amap." ".maprhs
   endif
   if dounmap
	exe "silent! ".mapmode."unmap ".dobuffer.amap
   endif
 
  " save single map <something>
  elseif strpart(a:mapchx,0,1) == '<'
"   call Decho("save single map <something>")
   let amap       = a:mapchx
   if amap == "|" || amap == "\<c-v>"
    let amap= "\<c-v>".amap
"	call Decho("amap[[".amap."]]")
   endif
   let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|silent! ".mapmode."unmap ".dobuffer.amap
   if maparg(a:mapchx,mapmode) != ""
    let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|".mapmode."map ".dobuffer.amap." ".maprhs
   endif
   if dounmap
	exe "silent! ".mapmode."unmap ".dobuffer.amap
   endif
 
  " save multiple maps
  else
"   call Decho("save multiple maps")
   let i= 1
   while i <= strlen(a:mapchx)
    let amap= a:maplead.strpart(a:mapchx,i-1,1)
	if amap == "|" || amap == "\<c-v>"
	 let amap= "\<c-v>".amap
	endif
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|silent! ".mapmode."unmap ".dobuffer.amap
    if maparg(amap,mapmode) != ""
     let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	 let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|".mapmode."map ".dobuffer.amap." ".maprhs
    endif
	if dounmap
	 exe "silent! ".mapmode."unmap ".dobuffer.amap
	endif
    let i= i + 1
   endwhile
  endif
"  call Dret("SaveUserMaps : restoremap_".a:suffix.": ".s:restoremap_{a:suffix})
endfun

" ---------------------------------------------------------------------
" RestoreUserMaps: {{{2
"   Used to restore user maps saved by SaveUserMaps()
fun! RestoreUserMaps(suffix)
"  call Dfunc("RestoreUserMaps(suffix<".a:suffix.">)")
  if exists("s:restoremap_{a:suffix}")
   let s:restoremap_{a:suffix}= substitute(s:restoremap_{a:suffix},'|\s*$','','e')
   if s:restoremap_{a:suffix} != ""
"   	call Decho("exe ".s:restoremap_{a:suffix})
    exe "silent! ".s:restoremap_{a:suffix}
   endif
   unlet s:restoremap_{a:suffix}
  endif
"  call Dret("RestoreUserMaps")
endfun

" ==============
"  Restore: {{{1
" ==============
let &cpo= s:keepcpo
unlet s:keepcpo

" ================
"  Modelines: {{{1
" ================
" vim: ts=4 fdm=marker
