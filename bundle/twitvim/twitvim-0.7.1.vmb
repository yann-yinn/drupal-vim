" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/twitvim.vim	[[[1
5148
" ==============================================================
" TwitVim - Post to Twitter from Vim
" Based on Twitter Vim script by Travis Jeffery <eatsleepgolf@gmail.com>
"
" Version: 0.7.1
" License: Vim license. See :help license
" Language: Vim script
" Maintainer: Po Shan Cheah <morton@mortonfox.com>
" Created: March 28, 2008
" Last updated: September 21, 2011
"
" GetLatestVimScripts: 2204 1 twitvim.vim
" ==============================================================

" Load this module only once.
if exists('loaded_twitvim')
    finish
endif
let loaded_twitvim = 1

" Avoid side-effects from cpoptions setting.
let s:save_cpo = &cpo
set cpo&vim

" User agent header string.
let s:user_agent = 'TwitVim 0.7.1 2011-09-21'

" Twitter character limit. Twitter used to accept tweets up to 246 characters
" in length and display those in truncated form, but that is no longer the
" case. So 140 is now the hard limit.
let s:char_limit = 140

" Allow the user to override the API root, e.g. for identi.ca, which offers a
" Twitter-compatible API.
function! s:get_api_root()
    return exists('g:twitvim_api_root') ? g:twitvim_api_root : "http://api.twitter.com/1"
endfunction

" Allow user to set the format for retweets.
function! s:get_retweet_fmt()
    return exists('g:twitvim_retweet_format') ? g:twitvim_retweet_format : "RT %s: %t"
endfunction

" Allow user to enable Python networking code by setting twitvim_enable_python.
function! s:get_enable_python()
    return exists('g:twitvim_enable_python') ? g:twitvim_enable_python : 0
endfunction

" Allow user to enable Perl networking code by setting twitvim_enable_perl.
function! s:get_enable_perl()
    return exists('g:twitvim_enable_perl') ? g:twitvim_enable_perl : 0
endfunction

" Allow user to enable Ruby code by setting twitvim_enable_ruby.
function! s:get_enable_ruby()
    return exists('g:twitvim_enable_ruby') ? g:twitvim_enable_ruby : 0
endfunction

" Allow user to enable Tcl code by setting twitvim_enable_tcl.
function! s:get_enable_tcl()
    return exists('g:twitvim_enable_tcl') ? g:twitvim_enable_tcl : 0
endfunction

" Get proxy setting from twitvim_proxy in .vimrc or _vimrc.
" Format is proxysite:proxyport
function! s:get_proxy()
    return exists('g:twitvim_proxy') ? g:twitvim_proxy : ''
endfunction

" If twitvim_proxy_login exists, use that as the proxy login.
" Format is proxyuser:proxypassword
" If twitvim_proxy_login_b64 exists, use that instead. This is the proxy
" user:password in base64 encoding.
function! s:get_proxy_login()
    if exists('g:twitvim_proxy_login_b64') && g:twitvim_proxy_login_b64 != ''
	return g:twitvim_proxy_login_b64
    else
	return exists('g:twitvim_proxy_login') ? g:twitvim_proxy_login : ''
    endif
endfunction

" Get twitvim_count, if it exists. This will be the number of tweets returned
" by :FriendsTwitter, :UserTwitter, and :SearchTwitter.
function! s:get_count()
    if exists('g:twitvim_count')
	if g:twitvim_count < 1
	    return 1
	elseif g:twitvim_count > 200
	    return 200
	else
	    return g:twitvim_count
	endif
    endif
    return 0
endfunction

" User setting to show/hide header in the buffer. Default: show header.
function! s:get_show_header()
    return exists('g:twitvim_show_header') ? g:twitvim_show_header : 1
endfunction

" User config for name of OAuth access token file.
function! s:get_token_file()
    return exists('g:twitvim_token_file') ? g:twitvim_token_file : $HOME . "/.twitvim.token"
endfunction

" User config to disable the OAuth access token file.
function! s:get_disable_token_file()
    return exists('g:twitvim_disable_token_file') ? g:twitvim_disable_token_file : 0
endfunction

" User config to enable the filter.
function! s:get_filter_enable()
    return exists('g:twitvim_filter_enable') ? g:twitvim_filter_enable : 0
endfunction

" User config for filter.
function! s:get_filter_regex()
    return exists('g:twitvim_filter_regex') ? g:twitvim_filter_regex : ''
endfunction

" User config for Trends WOEID.
" Default to 1 for worldwide.
function! s:get_twitvim_woeid()
    return exists('g:twitvim_woeid') ? g:twitvim_woeid : 1
endfunction


" Display an error message in the message area.
function! s:errormsg(msg)
    redraw
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

" Display a warning message in the message area.
function! s:warnmsg(msg)
    redraw
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

" Get Twitter login info from twitvim_login in vimrc.
" Format is username:password
" If twitvim_login_b64 exists, use that instead. This is the user:password
" in base64 encoding.
"
" This function is for services with Twitter-compatible APIs that use Basic
" authentication, e.g. identi.ca
function! s:get_twitvim_login_noerror()
    if exists('g:twitvim_login_b64') && g:twitvim_login_b64 != ''
	return g:twitvim_login_b64
    elseif exists('g:twitvim_login') && g:twitvim_login != ''
	return g:twitvim_login
    else
	return ''
    endif
endfunction

" Dummy login string to force OAuth signing in run_curl_oauth().
let s:ologin = "oauth:oauth"

" Throw away saved login tokens and reset login info.
function! s:reset_twitvim_login()
    let s:access_token = ""
    let s:access_token_secret = ""
    let s:tokens = {}
    call delete(s:get_token_file())

    let s:cached_username = ""
endfunction

" Verify user credentials. This function is actually used to do an OAuth
" handshake after deleting the access token.
"
" Returns 1 if login succeeded, 0 if login failed, <0 for other errors.
function! s:check_twitvim_login()
    redraw
    echo "Logging into Twitter..."

    let url = s:get_api_root()."/account/verify_credentials.xml"
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error =~ '401'
	return 0
    endif

    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error logging into Twitter: ".(errormsg != '' ? errormsg : error))
	return -1
    endif

    " The following check should not be required because Twitter is supposed to
    " return a 401 HTTP status on login failure, but you never know with
    " Twitter.
    let error = s:xml_get_element(output, 'error')
    if error =~ '\ccould not authenticate'
	return 0
    endif

    if error != ''
	call s:errormsg("Error logging into Twitter: ".error)
	return -1
    endif

    redraw
    echo "Twitter login succeeded."

    return 1
endfunction

" Log in to a Twitter account.
function! s:prompt_twitvim_login()
    call s:do_login()
endfunction

" Switch to a different Twitter user.
function! s:switch_twitvim_login(user)
    let user = a:user
    if user == ''
	let namelist = s:list_tokens()
	if namelist == []
	    call s:errormsg('No logins to switch to. Use :SetLoginTwitter to log in.')
	    return
	endif

	let menu = []
	call add(menu, 'Choose a login to switch to:')
	let namecount = 0
	for name in namelist
	    let namecount += 1
	    call add(menu, namecount.'. '.name)
	endfor

	call inputsave()
	let input = inputlist(menu)
	call inputrestore()
	if input < 1 || input > len(namelist)
	    " Invalid input cancels the command.
	    return
	endif

	let user = namelist[input - 1]
    endif
    call s:switch_token(user)
    call s:write_tokens(s:cached_username)
endfunction

let s:cached_login = ''
let s:cached_username = ''

" See if we can save time by using the cached username.
function! s:get_twitvim_cached_username()
    if s:get_api_root() =~ 'twitter\.com'
	if s:cached_username == ''
	    return ''
	endif
    else
	" In Twitter-compatible services that use Basic authentication, the
	" user may have changed the login info on the fly. So we have to watch
	" out for that.
	let login = s:get_twitvim_login_noerror()
	if login == '' || login != s:cached_login
	    return ''
	endif
    endif
    return s:cached_username
endfunction

" Get Twitter user name by verifying login credentials
function! s:get_twitvim_username()
    " If we already have the info, no need to get it again.
    let username = s:get_twitvim_cached_username()
    if username != ''
	return username
    endif

    redraw
    echo "Verifying login credentials with Twitter..."

    let url = s:get_api_root()."/account/verify_credentials.xml"
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error verifying login credentials: ".(errormsg != '' ? errormsg : error))
	return ''
    endif

    redraw
    echo "Twitter login credentials verified."

    let username = s:xml_get_element(output, 'screen_name')

    " Save it so we don't have to do it again unless the user switches to
    " a different login.
    let s:cached_username = username
    let s:cached_login = s:get_twitvim_login_noerror()

    return username
endfunction

" If set, twitvim_cert_insecure turns off certificate verification if using
" https Twitter API over cURL or Ruby.
function! s:get_twitvim_cert_insecure()
    return exists('g:twitvim_cert_insecure') ? g:twitvim_cert_insecure : 0
endfunction

" === JSON parser ===

function! s:parse_json(str)
    try
	let true = 1
	let false = 0
	let null = ''
	sandbox let result = eval(a:str)
	return result
    catch
	call s:errormsg('JSON parse error: '.v:exception)
	return {}
    endtry
endfunction

" === XML helper functions ===

" Get the content of the n'th element in a series of elements.
function! s:xml_get_nth(xmlstr, elem, n)
    let matchres = matchlist(a:xmlstr, '<'.a:elem.'\%( [^>]*\)\?>\(.\{-}\)</'.a:elem.'>', -1, a:n)
    return matchres == [] ? "" : matchres[1]
endfunction

" Get all elements in a series of elements.
function! s:xml_get_all(xmlstr, elem)
    let pat = '<'.a:elem.'\%( [^>]*\)\?>\(.\{-}\)</'.a:elem.'>'
    let matches = []
    let pos = 0

    while 1
	let matchres = matchlist(a:xmlstr, pat, pos)
	if matchres == []
	    return matches
	endif
	call add(matches, matchres[1])
	let pos = matchend(a:xmlstr, pat, pos)
    endwhile
endfunction

" Get the content of the specified element.
function! s:xml_get_element(xmlstr, elem)
    return s:xml_get_nth(a:xmlstr, a:elem, 1)
endfunction

" Remove any number of the specified element from the string. Used for removing
" sub-elements so that you can parse the remaining elements safely.
function! s:xml_remove_elements(xmlstr, elem)
    return substitute(a:xmlstr, '<'.a:elem.'>.\{-}</'.a:elem.'>', '', "g")
endfunction

" Get the attributes of the n'th element in a series of elements.
function! s:xml_get_attr_nth(xmlstr, elem, n)
    let matchres = matchlist(a:xmlstr, '<'.a:elem.'\s\+\([^>]*\)>', -1, a:n)
    if matchres == []
	return {}
    endif

    let matchcount = 1
    let attrstr = matchres[1]
    let attrs = {}

    while 1
	let matchres = matchlist(attrstr, '\(\w\+\)="\([^"]*\)"', -1, matchcount)
	if matchres == []
	    break
	endif

	let attrs[matchres[1]] = matchres[2]
	let matchcount += 1
    endwhile

    return attrs
endfunction

" Get attributes of the specified element.
function! s:xml_get_attr(xmlstr, elem)
    return s:xml_get_attr_nth(a:xmlstr, a:elem, 1)
endfunction

" === End of XML helper functions ===

" === Time parser ===

" Convert date to Julian date.
function! s:julian(year, mon, mday)
    let month = (a:mon - 1 + 10) % 12
    let year = a:year - month / 10
    return a:mday + 365 * year + year / 4 - year / 100 + year / 400 + ((month * 306) + 5) / 10
endfunction

" Calculate number of days since UNIX Epoch.
function! s:daygm(year, mon, mday)
    return s:julian(a:year, a:mon, a:mday) - s:julian(1970, 1, 1)
endfunction

" Convert date/time to UNIX time. (seconds since Epoch)
function! s:timegm(year, mon, mday, hour, min, sec)
    return a:sec + a:min * 60 + a:hour * 60 * 60 + s:daygm(a:year, a:mon, a:mday) * 60 * 60 * 24
endfunction

" Convert abbreviated month name to month number.
function! s:conv_month(s)
    let monthnames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
    for mon in range(len(monthnames))
	if monthnames[mon] == tolower(a:s)
	    return mon + 1
	endif	
    endfor
    return 0
endfunction

function! s:timegm2(matchres, indxlist)
    let args = []
    for i in a:indxlist
	if i < 0
	    let mon = s:conv_month(a:matchres[-i])
	    if mon == 0
		return -1
	    endif
	    let args = add(args, mon)
	else
	    let args = add(args, a:matchres[i] + 0)
	endif
    endfor
    return call('s:timegm', args)
endfunction

" Parse a Twitter time string.
function! s:parse_time(str)
    " This timestamp format is used by Twitter in timelines.
    let matchres = matchlist(a:str, '^\w\+,\s\+\(\d\+\)\s\+\(\w\+\)\s\+\(\d\+\)\s\+\(\d\+\):\(\d\+\):\(\d\+\)\s\++0000$')
    if matchres != []
	return s:timegm2(matchres, [3, -2, 1, 4, 5, 6])
    endif

    " This timestamp format is used by Twitter in response to an update.
    let matchres = matchlist(a:str, '^\w\+\s\+\(\w\+\)\s\+\(\d\+\)\s\+\(\d\+\):\(\d\+\):\(\d\+\)\s\++0000\s\+\(\d\+\)$')
    if matchres != []
	return s:timegm2(matchres, [6, -1, 2, 3, 4, 5])
    endif
	
    " This timestamp format is used by Twitter Search.
    let matchres = matchlist(a:str, '^\(\d\+\)-\(\d\+\)-\(\d\+\)T\(\d\+\):\(\d\+\):\(\d\+\)Z$')
    if matchres != []
	return s:timegm2(matchres, range(1, 6))
    endif

    " This timestamp format is used by Twitter Rate Limit.
    let matchres = matchlist(a:str, '^\(\d\+\)-\(\d\+\)-\(\d\+\)T\(\d\+\):\(\d\+\):\(\d\+\)+00:00$')
    if matchres != []
	return s:timegm2(matchres, range(1, 6))
    endif

    return -1
endfunction

" Convert the Twitter timestamp to local time and simplify it.
function! s:time_filter(str)
    if !exists("*strftime")
	return a:str
    endif
    let t = s:parse_time(a:str)
    return t < 0 ? a:str : strftime('%I:%M %p %b %d, %Y', t)
endfunction

" === End of time parser ===

" === Token Management code ===

" Each token record holds the following fields:
"
" token: access token
" secret: access token secret
" name: screen name
" A lowercased copy of the screen name is the hash key.

let s:tokens = {}
let s:token_header = 'TwitVim 0.6'

function! s:find_token(name)
    return get(s:tokens, tolower(a:name), {})
endfunction

function! s:save_token(tokenrec)
    let tokenrec = a:tokenrec
    let s:tokens[tolower(tokenrec.name)] = tokenrec
endfunction

" Switch to another access token. Note that the token file should be written
" out again after this to reflect the new current user.
function! s:switch_token(name)
    let tokenrec = s:find_token(a:name)
    if tokenrec == {}
	call s:errormsg("Can't switch to user ".a:name.".")
    else
	let s:access_token = tokenrec.token
	let s:access_token_secret = tokenrec.secret
	let s:cached_username = tokenrec.name
	redraw
	echo "Logged in as ".s:cached_username."."
    endif
endfunction

" Returns a list of screen names. This is for prompting the user to pick a login
" to which to switch.
function! s:list_tokens()
    let names = []
    for tokenrec in values(s:tokens)
	" Need to use the names in the token records rather than keys(s:tokens)
	" in order to present screen names in original case instead of all
	" lowercase.
	call add(names, tokenrec.name)
    endfor
    return names
endfunction
    
" Returns a newline-delimited list of screen names. This is for command
" completion when switching logins.
function! s:name_list_tokens(ArgLead, CmdLine, CursorPos)
    return join(s:list_tokens(), "\n")
endfunction


" Write the token file.
function! s:write_tokens(current_user)
    if !s:get_disable_token_file()
	let tokenfile = s:get_token_file()

	let lines = []
	call add(lines, s:token_header)
	call add(lines, a:current_user)
	for tokenrec in values(s:tokens)
	    call add(lines, tokenrec.name)
	    call add(lines, tokenrec.token)
	    call add(lines, tokenrec.secret)
	endfor

	if writefile(lines, tokenfile) < 0
	    call s:errormsg('Error writing token file: '.v:errmsg)
	endif

	" Check and change file permissions for security.
	if has('unix')
	    let perms = getfperm(tokenfile)
	    if perms != '' && perms[-6:] != '------'
		silent! execute "!chmod go-rwx '".tokenfile."'"
	    endif
	endif
    endif
endfunction

" Read the token file.
function! s:read_tokens()
    let tokenfile = s:get_token_file()
    if !s:get_disable_token_file() && filereadable(tokenfile)
	let [hdr, current_user; tokens] = readfile(tokenfile, 't', 500)
	if tokens == []
	    " Legacy token file only has token and secret.
	    let s:access_token = hdr
	    let s:access_token_secret = current_user
	    let s:cached_username = ''

	    let user = s:get_twitvim_username()
	    if user == ''
		call s:errormsg('Invalid token in token file. Please relogin with :SetLoginTwitter.')
		return
	    endif

	    let tokenrec = {}
	    let tokenrec.token = s:access_token
	    let tokenrec.secret = s:access_token_secret
	    let tokenrec.name = user

	    call s:save_token(tokenrec)
	    call s:write_tokens(user)
	else
	    " New token file contains tokens, 3 lines per record.
	    for i in range(0, len(tokens) - 1, 3)
		let tokenrec = {}
		let tokenrec.name = tokens[i]
		let tokenrec.token = tokens[i + 1]
		let tokenrec.secret = tokens[i + 2]
		call s:save_token(tokenrec)
	    endfor
	    call s:switch_token(current_user)
	endif
    endif
endfunction


" === End of Token Management code ===

" === OAuth code ===

" Check if we can use Perl for HMAC-SHA1 digests.
function! s:check_perl_hmac()
    let can_perl = 1
    perl <<EOF
eval {
    require Digest::HMAC_SHA1;
    Digest::HMAC_SHA1->import;
};
if ($@) {
    VIM::DoCommand('let can_perl = 0');
}
EOF
    return can_perl
endfunction

" Compute HMAC-SHA1 digest. (Perl version)
function! s:perl_hmac_sha1_digest(key, str)
    perl <<EOF
require Digest::HMAC_SHA1;
Digest::HMAC_SHA1->import;

my $key = VIM::Eval('a:key');
my $str = VIM::Eval('a:str');

my $hmac = Digest::HMAC_SHA1->new($key);

$hmac->add($str);
my $signature = $hmac->b64digest; # Length of 27

VIM::DoCommand("let signature = '$signature'");
EOF

    return signature
endfunction

" Check if we can use Python for HMAC-SHA1 digests.
function! s:check_python_hmac()
    let can_python = 1
    python <<EOF
import vim
try:
    import base64
    import hashlib
    import hmac
except:
    vim.command('let can_python = 0')
EOF
    return can_python
endfunction

" Compute HMAC-SHA1 digest. (Python version)
function! s:python_hmac_sha1_digest(key, str)
    python <<EOF
import base64
import hashlib
import hmac
import vim

key = vim.eval("a:key")
mstr = vim.eval("a:str")

digest = hmac.new(key, mstr, hashlib.sha1).digest()
signature = base64.encodestring(digest)[0:-1]

vim.command("let signature='%s'" % signature)
EOF
    return signature
endfunction

" Check if we can use Ruby for HMAC-SHA1 digests.
function! s:check_ruby_hmac()
    let can_ruby = 1
    ruby <<EOF
begin
    require 'openssl'
    require 'base64'
rescue LoadError
    VIM.command('let can_ruby = 0')
end
EOF
    return can_ruby
endfunction

" Compute HMAC-SHA1 digest. (Ruby version)
function! s:ruby_hmac_sha1_digest(key, str)
    ruby <<EOF
require 'openssl'
require 'base64'

key = VIM.evaluate('a:key')
str = VIM.evaluate('a:str')

digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), key, str)
signature = Base64.encode64(digest).chomp

VIM.command("let signature='#{signature}'")
EOF
    return signature
endfunction

" Check if we can use Tcl for HMAC-SHA1 digests.
function! s:check_tcl_hmac()
    let can_tcl = 1
    tcl <<EOF
if [catch {
    package require sha1
    package require base64
} result] {
    ::vim::command "let can_tcl = 0"
}
EOF
    return can_tcl
endfunction

" Compute HMAC-SHA1 digest. (Tcl version)
function! s:tcl_hmac_sha1_digest(key, str)
    tcl <<EOF
package require sha1
package require base64

set key [::vim::expr a:key]
set str [::vim::expr a:str]

set signature [base64::encode [sha1::hmac -bin $key $str]]

::vim::command "let signature = '$signature'"
EOF
    return signature
endfunction

" Compute HMAC-SHA1 digest by running openssl command line utility.
function! s:openssl_hmac_sha1_digest(key, str)
    let output = system('openssl dgst -binary -sha1 -hmac "'.a:key.'" | openssl base64', a:str)
    if v:shell_error != 0
	call s:errormsg("Error running openssl command: ".output)
	return ""
    endif

    " Remove trailing newlines.
    let output = substitute(output, '\n\+$', '', '')

    return output
endfunction

" Find out which method we can use to compute a HMAC-SHA1 digest.
function! s:get_hmac_method()
    if !exists('s:hmac_method')
	let s:hmac_method = 'openssl'
	if s:get_enable_perl() && has('perl') && s:check_perl_hmac()
	    let s:hmac_method = 'perl'
	elseif s:get_enable_python() && has('python') && s:check_python_hmac()
	    let s:hmac_method = 'python'
	elseif s:get_enable_ruby() && has('ruby') && s:check_ruby_hmac()
	    let s:hmac_method = 'ruby'
	elseif s:get_enable_tcl() && has('tcl') && s:check_tcl_hmac()
	    let s:hmac_method = 'tcl'
	endif
    endif
    return s:hmac_method
endfunction

function! s:hmac_sha1_digest(key, str)
    return s:{s:get_hmac_method()}_hmac_sha1_digest(a:key, a:str)
endfunction

function! s:reset_hmac_method()
    unlet! s:hmac_method
endfunction

function! s:show_hmac_method()
    echo 'Hmac Method:' s:get_hmac_method()
endfunction

" For debugging. Reset Hmac method.
if !exists(":TwitVimResetHmacMethod")
    command TwitVimResetHmacMethod :call <SID>reset_hmac_method()
endif

" For debugging. Show current Hmac method.
if !exists(":TwitVimShowHmacMethod")
    command TwitVimShowHmacMethod :call <SID>show_hmac_method()
endif


let s:gc_consumer_key = "HyshEU8SbcsklPQ6ouF0g"
let s:gc_consumer_secret = "U1uvxLjZxlQAasy9Kr5L2YAFnsvYTOqx1bk7uJuezQ"

let s:gc_req_url = "http://api.twitter.com/oauth/request_token"
let s:gc_access_url = "http://api.twitter.com/oauth/access_token"
let s:gc_authorize_url = "https://api.twitter.com/oauth/authorize"

" Simple nonce value generator. This needs to be randomized better.
function! s:nonce()
    if !exists("s:nonce_val") || s:nonce_val < 1
	let s:nonce_val = localtime() + 109
    endif

    let retval = s:nonce_val
    let s:nonce_val += 109

    return retval
endfunction

" Split a URL into base and params.
function! s:split_url(url)
    let urlarray = split(a:url, '?')
    let baseurl = urlarray[0]
    let parms = {}
    if len(urlarray) > 1
	for pstr in split(urlarray[1], '&')
	    let [key, value] = split(pstr, '=')
	    let parms[key] = value
	endfor
    endif
    return [baseurl, parms]
endfunction

" Produce signed content using the parameters provided via parms using the
" chosen method, url and provided token secret. Note that in the case of
" getting a new Request token, the secret will be ""
function! s:getOauthResponse(url, method, parms, token_secret)
    let parms = copy(a:parms)

    " Add some constants to hash
    let parms["oauth_consumer_key"] = s:gc_consumer_key
    let parms["oauth_signature_method"] = "HMAC-SHA1"
    let parms["oauth_version"] = "1.0"

    " Get the timestamp and add to hash
    let parms["oauth_timestamp"] = localtime()

    let parms["oauth_nonce"] = s:nonce()

    let [baseurl, urlparms] = s:split_url(a:url)
    call extend(parms, urlparms)

    " Alphabetically sort by key and form a string that has
    " the format key1=value1&key2=value2&...
    " Must UTF8 encode and then URL encode the values.
    let content = ""

    for key in sort(keys(parms))
	let value = s:url_encode(parms[key])
	let content .= key . "=" . value . "&"
    endfor
    let content = content[0:-2]

    " Form the signature base string which is comprised of 3
    " pieces, with each piece URL encoded.
    " [METHOD_UPPER_CASE]&[url]&content
    let signature_base_str = a:method . "&" . s:url_encode(baseurl) . "&" . s:url_encode(content)
    let hmac_sha1_key = s:url_encode(s:gc_consumer_secret) . "&" . s:url_encode(a:token_secret)
    let signature = s:hmac_sha1_digest(hmac_sha1_key, signature_base_str)

    " Add padding character to make a multiple of 4 per the
    " requirement of OAuth.
    if strlen(signature) % 4
	let signature .= "="
    endif

    let content = "OAuth "

    for key in keys(parms)
	if key =~ "oauth"
	    let value = s:url_encode(parms[key])
	    let content .= key . '="' . value . '", '
	endif
    endfor
    let content .= 'oauth_signature="' . s:url_encode(signature) . '"'
    return content
endfunction

" Convert an OAuth endpoint to https if API root is https.
function! s:to_https(url)
    let url = a:url
    if s:get_api_root()[:5] == 'https:'
	if url[:4] == 'http:'
	    let url = 'https:'.url[5:]
	endif
    endif
    return url
endfunction

" Perform the OAuth dance to authorize this client with Twitter.
function! s:do_oauth()
    " Call oauth/request_token to get request token from Twitter.

    let parms = { "oauth_callback": "oob", "dummy" : "1" }
    let req_url = s:to_https(s:gc_req_url)
    let oauth_hdr = s:getOauthResponse(req_url, "POST", parms, "")

    let [error, output] = s:run_curl(req_url, oauth_hdr, s:get_proxy(), s:get_proxy_login(), { "dummy" : "1" })

    if error != ''
	call s:errormsg("Error from oauth/request_token: ".error)
	return [-1, '', '', '']
    endif

    let matchres = matchlist(output, 'oauth_token=\([^&]\+\)&')
    if matchres != []
	let request_token = matchres[1]
    endif

    let matchres = matchlist(output, 'oauth_token_secret=\([^&]\+\)&')
    if matchres != []
	let token_secret = matchres[1]
    endif

    " Launch web browser to let user allow or deny the authentication request.
    let auth_url = s:gc_authorize_url . "?oauth_token=" . request_token

    " If user has not set up twitvim_browser_cmd, just display the
    " authentication URL and ask the user to visit that URL.
    if !exists('g:twitvim_browser_cmd') || g:twitvim_browser_cmd == ''

	" Attempt to shorten the auth URL.
	let newurl = s:call_isgd(auth_url)
	if newurl != ""
	    let auth_url = newurl
	else
	    let newurl = s:call_bitly(auth_url)
	    if newurl != ""
		let auth_url = newurl
	    endif
	endif

	echo "Visit the following URL in your browser to authenticate TwitVim:"
	echo auth_url
    else
	if s:launch_browser(auth_url) < 0
	    return [-2, '', '', '']
	endif
    endif

    call inputsave()
    let pin = input("Enter Twitter OAuth PIN: ")
    call inputrestore()

    if pin == ""
	call s:warnmsg("No OAuth PIN entered")
	return [-3, '', '', '']
    endif

    " Call oauth/access_token to swap request token for access token.
    
    let parms = { "dummy" : 1, "oauth_token" : request_token, "oauth_verifier" : pin }
    let access_url = s:to_https(s:gc_access_url)
    let oauth_hdr = s:getOauthResponse(access_url, "POST", parms, token_secret)

    let [error, output] = s:run_curl(access_url, oauth_hdr, s:get_proxy(), s:get_proxy_login(), { "dummy" : 1 })

    if error != ''
	call s:errormsg("Error from oauth/access_token: ".error)
	return [-4, '', '', '']
    endif

    let matchres = matchlist(output, 'oauth_token=\([^&]\+\)&')
    if matchres != []
	let request_token = matchres[1]
    endif

    let matchres = matchlist(output, 'oauth_token_secret=\([^&]\+\)&')
    if matchres != []
	let token_secret = matchres[1]
    endif

    let matchres = matchlist(output, 'screen_name=\([^&]\+\)')
    if matchres != []
	let screen_name = matchres[1]
    endif

    return [ 0, request_token, token_secret, screen_name ]
endfunction

" Perform an OAuth login.
function! s:do_login()
    let [ retval, s:access_token, s:access_token_secret, s:cached_username ] = s:do_oauth()
    if retval < 0
	return [ -1, "Error from do_oauth(): ".retval ]
    endif

    let tokenrec = {}
    let tokenrec.token = s:access_token
    let tokenrec.secret = s:access_token_secret
    let tokenrec.name = s:cached_username
    call s:save_token(tokenrec)
    call s:write_tokens(s:cached_username)

    redraw
    echo "Logged in as ".s:cached_username."."

    return [ 0, '' ]
endfunction

" Sign a request with OAuth and send it.
function! s:run_curl_oauth(url, login, proxy, proxylogin, parms)
    if a:login != '' && a:url =~ 'twitter\.com'

	" Get access tokens from token file or do OAuth login.
	if !exists('s:access_token') || s:access_token == ''
	    call s:read_tokens()
	    if !exists('s:access_token') || s:access_token == ''
		let [ status, error ] = s:do_login()
		if status < 0
		    return [ error, '' ]
		endif
	    endif
	endif

	let parms = copy(a:parms)
	let parms["oauth_token"] = s:access_token
	let oauth_hdr = s:getOauthResponse(a:url, a:parms == {} ? 'GET' : 'POST', parms, s:access_token_secret)

	return s:run_curl(a:url, oauth_hdr, a:proxy, a:proxylogin, a:parms)
    else
	if a:login != ''
	    let login = s:get_twitvim_login_noerror()
	    if login == ''
		return [ 'Login info not set. Please add to vimrc: let twitvim_login="USER:PASS"', '' ]
	    endif
	else
	    let login = a:login
	endif
	return s:run_curl(a:url, login, a:proxy, a:proxylogin, a:parms)
    endif
endfunction

" === End of OAuth code ===

" === Networking code ===

function! s:url_encode_char(c)
    let utf = iconv(a:c, &encoding, "utf-8")
    if utf == ""
	let utf = a:c
    endif
    let s = ""
    for i in range(strlen(utf))
	let s .= printf("%%%02X", char2nr(utf[i]))
    endfor
    return s
endfunction

" URL-encode a string.
function! s:url_encode(str)
    return substitute(a:str, '[^a-zA-Z0-9_.~-]', '\=s:url_encode_char(submatch(0))', 'g')
endfunction

" Use curl to fetch a web page.
function! s:curl_curl(url, login, proxy, proxylogin, parms)
    let error = ""
    let output = ""

    let curlcmd = "curl -s -S "

    if s:get_twitvim_cert_insecure()
	let curlcmd .= "-k "
    endif

    if a:proxy != ""
	let curlcmd .= '-x "'.a:proxy.'" '
    endif

    if a:proxylogin != ""
	if stridx(a:proxylogin, ':') != -1
	    let curlcmd .= '-U "'.a:proxylogin.'" '
	else
	    let curlcmd .= '-H "Proxy-Authorization: Basic '.a:proxylogin.'" '
	endif
    endif

    if a:login != ""
	if a:login =~ "^OAuth "
	    let curlcmd .= '-H "Authorization: '.a:login.'" '
	elseif stridx(a:login, ':') != -1
	    let curlcmd .= '-u "'.a:login.'" '
	else
	    let curlcmd .= '-H "Authorization: Basic '.a:login.'" '
	endif
    endif

    let got_json = 0
    for [k, v] in items(a:parms)
	if k == '__json'
	    let got_json = 1
	    let vsub = substitute(v, '"', '\\"', 'g')
	    if  has('win32') || has('win64')
		" Under Windows only, we need to quote some special characters.
		let vsub = substitute(vsub, '[\\&|><^]', '"&"', 'g')
	    endif
	    let curlcmd .= '-d "'.vsub.'" '
	else
	    let curlcmd .= '-d "'.s:url_encode(k).'='.s:url_encode(v).'" '
	endif
    endfor

    if got_json
	let curlcmd .= '-H "Content-Type: application/json" '
    endif
    
    let curlcmd .= '-H "User-Agent: '.s:user_agent.'" '

    let curlcmd .= '"'.a:url.'"'

    let output = system(curlcmd)
    let errormsg = s:xml_get_element(output, 'error')
    if v:shell_error != 0
	let error = output
    elseif errormsg != ''
	let error = errormsg
    endif

    return [ error, output ]
endfunction

" Check if we can use Python.
function! s:check_python()
    let can_python = 1
    python <<EOF
import vim
try:
    import urllib
    import urllib2
    import base64
    import sys
except:
    vim.command('let can_python = 0')
EOF
    return can_python
endfunction

" Use Python to fetch a web page.
function! s:python_curl(url, login, proxy, proxylogin, parms)
    let error = ""
    let output = ""
    python <<EOF
import urllib
import urllib2
import base64
import sys
import vim

def make_base64(s):
    if s.find(':') != -1:
	s = base64.b64encode(s)
    return s

try:
    url = vim.eval("a:url")
    parms = vim.eval("a:parms")

    if parms.get('__json') is not None:
	req = urllib2.Request(url, parms['__json'])
	req.add_header('Content-Type', 'application/json')
    else:
	req = parms == {} and urllib2.Request(url) or urllib2.Request(url, urllib.urlencode(parms))

    login = vim.eval("a:login")
    if login != "":
	if login[0:6] == "OAuth ":
	    req.add_header('Authorization', login)
	else:
	    req.add_header('Authorization', 'Basic %s' % make_base64(login))

    proxy = vim.eval("a:proxy")
    if proxy != "":
	req.set_proxy(proxy, 'http')

    proxylogin = vim.eval("a:proxylogin")
    if proxylogin != "":
	req.add_header('Proxy-Authorization', 'Basic %s' % make_base64(proxylogin))

    req.add_header('User-Agent', vim.eval("s:user_agent"))

    f = urllib2.urlopen(req)
    out = ''.join(f.readlines())
except urllib2.HTTPError, (httperr):
    vim.command("let error='%s'" % str(httperr).replace("'", "''"))
    vim.command("let output='%s'" % httperr.read().replace("'", "''"))
except:
    exctype, value = sys.exc_info()[:2]
    errmsg = (exctype.__name__ + ': ' + str(value)).replace("'", "''")
    vim.command("let error='%s'" % errmsg)
    vim.command("let output='%s'" % errmsg)
else:
    vim.command("let output='%s'" % out.replace("'", "''"))
EOF

    return [ error, output ]
endfunction

" Check if we can use Perl.
function! s:check_perl()
    let can_perl = 1
    perl <<EOF
eval {
    require MIME::Base64;
    MIME::Base64->import;

    require LWP::UserAgent;
    LWP::UserAgent->import;
};

if ($@) {
    VIM::DoCommand('let can_perl = 0');
}
EOF
    return can_perl
endfunction

" Use Perl to fetch a web page.
function! s:perl_curl(url, login, proxy, proxylogin, parms)
    let error = ""
    let output = ""

    perl <<EOF
require MIME::Base64;
MIME::Base64->import;

require LWP::UserAgent;
LWP::UserAgent->import;

sub make_base64 {
    my $s = shift;
    $s =~ /:/ ? encode_base64($s) : $s;
}

my $ua = LWP::UserAgent->new;

my $url = VIM::Eval('a:url');

my $proxy = VIM::Eval('a:proxy');
$proxy ne '' and $ua->proxy('http', "http://$proxy");

my $proxylogin = VIM::Eval('a:proxylogin');
$proxylogin ne '' and $ua->default_header('Proxy-Authorization' => 'Basic '.make_base64($proxylogin));

my %parms = ();
my $keys = VIM::Eval('keys(a:parms)');
for $k (split(/\n/, $keys)) {
    $parms{$k} = VIM::Eval("a:parms['$k']");
}

my $login = VIM::Eval('a:login');
if ($login ne '') {
    if ($login =~ /^OAuth /) {
	$ua->default_header('Authorization' => $login);
    }
    else {
	$ua->default_header('Authorization' => 'Basic '.make_base64($login));
    }
}

$ua->default_header('User-Agent' => VIM::Eval("s:user_agent"));

my $response;

if (defined $parms{'__json'}) {
    $response = $ua->post($url, 
	'Content-Type' => 'application/json',
	Content => $parms{'__json'});
}
else {
    $response = %parms ? $ua->post($url, \%parms) : $ua->get($url);
}
if ($response->is_success) {
    my $output = $response->content;
    $output =~ s/'/''/g;
    VIM::DoCommand("let output ='$output'");
}
else {
    my $output = $response->content;
    $output =~ s/'/''/g;
    VIM::DoCommand("let output ='$output'");

    my $error = $response->status_line;
    $error =~ s/'/''/g;
    VIM::DoCommand("let error ='$error'");
}
EOF

    return [ error, output ]
endfunction

" Check if we can use Ruby.
"
" Note: Before the networking code will function in Ruby under Windows, you
" need the patch from here:
" http://www.mail-archive.com/vim_dev@googlegroups.com/msg03693.html
"
" and Bram's correction to the patch from here:
" http://www.mail-archive.com/vim_dev@googlegroups.com/msg03713.html
"
function! s:check_ruby()
    let can_ruby = 1
    ruby <<EOF
begin
    require 'net/http'
    require 'net/https'
    require 'uri'
    require 'Base64'
rescue LoadError
    VIM.command('let can_ruby = 0')
end
EOF
    return can_ruby
endfunction

" Use Ruby to fetch a web page.
function! s:ruby_curl(url, login, proxy, proxylogin, parms)
    let error = ""
    let output = ""

    ruby <<EOF
require 'net/http'
require 'net/https'
require 'uri'
require 'Base64'

def make_base64(s)
    s =~ /:/ ? Base64.encode64(s) : s
end

def parse_user_password(s)
    (s =~ /:/ ? s : Base64.decode64(s)).split(':', 2)    
end

url = URI.parse(VIM.evaluate('a:url'))
httpargs = [ url.host, url.port ]

proxy = VIM.evaluate('a:proxy')
if proxy != ''
    prox = URI.parse("http://#{proxy}")
    httpargs += [ prox.host, prox.port ]
end

proxylogin = VIM.evaluate('a:proxylogin')
if proxylogin != ''
    httpargs += parse_user_password(proxylogin)
end

net = Net::HTTP.new(*httpargs)

net.use_ssl = (url.scheme == 'https')

# Disable certificate verification if user sets this variable.
cert_insecure = VIM.evaluate('s:get_twitvim_cert_insecure()')
if cert_insecure != '0'
    net.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

parms = {}
keys = VIM.evaluate('keys(a:parms)')

# Vim patch 7.2.374 adds support to if_ruby for Vim types. So keys() will
# actually return a Ruby array instead of a newline-delimited string.
# So we only need to split the string if VIM.evaluate returns a string.
# If it's already an array, leave it alone.

keys = keys.split(/\n/) if keys.is_a? String

keys.each { |k|
    parms[k] = VIM.evaluate("a:parms['#{k}']")
}

begin
    res = net.start { |http| 
	path = "#{url.path}?#{url.query}"
	if parms == {}
	    req = Net::HTTP::Get.new(path)
	elsif parms.has_key?('__json')
	    req = Net::HTTP::Post.new(path)
	    req.body = parms['__json']
	    req.set_content_type('application/json')
	else
	    req = Net::HTTP::Post.new(path)
	    req.set_form_data(parms)
	end

	login = VIM.evaluate('a:login')
	if login != ''
	    if login =~ /^OAuth /
		req.add_field 'Authorization', login
	    else
		req.add_field 'Authorization', "Basic #{make_base64(login)}"
	    end
	end

	req['User-Agent'] = VIM.evaluate("s:user_agent")

	http.request(req)
    }
    case res
    when Net::HTTPSuccess
	output = res.body.gsub("'", "''")
	VIM.command("let output='#{output}'")
    else
	error = "#{res.code} #{res.message}".gsub("'", "''")
	VIM.command("let error='#{error}'")

	output = res.body.gsub("'", "''")
	VIM.command("let output='#{output}'")
    end
rescue => exc
    VIM.command("let error='#{exc.message}'")
end
EOF

    return [error, output]
endfunction

" Check if we can use Tcl.
"
" Note: ActiveTcl 8.5 doesn't include Tcllib in the download. You need to run the following after installing ActiveTcl:
"
"    teacup install tcllib
"
function! s:check_tcl()
    let can_tcl = 1
    tcl <<EOF
if [catch {
    package require http
    package require uri
    package require base64
} result] {
    ::vim::command "let can_tcl = 0"
}
EOF
    return can_tcl
endfunction

" Use Tcl to fetch a web page.
function! s:tcl_curl(url, login, proxy, proxylogin, parms)
    let error = ""
    let output = ""

    tcl << EOF
package require http
package require uri
package require base64

proc make_base64 {s} {
    if { [string first : $s] >= 0 } {
	return [base64::encode $s]
    }
    return $s
}

set url [::vim::expr a:url]

if {[string tolower [string range $url 0 7]] == "https://"} {
    # Load and register support for https URLs.
    package require tls
    ::http::register https 443 ::tls::socket
}

set headers [list]

::http::config -proxyhost ""
set proxy [::vim::expr a:proxy]
if { $proxy != "" } {
    array set prox [uri::split "http://$proxy"]
    ::http::config -proxyhost $prox(host)
    ::http::config -proxyport $prox(port)
}

set proxylogin [::vim::expr a:proxylogin]
if { $proxylogin != "" } {
    lappend headers "Proxy-Authorization" "Basic [make_base64 $proxylogin]"
}

set login [::vim::expr a:login]
if { $login != "" } {
    if {[string range $login 0 5] == "OAuth "} {
	lappend headers "Authorization" $login
    } else {
	lappend headers "Authorization" "Basic [make_base64 $login]"
    }
}

lappend headers "User-Agent" [::vim::expr "s:user_agent"]

set parms [list]
set keys [split [::vim::expr "keys(a:parms)"] "\n"]
if { [llength $keys] > 0 } {
    if { [lsearch -exact $keys "__json"] != -1 } {	
	set query [::vim::expr "a:parms\['__json']"]
	lappend headers "Content-Type" "application/json"
    } else {
	foreach key $keys {
	    lappend parms $key [::vim::expr "a:parms\['$key']"]
	}
	set query [eval [concat ::http::formatQuery $parms]]
    }
    set res [::http::geturl $url -headers $headers -query $query]
} else {
    set res [::http::geturl $url -headers $headers]
}

upvar #0 $res state

if { $state(status) == "ok" } {
    if { [ ::http::ncode $res ] >= 400 } {
	set error $state(http)
	::vim::command "let error = '$error'"
	set output [string map {' ''} $state(body)]
	::vim::command "let output = '$output'"
    } else {
	set output [string map {' ''} $state(body)]
	::vim::command "let output = '$output'"
    }
} else {
    if { [ info exists state(error) ] } {
	set error [string map {' ''} $state(error)]
    } else {
	set error "$state(status) error"
    }
    ::vim::command "let error = '$error'"
}

::http::cleanup $res
EOF

    return [error, output]
endfunction

" Find out which method we can use to fetch a web page.
function! s:get_curl_method()
    if !exists('s:curl_method')
	let s:curl_method = 'curl'
	if s:get_enable_perl() && has('perl') && s:check_perl()
	    let s:curl_method = 'perl'
	elseif s:get_enable_python() && has('python') && s:check_python()
	    let s:curl_method = 'python'
	elseif s:get_enable_ruby() && has('ruby') && s:check_ruby()
	    let s:curl_method = 'ruby'
	elseif s:get_enable_tcl() && has('tcl') && s:check_tcl()
	    let s:curl_method = 'tcl'
	endif
    endif
    return s:curl_method
endfunction

" We need to convert our parameters to UTF-8. In curl_curl() this is already
" handled as part of our url_encode() function, so we only need to do this for
" other net methods. Also, of course, we don't have to do anything if the
" encoding is already UTF-8.
function! s:iconv_parms(parms)
    if s:get_curl_method() == 'curl' || &encoding == 'utf-8'
	return a:parms
    endif
    let parms2 = {}
    for k in keys(a:parms)
	let v = iconv(a:parms[k], &encoding, 'utf-8')
	if v == ''
	    let v = a:parms[k]
	endif
	let parms2[k] = v
    endfor
    return parms2
endfunction

function! s:run_curl(url, login, proxy, proxylogin, parms)
    return s:{s:get_curl_method()}_curl(a:url, a:login, a:proxy, a:proxylogin, s:iconv_parms(a:parms))
endfunction

function! s:reset_curl_method()
    unlet! s:curl_method
endfunction

function! s:show_curl_method()
    echo 'Net Method:' s:get_curl_method()
endfunction

" For debugging. Reset networking method.
if !exists(":TwitVimResetMethod")
    command TwitVimResetMethod :call <SID>reset_curl_method()
endif

" For debugging. Show current networking method.
if !exists(":TwitVimShowMethod")
    command TwitVimShowMethod :call <SID>show_curl_method()
endif


" === End of networking code ===

" === Buffer stack code ===

" Each buffer record holds the following fields:
"
" buftype: Buffer type = dmrecv, dmsent, search, public, friends, user, 
"   replies, list, retweeted_by_me, retweeted_to_me, favorites, trends
" user: For user buffers if other than current user
" list: List slug if displaying a Twitter list.
" page: Keep track of pagination.
" statuses: Tweet IDs. For use by in_reply_to_status_id
" inreplyto: IDs of predecessor messages for @-replies.
" dmids: Direct Message IDs.
" buffer: The buffer text.
" view: viewport saved with winsaveview()
" showheader: 1 if header is shown in this buffer, 0 if header is hidden.

let s:curbuffer = {}

" The info buffer record holds the following fields:
"
" buftype: profile, friends, followers, listmembers, listsubs, userlists, 
"   userlistmem, userlistsubs, listinfo
" next_cursor: Used for paging.
" prev_cursor: Used for paging.
" cursor: Used for refresh.
" user: User name
" list: List name
" buffer: The buffer text.
" view: viewport saved with winsaveview()
" showheader: 1 if header is shown in this buffer, 0 if header is hidden.
" 
" flist: List of friends/followers IDs.
" findex: Starting index within flist of the friends/followers info displayed
" in this buffer.

let s:infobuffer = {}

" ptr = Buffer stack pointer. -1 if no items yet. May not point to the end of
" the list if user has gone back one or more buffers.
let s:bufstack = { 'ptr': -1, 'stack': [] }

let s:infobufstack = { 'ptr': -1, 'stack': [] }

" Maximum items in the buffer stack. Adding a new item after this limit will
" get rid of the first item.
let s:bufstackmax = 10


" Add current buffer to the buffer stack at the next position after current.
" Remove all buffers after that.
function! s:add_buffer(infobuf)

    let stack = a:infobuf ? s:infobufstack : s:bufstack
    let cur = a:infobuf ? s:infobuffer : s:curbuffer

    " If stack is already full, remove the buffer at the bottom of the stack to
    " make room.
    if stack.ptr >= s:bufstackmax
	call remove(stack.stack, 0)
	let stack.ptr -= 1
    endif

    let stack.ptr += 1

    " Suppress errors because there may not be anything to remove after current
    " position.
    silent! call remove(stack.stack, stack.ptr, -1)

    call add(stack.stack, cur)
endfunction

" Check if two buffers show the same info based on attributes.
function! s:is_same(infobuf, a, b)
    let a = a:a
    let b = a:b
    if a:infobuf
	if a.buftype == b.buftype && a.cursor == b.cursor && a.user == b.user && a.list == b.list
	    return 1
	endif
    else
	if a.buftype == b.buftype && a.list == b.list && a.user == b.user && a.page == b.page
	    return 1
	endif
    endif
    return 0
endfunction

" If current buffer is same type as the buffer at the buffer stack pointer then
" just copy it into the buffer stack. Otherwise, add it to buffer stack.
function! s:save_buffer(infobuf)
    let stack = a:infobuf ? s:infobufstack : s:bufstack
    let cur = a:infobuf ? s:infobuffer : s:curbuffer
    let winname = a:infobuf ? s:user_winname : s:twit_winname

    if cur == {}
	return
    endif

    " Save buffer contents and cursor position.
    let twit_bufnr = bufwinnr('^'.winname.'$')
    if twit_bufnr > 0
	let curwin = winnr()
	execute twit_bufnr . "wincmd w"
	let cur.buffer = getline(1, '$')
	let cur.view = winsaveview()
	execute curwin .  "wincmd w"
	
	" If current buffer is the same type as buffer at the top of the stack,
	" then just copy it.
	if stack.ptr >= 0 && s:is_same(a:infobuf, cur, stack.stack[stack.ptr])
	    let stack.stack[stack.ptr] = deepcopy(cur)
	else
	    " Otherwise, push the current buffer onto the stack.
	    call s:add_buffer(a:infobuf)
	endif
    endif

    " If twit_bufnr returned -1, the user closed the window manually. So we
    " have nothing to save. Do not alter the buffer stack.
endfunction

" Go back one buffer in the buffer stack.
function! s:back_buffer(infobuf)
    let stack = a:infobuf ? s:infobufstack : s:bufstack

    call s:save_buffer(a:infobuf)

    if stack.ptr < 1
	call s:warnmsg("Already at oldest buffer. Can't go back further.")
	return -1
    endif

    let stack.ptr -= 1
    if a:infobuf
	let s:infobuffer = deepcopy(stack.stack[stack.ptr])
    else
	let s:curbuffer = deepcopy(stack.stack[stack.ptr])
    endif
    let cur = a:infobuf ? s:infobuffer : s:curbuffer
    let wintype = a:infobuf ? 'userinfo' : 'timeline'

    call s:twitter_wintext_view(cur.buffer, wintype, cur.view)
    return 0
endfunction

" Go forward one buffer in the buffer stack.
function! s:fwd_buffer(infobuf)
    let stack = a:infobuf ? s:infobufstack : s:bufstack

    call s:save_buffer(a:infobuf)

    if stack.ptr + 1 >= len(stack.stack)
	call s:warnmsg("Already at newest buffer. Can't go forward.")
	return -1
    endif

    let stack.ptr += 1
    if a:infobuf
	let s:infobuffer = deepcopy(stack.stack[stack.ptr])
    else
	let s:curbuffer = deepcopy(stack.stack[stack.ptr])
    endif
    let cur = a:infobuf ? s:infobuffer : s:curbuffer
    let wintype = a:infobuf ? 'userinfo' : 'timeline'

    call s:twitter_wintext_view(cur.buffer, wintype, cur.view)
    return 0
endfunction

if !exists(":BackTwitter")
    command BackTwitter :call <SID>back_buffer(0)
endif
if !exists(":ForwardTwitter")
    command ForwardTwitter :call <SID>fwd_buffer(0)
endif
if !exists(":BackInfoTwitter")
    command BackInfoTwitter :call <SID>back_buffer(1)
endif
if !exists(":ForwardInfoTwitter")
    command ForwardInfoTwitter :call <SID>fwd_buffer(1)
endif

" For debugging. Show the buffer stack.
function! s:show_bufstack(infobuf)
    let stack = a:infobuf ? s:infobufstack : s:bufstack

    for i in range(len(stack.stack) - 1, 0, -1)
	let s = i.':'
	let s .= ' type='.stack.stack[i].buftype
	let s .= ' user='.stack.stack[i].user
	let s .= ' list='.stack.stack[i].list
	if a:infobuf
	    let s .= ' cursor='.stack.stack[i].cursor
	else
	    let s .= ' page='.stack.stack[i].page
	endif
	echo s
    endfor
endfunction

if !exists(":TwitVimShowBufstack")
    command TwitVimShowBufstack :call <SID>show_bufstack(0)
endif
if !exists(":TwitVimShowInfoBufstack")
    command TwitVimShowInfoBufstack :call <SID>show_bufstack(1)
endif

" For debugging. Show curbuffer variable.
if !exists(":TwitVimShowCurbuffer")
    command TwitVimShowCurbuffer :echo s:curbuffer
endif
" For debugging. Show infobuffer variable.
if !exists(":TwitVimShowInfobuffer")
    command TwitVimShowInfobuffer :echo s:infobuffer
endif

" === End of buffer stack code ===

" Add update to Twitter buffer if public, friends, or user timeline.
function! s:add_update(output)
    if has_key(s:curbuffer, 'buftype') && (s:curbuffer.buftype == "public" || s:curbuffer.buftype == "friends" || s:curbuffer.buftype == "user" || s:curbuffer.buftype == "replies" || s:curbuffer.buftype == "list" || s:curbuffer.buftype == "retweeted_by_me" || s:curbuffer.buftype == "retweeted_to_me")

	" Parse the output from the Twitter update call.
	let line = s:format_status_xml(a:output)

	" Line number where new tweet will be inserted. It should be 3 if
	" header is shown and 1 if header is hidden.
	let insline = s:curbuffer.showheader ? 3 : 1

	" Add the status ID to the current buffer's statuses list.
	call insert(s:curbuffer.statuses, s:xml_get_element(a:output, 'id'), insline)

	" Add in-reply-to ID to current buffer's in-reply-to list.
	call insert(s:curbuffer.inreplyto, s:xml_get_element(a:output, 'in_reply_to_status_id'), insline)

	let twit_bufnr = bufwinnr('^'.s:twit_winname.'$')
	if twit_bufnr > 0
	    let curwin = winnr()
	    execute twit_bufnr . "wincmd w"
	    setlocal modifiable
	    call append(insline - 1, line)
	    execute "normal! ".insline."G"
	    setlocal nomodifiable
	    let s:curbuffer.buffer = getline(1, '$')
	    execute curwin .  "wincmd w"
	endif
    endif
endfunction

" Count number of characters in a multibyte string. Use technique from
" :help strlen().
function! s:mbstrlen(s)
    return strlen(substitute(a:s, ".", "x", "g"))
endfunction

" Common code to post a message to Twitter.
function! s:post_twitter(mesg, inreplyto)
    let parms = {}

    " Add in_reply_to_status_id if status ID is available.
    if a:inreplyto != 0
	let parms["in_reply_to_status_id"] = a:inreplyto
    endif

    let mesg = a:mesg

    " Remove trailing newline. You see that when you visual-select an entire
    " line. Don't let it count towards the tweet length.
    let mesg = substitute(mesg, '\n$', '', "")

    " Convert internal newlines to spaces.
    let mesg = substitute(mesg, '\n', ' ', "g")

    let mesglen = s:mbstrlen(mesg)

    " Check tweet length. Note that the tweet length should be checked before
    " URL-encoding the special characters because URL-encoding increases the
    " string length.
    if mesglen > s:char_limit
	call s:warnmsg("Your tweet has ".(mesglen - s:char_limit)." too many characters. It was not sent.")
    elseif mesglen < 1
	call s:warnmsg("Your tweet was empty. It was not sent.")
    else
	redraw
	echo "Sending update to Twitter..."

	let url = s:get_api_root()."/statuses/update.xml"
	let parms["status"] = mesg
	let parms["source"] = "twitvim"

	let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)

	if error != ''
	    let errormsg = s:xml_get_element(output, 'error')
	    call s:errormsg("Error posting your tweet: ".(errormsg != '' ? errormsg : error))
	else
	    call s:add_update(output)
	    redraw
	    echo "Your tweet was sent. You used ".mesglen." characters."
	endif
    endif
endfunction

" Prompt user for tweet and then post it.
" If initstr is given, use that as the initial input.
function! s:CmdLine_Twitter(initstr, inreplyto)
    call inputsave()
    redraw
    let mesg = input("Your Twitter: ", a:initstr)
    call inputrestore()
    call s:post_twitter(mesg, a:inreplyto)
endfunction

" Extract the user name from a line in the timeline.
function! s:get_user_name(line)
    let line = substitute(a:line, '^+ ', '', '')
    let matchres = matchlist(line, '^\(\w\+\):')
    return matchres != [] ? matchres[1] : ""
endfunction

" This is for a local mapping in the timeline. Start an @-reply on the command
" line to the author of the tweet on the current line.
function! s:Quick_Reply()
    let username = s:get_user_name(getline('.'))
    if username != ""
	" If the status ID is not available, get() will return 0 and
	" post_twitter() won't add in_reply_to_status_id to the update.
	call s:CmdLine_Twitter('@'.username.' ', get(s:curbuffer.statuses, line('.')))
    endif
endfunction

" Extract all user names from a line in the timeline. Return the poster's name as well as names from all the @replies.
function! s:get_all_names(line)
    let names = []
    let dictnames = {}

    let username = s:get_user_name(getline('.'))
    if username != ""
	" Add this to the beginning of the list because we want the tweet
	" author to be the main addressee in the reply to all.
	let names = [ username ]
	let dictnames[tolower(username)] = 1
    endif

    let matchcount = 1
    while 1
	let matchres = matchlist(a:line, '@\(\w\+\)', -1, matchcount)
	if matchres == []
	    break
	endif
	let name = matchres[1]
	" Don't add duplicate names.
	if !has_key(dictnames, tolower(name))
	    call add(names, name)
	    let dictnames[tolower(name)] = 1
	endif
	let matchcount += 1
    endwhile

    return names
endfunction

" Reply to everyone mentioned on a line in the timeline.
function! s:Reply_All()
    let names = s:get_all_names(getline('.'))

    " Remove the author from the reply list so that he doesn't end up replying
    " to himself.
    let user = s:get_twitvim_username()
    let names2 = []
    for name in names
	if name != user
	    call add(names2, name)
	endif
    endfor

    let replystr = '@'.join(names2, ' @').' '

    if names != []
	" If the status ID is not available, get() will return 0 and
	" post_twitter() won't add in_reply_to_status_id to the update.
	call s:CmdLine_Twitter(replystr, get(s:curbuffer.statuses, line('.')))
    endif
endfunction

" This is for a local mapping in the timeline. Start a direct message on the
" command line to the author of the tweet on the current line.
function! s:Quick_DM()
    let username = s:get_user_name(getline('.'))
    if username != ""
	" call s:CmdLine_Twitter('d '.username.' ', 0)
	call s:send_dm(username, '')
    endif
endfunction

" Allow user to switch to old-style retweets by setting twitvim_old_retweet.
function! s:get_old_retweet()
    return exists('g:twitvim_old_retweet') ? g:twitvim_old_retweet : 0
endfunction

" Extract the tweet text from a timeline buffer line.
function! s:get_tweet(line)
    let line = substitute(a:line, '^\w\+:\s\+', '', '')
    let line = substitute(line, '\s\+|[^|]\+|$', '', '')

    " Remove newlines.
    let line = substitute(line, "\n", '', 'g')

    return line
endfunction

" Retweet is for replicating a tweet from another user.
function! s:Retweet()
    let line = getline('.')
    let username = s:get_user_name(line)
    if username != ""
	let retweet = substitute(s:get_retweet_fmt(), '%s', '@'.username, '')
	let retweet = substitute(retweet, '%t', s:get_tweet(line), '')
	call s:CmdLine_Twitter(retweet, 0)
    endif
endfunction

" Use new-style retweet API to retweet a tweet from another user.
function! s:Retweet_2()

    " Do an old-style retweet if user has set twitvim_old_retweet.
    if s:get_old_retweet()
	call s:Retweet()
	return
    endif

    let status = get(s:curbuffer.statuses, line('.'))
    if status == 0
	" Fall back to old-style retweeting if we can't get this tweet's status
	" ID.
	call s:Retweet()
	return
    endif

    let parms = {}

    " Force POST instead of GET.
    let parms["dummy"] = "dummy1"

    let url = s:get_api_root()."/statuses/retweet/".status.".xml"

    redraw
    echo "Retweeting..."

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error retweeting: ".(errormsg != '' ? errormsg : error))
    else
	call s:add_update(output)
	redraw
	echo "Retweeted."
    endif
endfunction

" Show which tweet this one is replying to below the current line.
function! s:show_inreplyto()
    let lineno = line('.')

    let inreplyto = get(s:curbuffer.inreplyto, lineno)
    if inreplyto == 0
	call s:warnmsg("No in-reply-to information for current line.")
	return
    endif

    redraw
    echo "Querying Twitter for in-reply-to tweet..."

    let url = s:get_api_root()."/statuses/show/".inreplyto.".xml"

    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting in-reply-to tweet: ".(errormsg != '' ? errormsg : error))
	return
    endif

    let line = s:format_status_xml(output)

    " Add the status ID to the current buffer's statuses list.
    call insert(s:curbuffer.statuses, s:xml_get_element(output, 'id'), lineno + 1)

    " Add in-reply-to ID to current buffer's in-reply-to list.
    call insert(s:curbuffer.inreplyto, s:xml_get_element(output, 'in_reply_to_status_id'), lineno + 1)

    " Already in the correct buffer so no need to search or switch buffers.
    setlocal modifiable
    call append(lineno, '+ '.line)
    setlocal nomodifiable
    let s:curbuffer.buffer = getline(1, '$')

    redraw
    echo "In-reply-to tweet found."
endfunction

" Truncate a string. Add '...' to the end of string was longer than
" the specified number of characters.
function! s:strtrunc(s, len)
    let slen = strlen(substitute(a:s, ".", "x", "g"))
    let s = substitute(a:s, '^\(.\{,'.a:len.'}\).*$', '\1', '')
    if slen > a:len
	let s .= '...'
    endif
    return s
endfunction

" Delete tweet or DM on current line.
function! s:do_delete_tweet()
    let lineno = line('.')

    let isdm = (s:curbuffer.buftype == "dmrecv" || s:curbuffer.buftype == "dmsent")
    let obj = isdm ? "message" : "tweet"
    let uobj = isdm ? "Message" : "Tweet"

    let id = get(isdm ? s:curbuffer.dmids : s:curbuffer.statuses, lineno)

    " The delete API call requires POST, not GET, so we supply a fake parameter
    " to force run_curl() to use POST.
    let parms = {}
    let parms["id"] = id

    let url = s:get_api_root().'/'.(isdm ? "direct_messages" : "statuses")."/destroy/".id.".xml"
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error deleting ".obj.": ".(errormsg != '' ? errormsg : error))
	return
    endif

    if isdm
	call remove(s:curbuffer.dmids, lineno)
    else
	call remove(s:curbuffer.statuses, lineno)
	call remove(s:curbuffer.inreplyto, lineno)
    endif

    " Already in the correct buffer so no need to search or switch buffers.
    setlocal modifiable
    normal! dd
    setlocal nomodifiable
    let s:curbuffer.buffer = getline(1, '$')

    redraw
    echo uobj "deleted."
endfunction

" Delete tweet or DM on current line.
function! s:delete_tweet()
    let lineno = line('.')

    let isdm = (s:curbuffer.buftype == "dmrecv" || s:curbuffer.buftype == "dmsent")
    let obj = isdm ? "message" : "tweet"
    let uobj = isdm ? "Message" : "Tweet"

    let id = get(isdm ? s:curbuffer.dmids : s:curbuffer.statuses, lineno)
    if id == 0
	call s:warnmsg("No erasable ".obj." on current line.")
	return
    endif

    call inputsave()
    let answer = input('Delete "'.s:strtrunc(getline('.'), 40).'"? (y/n) ')
    call inputrestore()
    if answer == 'y' || answer == 'Y'
	call s:do_delete_tweet()
    else
	redraw
	echo uobj "not deleted."
    endif
endfunction

" Fave or Unfave tweet on current line.
function! s:fave_tweet(unfave)
    let id = get(s:curbuffer.statuses, line('.'))
    if id == 0
	call s:warnmsg('Nothing to '.(a:unfave ? 'unfavorite' : 'favorite').' on current line.')
	return
    endif

    redraw
    echo (a:unfave ? 'Unfavoriting' : 'Favoriting') 'the tweet...'

    " favorites/create and favorites/destroy both require POST, not GET, so we
    " supply a fake parameter to force run_curl() to use POST.
    let parms = {}
    let parms['id'] = id

    let url = s:get_api_root().'/favorites/'.(a:unfave ? 'destroy' : 'create').'/'.id.'.xml'
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error ".(a:unfave ? 'unfavoriting' : 'favoriting')." the tweet: ".(errormsg != '' ? errormsg : error))
	return
    endif

    redraw
    echo 'Tweet' (a:unfave ? 'unfavorited.' : 'favorited.')
endfunction

" Prompt user for tweet.
if !exists(":PosttoTwitter")
    command PosttoTwitter :call <SID>CmdLine_Twitter('', 0)
endif

nnoremenu Plugin.TwitVim.Post\ from\ cmdline :call <SID>CmdLine_Twitter('', 0)<cr>

" Post current line to Twitter.
if !exists(":CPosttoTwitter")
    command CPosttoTwitter :call <SID>post_twitter(getline('.'), 0)
endif

nnoremenu Plugin.TwitVim.Post\ current\ line :call <SID>post_twitter(getline('.'), 0)<cr>

" Post entire buffer to Twitter.
if !exists(":BPosttoTwitter")
    command BPosttoTwitter :call <SID>post_twitter(join(getline(1, "$")), 0)
endif

" Post visual selection to Twitter.
noremap <SID>Visual y:call <SID>post_twitter(@", 0)<cr>
noremap <unique> <script> <Plug>TwitvimVisual <SID>Visual
if !hasmapto('<Plug>TwitvimVisual')
    vmap <unique> <A-t> <Plug>TwitvimVisual

    " Allow Ctrl-T as an alternative to Alt-T.
    " Alt-T pulls down the Tools menu if the menu bar is enabled.
    vmap <unique> <C-t> <Plug>TwitvimVisual
endif

vmenu Plugin.TwitVim.Post\ selection <Plug>TwitvimVisual

" Launch web browser with the given URL.
function! s:launch_browser(url)
    if !exists('g:twitvim_browser_cmd') || g:twitvim_browser_cmd == ''
	" Beep and error-highlight 
	execute "normal! \<Esc>"
	call s:errormsg('Browser cmd not set. Please add to .vimrc: let twitvim_browser_cmd="browsercmd"')
	return -1
    endif

    let startcmd = has("win32") || has("win64") ? "!start " : "! "

    " Discard unnecessary output from UNIX browsers. So far, this is known to
    " happen only in the Linux version of Google Chrome when it opens a tab in
    " an existing browser window.
    let endcmd = has('unix') ? '> /dev/null &' : ''

    " Escape characters that have special meaning in the :! command.
    let url = substitute(a:url, '!\|#\|%', '\\&', 'g')

    " Escape the '&' character under Unix. This character is valid in URLs but
    " causes the shell to background the process and cut off the URL at that
    " point.
    if has('unix')
	let url = substitute(url, '&', '\\&', 'g')
    endif

    redraw
    echo "Launching web browser..."
    let v:errmsg = ""
    silent! execute startcmd g:twitvim_browser_cmd url endcmd
    if v:errmsg == ""
	redraw!
	echo "Web browser launched."
    else
	call s:errormsg('Error launching browser: '.v:errmsg)
	return -2
    endif

    return 0
endfunction

let s:URLMATCH = '\%([Hh][Tt][Tt][Pp]\|[Hh][Tt][Tt][Pp][Ss]\|[Ff][Tt][Pp]\)://\S\+'

" Launch web browser with the URL at the cursor position. If possible, this
" function will try to recognize a URL within the current word. Otherwise,
" it'll just use the whole word.
" If the cWORD happens to be @user or user:, show that user's timeline.
function! s:launch_url_cword(infobuf)
    let s = expand("<cWORD>")

    " Handle @-replies by showing that user's timeline.
    " An @-reply must be preceded by a non-word character and ends at a
    " non-word character.
    let matchres = matchlist(s, '\w\@<!@\(\w\+\)')
    if matchres != []
	call s:get_timeline("user", matchres[1], 1)
	return
    endif

    if a:infobuf
	" Don't match ^word: if in profile buffer. It leads to all kinds of
	" false matches. Instead, parse a Name: line specially.
	let name = s:info_getname()
	if name != ''
	    call s:get_timeline("user", name, 1)
	    return
	endif

	" Parse a Website: line specially.
	let matchres = matchlist(getline('.'), '^Website: \('.s:URLMATCH.'\)')
	if matchres != []
	    call s:launch_browser(matchres[1])
	    return
	endif

	" Don't do anything on field labels in profile buffer.
	" Otherwise, the code below will needlessly launch a web browser.
	let matchres = matchlist(s, '^\(\w\+\):$')
	if matchres != []
	    return
	endif
    else
	" In a trending topics list, the whole line is a search term.
	if s:curbuffer.buftype == 'trends'
	    if !s:curbuffer.showheader || line('.') > 2
		call s:get_summize(getline('.'), 1)
	    endif
	    return
	endif

	if col('.') == 1 && s == '+'
	    " If the cursor is on the '+' in a reply expansion, use the second
	    " word instead.
	    let matchres = matchlist(getline('.'), '^+ \(\w\+\):')
	    if matchres != []
		call s:get_timeline("user", matchres[1], 1)
		return
	    endif
	endif

	" Handle username: at the beginning of the line by showing that user's
	" timeline.
	let matchres = matchlist(s, '^\(\w\+\):$')
	if matchres != []
	    call s:get_timeline("user", matchres[1], 1)
	    return
	endif
    endif

    " Handle #-hashtags by showing the Twitter Search for that hashtag.
    " A #-hashtag must be preceded by a non-word character and ends at a
    " non-word character.
    let matchres = matchlist(s, '\w\@<!\(#\w\+\)')
    if matchres != []
	call s:get_summize(matchres[1], 1)
	return
    endif

    let s = substitute(s, '.*\<\('.s:URLMATCH.'\)', '\1', "")
    call s:launch_browser(s)
endfunction

" Extract name from current line in info buffer, if possible.
function! s:info_getname()
    let matchres = matchlist(getline('.'), '^Name: \(\w\+\)')
    if matchres != []
	return matchres[1]
    else
	return ''
    endif
endfunction

" Attempt to scrape deck.ly HTML to get the long tweet.
function! s:get_deckly(url)
    let [error, output] = s:run_curl(a:url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	call s:errormsg('Error getting deck.ly page: '.error)
	return ''
    endif
    let matchres = matchlist(output, '<div\s\+id="deckly-post"[^>]\+>\(\_.*\)</div>')
    if matchres == []
	call s:errormsg('Could not find long post in deck.ly page.')
	return ''
    endif
    let matchres = matchlist(matchres[1], '<p>\(\_.\{-}\)</p>')
    if matchres == []
	call s:errormsg('Could not find long post in deckly-post div.')
	return ''
    endif
    let s = matchres[1]
    let s = substitute(s, '<a\>[^>]\+>', '', 'g')
    let s = substitute(s, '</a>', '', 'g')
    return s
endfunction

" Call LongURL API on a shorturl to expand it.
function! s:call_longurl(url)
    redraw
    echo "Sending request to LongURL..."

    let url = 'http://api.longurl.org/v1/expand?url='.s:url_encode(a:url)
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	call s:errormsg("Error calling LongURL API: ".error)
	return ""
    else
	redraw
	echo "Received response from LongURL."

	let longurl = s:xml_get_element(output, 'long_url')
	if longurl != ""
	    let longurl = substitute(longurl, '<!\[CDATA\[\(.*\)]]>', '\1', '')

	    " If it is a deck.ly URL, attempt to get the long tweet.
	    if a:url =~? 'deck\.ly' && longurl =~? 'tweetdeck\.com/twitter'
		let longpost = s:get_deckly(longurl)
		if longpost != ''
		    return longpost
		endif
	    endif

	    return longurl
	endif

	let errormsg = s:xml_get_element(output, 'error')
	if errormsg != ""
	    call s:errormsg("LongURL error: ".errormsg)
	    return ""
	endif

	call s:errormsg("Unknown response from LongURL: ".output)
	return ""
    endif
endfunction

" Call LongURL API on the given string. If no string is provided, use the
" current word. In the latter case, this function will try to recognize a URL
" within the word. Otherwise, it'll just use the whole word.
function! s:do_longurl(s)
    let s = a:s
    if s == ""
	let s = expand("<cWORD>")
	let s = substitute(s, '.*\<\('.s:URLMATCH.'\)', '\1', "")
    endif
    let result = s:call_longurl(s)
    if result != ""
	redraw
	echo s.' expands to '.result
    endif
endfunction


" Just like do_user_info() but handle Name: lines in info buffer specially.
function! s:do_user_info_infobuf()
    let name = s:info_getname()
    if name != ''
	call s:get_user_info(name)
	return
    endif

    " Fall back to original user info function.
    call s:do_user_info('')
endfunction

" Get info on the given user. If no user is provided, use the current word and
" strip off the @ or : if the current word is @user or user:. 
function! s:do_user_info(s)
    let s = a:s
    if s == ''
	let s = expand("<cword>")
	
	" Handle @-replies.
	let matchres = matchlist(s, '^@\(\w\+\)')
	if matchres != []
	    let s = matchres[1]
	else
	    " Handle username: at the beginning of the line.
	    let matchres = matchlist(s, '^\(\w\+\):$')
	    if matchres != []
		let s = matchres[1]
	    endif
	endif
    endif

    call s:get_user_info(s)
endfunction

" nr2byte() and nr2enc_char() converter functions for non-UTF8 encoding
" provided by @mattn_jp

" Get bytes from character code.
function! s:nr2byte(nr)
    if a:nr < 0x80
	return nr2char(a:nr)
    elseif a:nr < 0x800
	return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
    else
	return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
    endif
endfunction

" Convert character code from utf-8 to encoding.
function! s:nr2enc_char(charcode)
    if &encoding == 'utf-8'
	return nr2char(a:charcode)
    endif
    let char = s:nr2byte(a:charcode)
    if strlen(char) > 1
	let iconv_str = iconv(char, 'utf-8', &encoding)
	if iconv_str != ""
	    let char = strtrans(iconv_str)
	endif
    endif
    return char
endfunction


" Decode HTML entities. Twitter gives those to us a little weird. For example,
" a '<' character comes to us as &amp;lt;
function! s:convert_entity(str)
    let s = a:str
    let s = substitute(s, '&amp;', '\&', 'g')
    let s = substitute(s, '&lt;', '<', 'g')
    let s = substitute(s, '&gt;', '>', 'g')
    let s = substitute(s, '&quot;', '"', 'g')
    " let s = substitute(s, '&#\(\d\+\);','\=nr2char(submatch(1))', 'g')
    let s = substitute(s, '&#\(\d\+\);','\=s:nr2enc_char(submatch(1))', 'g')
    let s = substitute(s, '&#x\(\x\+\);','\=s:nr2enc_char("0x".submatch(1))', 'g')
    return s
endfunction

let s:twit_winname = "Twitter_".localtime()

" Set syntax highlighting in timeline window.
function! s:twitter_win_syntax(wintype)
    " Beautify the Twitter window with syntax highlighting.
    if has("syntax") && exists("g:syntax_on")
	" Reset syntax items in case there are any predefined in the new buffer.
	syntax clear

	" Twitter user name: from start of line to first colon.
	syntax match twitterUser /^.\{-1,}:/

	" Use the bars to recognize the time but hide the bars.
	syntax match twitterTime /|[^|]\+|$/ contains=twitterTimeBar
	syntax match twitterTimeBar /|/ contained

	" Highlight links in tweets.
	execute 'syntax match twitterLink "\<'.s:URLMATCH.'"'

	" An @-reply must be preceded by a non-word character and ends at a
	" non-word character.
	syntax match twitterReply "\w\@<!@\w\+"

	" A #-hashtag must be preceded by a non-word character and ends at a
	" non-word character.
	syntax match twitterLink "\w\@<!#\w\+"

	" Use the extra star at the end to recognize the title but hide the
	" star.
	syntax match twitterTitle /^\%(\w\+:\)\@!.\+\*$/ contains=twitterTitleStar
	syntax match twitterTitleStar /\*$/ contained

	highlight default link twitterUser Identifier
	highlight default link twitterTime String
	highlight default link twitterTimeBar Ignore
	highlight default link twitterTitle Title
	highlight default link twitterTitleStar Ignore
	highlight default link twitterLink Underlined
	highlight default link twitterReply Label
    endif
endfunction

" Switch to the Twitter window if there is already one or open a new window for
" Twitter.
" Returns 1 if new window created, 0 otherwise.
function! s:twitter_win(wintype)
    let winname = a:wintype == "userinfo" ? s:user_winname : s:twit_winname
    let newwin = 0

    let twit_bufnr = bufwinnr('^'.winname.'$')
    if twit_bufnr > 0
	execute twit_bufnr . "wincmd w"
    else
	let newwin = 1
	execute "new " . winname
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=delete 
	setlocal foldcolumn=0
	setlocal nobuflisted
	setlocal nospell

	" Launch browser with URL in visual selection or at cursor position.
	nnoremap <buffer> <silent> <A-g> :call <SID>launch_url_cword(0)<cr>
	nnoremap <buffer> <silent> <Leader>g :call <SID>launch_url_cword(0)<cr>
	vnoremap <buffer> <silent> <A-g> y:call <SID>launch_browser(@")<cr>
	vnoremap <buffer> <silent> <Leader>g y:call <SID>launch_browser(@")<cr>

	" Get user info for current word or selection.
	nnoremap <buffer> <silent> <Leader>p :call <SID>do_user_info("")<cr>
	vnoremap <buffer> <silent> <Leader>p y:call <SID>do_user_info(@")<cr>

	" Call LongURL API on current word or selection.
	nnoremap <buffer> <silent> <Leader>e :call <SID>do_longurl("")<cr>
	vnoremap <buffer> <silent> <Leader>e y:call <SID>do_longurl(@")<cr>

	if a:wintype == "userinfo"
	    " Next page in info buffer.
	    nnoremap <buffer> <silent> <C-PageDown> :call <SID>NextPageInfo()<cr>

	    " Previous page in info buffer.
	    nnoremap <buffer> <silent> <C-PageUp> :call <SID>PrevPageInfo()<cr>
	    
	    " Refresh info buffer.
	    nnoremap <buffer> <silent> <Leader><Leader> :call <SID>RefreshInfo()<cr>

	    " We need this to be handled specially in the info buffer.
	    nnoremap <buffer> <silent> <A-g> :call <SID>launch_url_cword(1)<cr>
	    nnoremap <buffer> <silent> <Leader>g :call <SID>launch_url_cword(1)<cr>
	    
	    " This also needs to be handled specially for Name: lines.
	    nnoremap <buffer> <silent> <Leader>p :call <SID>do_user_info_infobuf()<cr>

	    " Go back and forth through buffer stack.
	    nnoremap <buffer> <silent> <C-o> :call <SID>back_buffer(1)<cr>
	    nnoremap <buffer> <silent> <C-i> :call <SID>fwd_buffer(1)<cr>
	else
	    " Quick reply feature for replying from the timeline.
	    nnoremap <buffer> <silent> <A-r> :call <SID>Quick_Reply()<cr>
	    nnoremap <buffer> <silent> <Leader>r :call <SID>Quick_Reply()<cr>

	    " Quick DM feature for direct messaging from the timeline.
	    nnoremap <buffer> <silent> <A-d> :call <SID>Quick_DM()<cr>
	    nnoremap <buffer> <silent> <Leader>d :call <SID>Quick_DM()<cr>

	    " Retweet feature for replicating another user's tweet.
	    nnoremap <buffer> <silent> <Leader>R :call <SID>Retweet_2()<cr>

	    " Reply to all feature.
	    nnoremap <buffer> <silent> <Leader><C-r> :call <SID>Reply_All()<cr>

	    " Show in-reply-to for current tweet.
	    nnoremap <buffer> <silent> <Leader>@ :call <SID>show_inreplyto()<cr>

	    " Delete tweet or message on current line.
	    nnoremap <buffer> <silent> <Leader>X :call <SID>delete_tweet()<cr>

	    " Refresh timeline.
	    nnoremap <buffer> <silent> <Leader><Leader> :call <SID>RefreshTimeline()<cr>

	    " Next page in timeline.
	    nnoremap <buffer> <silent> <C-PageDown> :call <SID>NextPageTimeline()<cr>

	    " Previous page in timeline.
	    nnoremap <buffer> <silent> <C-PageUp> :call <SID>PrevPageTimeline()<cr>

	    " Favorite a tweet.
	    nnoremap <buffer> <silent> <Leader>f :call <SID>fave_tweet(0)<cr>
	    " Unfavorite a tweet.
	    nnoremap <buffer> <silent> <Leader><C-f> :call <SID>fave_tweet(1)<cr>

	    " Go back and forth through buffer stack.
	    nnoremap <buffer> <silent> <C-o> :call <SID>back_buffer(0)<cr>
	    nnoremap <buffer> <silent> <C-i> :call <SID>fwd_buffer(0)<cr>
	endif
    endif

    setlocal filetype=twitvim
    call s:twitter_win_syntax(a:wintype)
    return newwin
endfunction

" Get a Twitter window and stuff text into it. If view is not an empty
" dictionary then restore the cursor position to the saved view.
function! s:twitter_wintext_view(text, wintype, view)
    let curwin = winnr()
    let newwin = s:twitter_win(a:wintype)

    setlocal modifiable

    " Overwrite the entire buffer.
    " Need to use 'silent' or a 'No lines in buffer' message will appear.
    " Delete to the blackhole register "_ so that we don't affect registers.
    silent %delete _
    call setline('.', a:text)
    normal! 1G

    setlocal nomodifiable

    " Restore the saved view if provided.
    if a:view != {}
	call winrestview(a:view)
    endif

    " Go back to original window after updating buffer. If a new window is
    " created then our saved curwin number is wrong so the best we can do is to
    " take the user back to the last-accessed window using 'wincmd p'.
    if newwin
	wincmd p
    else
	execute curwin .  "wincmd w"
    endif
endfunction

" Get a Twitter window and stuff text into it.
function! s:twitter_wintext(text, wintype)
    call s:twitter_wintext_view(a:text, a:wintype, {})
endfunction

" Format a retweeted status, if available.
function! s:format_retweeted_status(item)
    let rt = s:xml_get_element(a:item, 'retweeted_status')
    if rt == ''
	return ''
    endif
    let user = s:xml_get_element(rt, 'screen_name')
    let text = s:convert_entity(s:get_status_text(rt))
    return 'RT @'.user.': '.text
endfunction

" Replace all matching strings in a string. This is a non-regex version of substitute().
function! s:str_replace_all(str, findstr, replstr)
    let findlen = strlen(a:findstr)
    let repllen = strlen(a:replstr)
    let s = a:str

    let idx = 0
    while 1
	let idx = stridx(s, a:findstr, idx)
	if idx < 0
	    break
	endif
	let s = strpart(s, 0, idx) . a:replstr . strpart(s, idx + findlen)
	let idx += repllen
    endwhile

    return s
endfunction

" Get status text with t.co URL expansion.
function! s:get_status_text(item)
    let text = s:xml_get_element(a:item, 'text')

    " Remove nul characters.
    let text = substitute(text, '[\x0]', ' ', 'g')

    let entities = s:xml_get_element(a:item, 'entities')
    let urls = s:xml_get_element(entities, 'urls')

    " Twitter entities output currently has a url element inside each url
    " element, so we handle that by only getting every other url element.
    let matchcount = 1
    while 1
	let url = s:xml_get_nth(urls, 'url', matchcount * 2)
	let expanded_url = s:xml_get_nth(urls, 'expanded_url', matchcount)

	if url == '' || expanded_url == ''
	    break
	endif

	" echomsg "Replacing ".url." with ".expanded_url." in ".text
	let text = s:str_replace_all(text, url, expanded_url)

	let matchcount += 1
    endwhile

    return text
endfunction

" Format XML status as a display line.
function! s:format_status_xml(item)
    let item = a:item

    " Quick hack. Even though we're getting new-style retweets in the timeline
    " XML, we'll still use the old-style retweet text from it.
    let item = s:xml_remove_elements(item, 'retweeted_status')

    let user = s:xml_get_element(item, 'screen_name')
    let text = s:format_retweeted_status(a:item)
    if text == ''
	let text = s:convert_entity(s:get_status_text(item))
    endif
    let pubdate = s:time_filter(s:xml_get_element(item, 'created_at'))

    return user.': '.text.' |'.pubdate.'|'
endfunction

" Get in-reply-to from a status element. If this is a retweet, use the id of
" the retweeted status as the in-reply-to.
function! s:get_in_reply_to(status)
    let rt = s:xml_get_element(a:status, 'retweeted_status')
    return rt != '' ? s:xml_get_element(rt, 'id') : s:xml_get_element(a:status, 'in_reply_to_status_id')
endfunction

" If the filter is enabled, test the current item against the filter. Returns
" true if there is a match and the item should be excluded from the timeline.
function! s:check_filter(item)
    if s:get_filter_enable()
	let filter = s:get_filter_regex()
	if filter != ''
	    let text = s:convert_entity(s:get_status_text(a:item))
	    if match(text, filter) >= 0
		return 1
	    endif
	endif
    endif
    return 0
endfunction

" Show a timeline from XML stream data.
function! s:show_timeline_xml(timeline, tline_name, username, page)
    let text = []

    let s:curbuffer.dmids = []

    " Construct page title.

    let title = substitute(a:tline_name, '^.', '\u&', '')." timeline"
    if a:username != ''
	let title .= " for ".a:username
    endif

    " Special case titles for Retweets and Mentions.
    if a:tline_name == "retweeted_to_me"
	let title = "Retweets by others"
    elseif a:tline_name == "retweeted_by_me"
	let title = "Retweets by you"
    elseif a:tline_name == "replies"
	let title = "Mentions timeline"
    endif

    if a:page > 1
	let title .= ' (page '.a:page.')'
    endif

    let s:curbuffer.showheader = s:get_show_header()
    if s:curbuffer.showheader
	" Index of first status will be 3 to match line numbers in timeline
	" display.
	let s:curbuffer.statuses = [0, 0, 0]
	let s:curbuffer.inreplyto = [0, 0, 0]

	" The extra stars at the end are for the syntax highlighter to
	" recognize the title. Then the syntax highlighter hides the stars by
	" coloring them the same as the background. It is a bad hack.
	call add(text, title.'*')
	call add(text, repeat('=', s:mbstrlen(title)).'*')
    else
	" Index of first status will be 1 to match line numbers in timeline
	" display.
	let s:curbuffer.statuses = [0]
	let s:curbuffer.inreplyto = [0]
    endif

    for item in s:xml_get_all(a:timeline, 'status')
	if !s:check_filter(item)
	    call add(s:curbuffer.statuses, s:xml_get_element(item, 'id'))
	    call add(s:curbuffer.inreplyto, s:get_in_reply_to(item))

	    let line = s:format_status_xml(item)
	    call add(text, line)
	endif
    endfor

    call s:twitter_wintext(text, "timeline")
    let s:curbuffer.buffer = text
endfunction

" Add a parameter to a URL.
function! s:add_to_url(url, parm)
    return a:url . (a:url =~ '?' ? '&' : '?') . a:parm
endfunction

" Generic timeline retrieval function.
function! s:get_timeline(tline_name, username, page)
    if a:tline_name == "public"
	" No authentication is needed for public timeline.
	let login = ''
    else
	let login = s:ologin
    endif

    let url_fname = (a:tline_name == "favorites" || a:tline_name == "retweeted_to_me" || a:tline_name == "retweeted_by_me") ? a:tline_name.".xml" : a:tline_name == "friends" ? "home_timeline.xml" : a:tline_name == "replies" ? "mentions.xml" : a:tline_name."_timeline.xml"

    " Support pagination.
    if a:page > 1
	let url_fname = s:add_to_url(url_fname, 'page='.a:page)
    endif

    " Include retweets.
    let url_fname = s:add_to_url(url_fname, 'include_rts=true')

    " Include entities to get URL expansions for t.co.
    let url_fname = s:add_to_url(url_fname, 'include_entities=true')

    " Twitter API allows you to specify a username for user_timeline to
    " retrieve another user's timeline.
    if a:username != ''
	let url_fname = s:add_to_url(url_fname, 'screen_name='.a:username)
    endif

    " Support count parameter in favorites, friends, user, mentions, and retweet timelines.
    if a:tline_name == 'favorites' || a:tline_name == 'friends' || a:tline_name == 'user' || a:tline_name == 'replies' || a:tline_name == 'retweeted_to_me' || a:tline_name == 'retweeted_by_me'
	let tcount = s:get_count()
	if tcount > 0
	    let url_fname = s:add_to_url(url_fname, 'count='.tcount)
	endif
    endif

    let tl_name = a:tline_name == "replies" ? "mentions" : a:tline_name

    redraw
    echo "Sending" tl_name "timeline request to Twitter..."

    let url = s:get_api_root().(a:tline_name == 'favorites' ? '/' : "/statuses/").url_fname

    let [error, output] = s:run_curl_oauth(url, login, s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting Twitter ".tl_name." timeline: ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(0)
    let s:curbuffer = {}
    call s:show_timeline_xml(output, a:tline_name, a:username, a:page)
    let s:curbuffer.buftype = a:tline_name
    let s:curbuffer.user = a:username
    let s:curbuffer.list = ''
    let s:curbuffer.page = a:page
    redraw
    call s:save_buffer(0)

    let foruser = a:username == '' ? '' : ' for user '.a:username

    " Uppercase the first letter in the timeline name.
    echo substitute(tl_name, '^.', '\u&', '') "timeline updated".foruser."."
endfunction

" Retrieve a Twitter list timeline.
function! s:get_list_timeline(username, listname, page)

    let user = a:username
    if user == ''
	let user = s:get_twitvim_username()
	if user == ''
	    call s:errormsg('Twitter login not set. Please specify a username.')
	    return -1
	endif
    endif

    let url = s:get_api_root().'/lists/statuses.xml?slug='.a:listname.'&owner_screen_name='.user

    " Support pagination.
    if a:page > 1
	let url = s:add_to_url(url, 'page='.a:page)
    endif

    " Support count parameter.
    let tcount = s:get_count()
    if tcount > 0
	let url = s:add_to_url(url, 'per_page='.tcount)
	let url = s:add_to_url(url, 'count='.tcount)
    endif

    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    " Include retweets.
    let url = s:add_to_url(url, 'include_rts=true')

    redraw
    echo "Sending list timeline request to Twitter..."

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting Twitter list timeline: ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(0)
    let s:curbuffer = {}
    call s:show_timeline_xml(output, "list", user."/".a:listname, a:page)
    let s:curbuffer.buftype = "list"
    let s:curbuffer.user = user
    let s:curbuffer.list = a:listname
    let s:curbuffer.page = a:page
    redraw
    call s:save_buffer(0)

    echo "List timeline updated for ".user."/".a:listname
endfunction

" Show direct message sent or received by user. First argument should be 'sent'
" or 'received' depending on which timeline we are displaying.
function! s:show_dm_xml(sent_or_recv, timeline, page)
    let text = []

    "No status IDs in direct messages.
    let s:curbuffer.statuses = []
    let s:curbuffer.inreplyto = []

    let title = 'Direct messages '.a:sent_or_recv

    if a:page > 1
	let title .= ' (page '.a:page.')'
    endif

    let s:curbuffer.showheader = s:get_show_header()
    if s:curbuffer.showheader
	" Index of first dmid will be 3 to match line numbers in timeline
	" display.
	let s:curbuffer.dmids = [0, 0, 0]

	" The extra stars at the end are for the syntax highlighter to
	" recognize the title. Then the syntax highlighter hides the stars by
	" coloring them the same as the background. It is a bad hack.
	call add(text, title.'*')
	call add(text, repeat('=', s:mbstrlen(title)).'*')
    else
	" Index of first dmid will be 1 to match line numbers in timeline
	" display.
	let s:curbuffer.dmids = [0]
    endif

    for item in s:xml_get_all(a:timeline, 'direct_message')
	call add(s:curbuffer.dmids, s:xml_get_element(item, 'id'))

	let user = s:xml_get_element(item, a:sent_or_recv == 'sent' ? 'recipient_screen_name' : 'sender_screen_name')
	let mesg = s:get_status_text(item)
	let date = s:time_filter(s:xml_get_element(item, 'created_at'))

	call add(text, user.": ".s:convert_entity(mesg).' |'.date.'|')
    endfor

    call s:twitter_wintext(text, "timeline")
    let s:curbuffer.buffer = text
endfunction

" Get direct messages sent to or received by user.
function! s:Direct_Messages(mode, page)
    let sent = (a:mode == "dmsent")
    let s_or_r = (sent ? "sent" : "received")

    redraw
    echo "Sending direct messages ".s_or_r." timeline request to Twitter..."

    let url = s:get_api_root()."/direct_messages".(sent ? "/sent" : "").".xml"

    " Support pagination.
    let pagearg = ''
    if a:page > 1
	let url = s:add_to_url(url, 'page='.a:page)
    endif
    
    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    " Support count parameter.
    let tcount = s:get_count()
    if tcount > 0
	let url = s:add_to_url(url, 'count='.tcount)
    endif

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting Twitter direct messages ".s_or_r." timeline: ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(0)
    let s:curbuffer = {}
    call s:show_dm_xml(s_or_r, output, a:page)
    let s:curbuffer.buftype = a:mode
    let s:curbuffer.user = ''
    let s:curbuffer.list = ''
    let s:curbuffer.page = a:page
    redraw
    call s:save_buffer(0)
    echo "Direct messages ".s_or_r." timeline updated."
endfunction

" === Trends Code ===

let s:woeid_list = {}

" Get master list of WOEIDs from Twitter API.
function! s:get_woeids()
    if s:woeid_list != {}
	return s:woeid_list
    endif

    redraw
    echo "Retrieving list of WOEIDs..."

    let url = s:get_api_root().'/trends/available.xml'
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error retrieving list of WOEIDs: ".(errormsg != '' ? errormsg : error))
	return {}
    endif

    for location in s:xml_get_all(output, 'location')
	let name = s:xml_get_element(location, 'name')
	let woeid = s:xml_get_element(location, 'woeid')
	let placetype = s:xml_get_element(location, 'placeTypeName')
	let country = s:xml_get_element(location, 'country')

	if placetype == 'Supername'
	    let s:woeid_list[name] = { 'woeid' : woeid, 'towns' : {} }
	elseif placetype == 'Country' 
	    if !has_key(s:woeid_list, country)
		let s:woeid_list[country] = { 'towns' : {} }
	    endif
	    let s:woeid_list[country]['woeid'] = woeid
	elseif placetype == 'Town'
	    if !has_key(s:woeid_list, country)
		let s:woeid_list[country] = { 'towns' : {} }
	    endif
	    let s:woeid_list[country]['towns'][name] = { 'woeid' : woeid }
	else
	    call s:errormsg('Unknown location type "'.placetype.'".')
	    return {}
	endif
    endfor

    redraw
    echo "Retrieved list of WOEIDs."

    return s:woeid_list
endfunction

function! s:get_woeid_pagelen()
    let maxlen = &lines - 3
    if maxlen < 5
	call s:errormsg('Window is not tall enough for menu.')
	return -1
    endif
    return maxlen < 20 ? maxlen : 20
endfunction

function! s:comp_countries(a, b)
    if a:a == 'Worldwide'
	return -1
    elseif a:b == 'Worldwide'
	return 1
    elseif a:a == 'United States'
	return -1
    elseif a:b == 'United States'
	return 1
    elseif a:a == a:b
	return 0
    elseif a:a < a:b
	return -1
    else
	return 1
    endif
endfunction

function! s:get_country_list()
    return sort(keys(s:woeid_list), 's:comp_countries')
endfunction

function! s:get_town_list(country)
    return [ a:country ] + sort(keys(s:woeid_list[a:country]['towns']))
endfunction

function! s:get_woeid(country, town)
    if a:town == '' || a:town == a:country
	return s:woeid_list[a:country]['woeid']
    else
	return s:woeid_list[a:country]['towns'][a:town]['woeid']
    endif
endfunction

function! s:make_loc_menu(what, namelist, pagelen, indx)
    let sublist = a:namelist[a:indx : a:indx + a:pagelen - 1]
    let menu = [ 'Pick a '.a:what.':' ]
    let item_count = 0
    for name in sublist
	let item_count += 1
	call add(menu, printf('%2d', item_count).'. '.name)
    endfor
    if a:indx + a:pagelen < len(a:namelist)
	let item_count += 1
	call add(menu, printf('%2d', item_count).'. next page')
    endif
    if a:indx > 0
	let item_count += 1
	call add(menu, printf('%2d', item_count).'. previous page')
    endif
    return menu
endfunction

function! s:pick_woeid_town(country)
    let indx = 0
    let towns = s:get_town_list(a:country)
    let pagelen = s:get_woeid_pagelen()

    while 1
	let menu = s:make_loc_menu('location', towns, pagelen, indx)

	call inputsave()
	let input = inputlist(menu)
	call inputrestore()

	if input < 1 || input >= len(menu)
	    " Invalid input cancels the command.
	    return 0
	endif

	let select = menu[input][4:]

	if select == 'next page'
	    let indx += pagelen
	elseif select == 'previous page'
	    let indx -= pagelen
	    if indx < 0
		indx = 0
	    endif
	else
	    let g:twitvim_woeid = s:get_woeid(a:country, select)

	    redraw
	    echo 'Set trends region to '.select.' ('.g:twitvim_woeid.').'

	    return g:twitvim_woeid
	end
    endwhile
endfunction

" Allow the user to pick a WOEID for Trends from a list of WOEIDs.
function! s:pick_woeid()
    let indx = 0
    if s:get_woeids() == {}
	return -1
    endif
    let countries = s:get_country_list()
    let pagelen = s:get_woeid_pagelen()

    while 1
	let menu = s:make_loc_menu('country', countries, pagelen, indx)

	call inputsave()
	let input = inputlist(menu)
	call inputrestore()

	if input < 1 || input >= len(menu)
	    " Invalid input cancels the command.
	    return 0
	endif

	let select = menu[input][4:]

	if select == 'next page'
	    let indx += pagelen
	elseif select == 'previous page'
	    let indx -= pagelen
	    if indx < 0
		indx = 0
	    endif
	else
	    if s:woeid_list[select]['towns'] == {}
		let g:twitvim_woeid = s:get_woeid(select, '')

		redraw
		echo 'Set trends region to '.select.' ('.g:twitvim_woeid.').'

		return g:twitvim_woeid
	    else
		return s:pick_woeid_town(select)
	    end
	endif
    endwhile
endfunction

if !exists(":SetTrendLocationTwitter")
    command SetTrendLocationTwitter :call <SID>pick_woeid()
endif

function! s:show_trends_xml(timeline)
    let text = []

    let title = 'Trending topics'

    let s:curbuffer.showheader = s:get_show_header()
    if s:curbuffer.showheader
	call add(text, title.'*')
	call add(text, repeat('=', s:mbstrlen(title)).'*')
    endif

    for item in s:xml_get_all(a:timeline, 'trend')
	call add(text, s:convert_entity(item))
    endfor

    call s:twitter_wintext(text, "timeline")
    let s:curbuffer.buffer = text
endfunction

" Get trending topics.
function! s:Local_Trends()
    redraw
    echo "Getting trending topics from Twitter..."

    let url = s:get_api_root().'/trends/'.s:get_twitvim_woeid().'.xml'
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error retrieving trending topics: ".(errormsg != '' ? errormsg : error))
	return {}
    endif

    call s:save_buffer(0)
    let s:curbuffer = {}
    call s:show_trends_xml(output)
    let s:curbuffer.buftype = 'trends'
    let s:curbuffer.user = ''
    let s:curbuffer.list = ''
    let s:curbuffer.page = ''
    redraw
    call s:save_buffer(0)

    echo 'Trending topics retrieved.'
endfunction

if !exists(":TrendTwitter")
    command TrendTwitter :call <SID>Local_Trends()
endif

" === End of Trends Code ===

" Function to load a timeline from the given parameters. For use by refresh and
" next/prev pagination commands.
function! s:load_timeline(buftype, user, list, page)
    if a:buftype == "public" || a:buftype == "friends" || a:buftype == "user" || a:buftype == "replies" || a:buftype == "retweeted_by_me" || a:buftype == "retweeted_to_me" || a:buftype == 'favorites'
	call s:get_timeline(a:buftype, a:user, a:page)
    elseif a:buftype == "list"
	call s:get_list_timeline(a:user, a:list, a:page)
    elseif a:buftype == "dmsent" || a:buftype == "dmrecv"
	call s:Direct_Messages(a:buftype, a:page)
    elseif a:buftype == "search"
	call s:get_summize(a:user, a:page)
    elseif a:buftype == 'trends'
	call s:Local_Trends()
    endif
endfunction

" Refresh the timeline buffer.
function! s:RefreshTimeline()
    if s:curbuffer != {}
	call s:load_timeline(s:curbuffer.buftype, s:curbuffer.user, s:curbuffer.list, s:curbuffer.page)
    else
	call s:warnmsg("No timeline buffer to refresh.")
    endif
endfunction

" Go to next page in timeline.
function! s:NextPageTimeline()
    if s:curbuffer != {}
	call s:load_timeline(s:curbuffer.buftype, s:curbuffer.user, s:curbuffer.list, s:curbuffer.page + 1)
    else
	call s:warnmsg("No timeline buffer.")
    endif
endfunction

" Go to previous page in timeline.
function! s:PrevPageTimeline()
    if s:curbuffer != {}
	if s:curbuffer.page <= 1
	    call s:warnmsg("Timeline is already on first page.")
	else
	    call s:load_timeline(s:curbuffer.buftype, s:curbuffer.user, s:curbuffer.list, s:curbuffer.page - 1)
	endif
    else
	call s:warnmsg("No timeline buffer.")
    endif
endfunction

" Get a Twitter list. Need to do a little fiddling because the 
" username argument is optional.
function! s:DoList(page, arg1, ...)
    let user = ''
    let list = a:arg1
    if a:0 > 0
	let user = a:arg1
	let list = a:1
    endif
    call s:get_list_timeline(user, list, a:page)
endfunction

if !exists(":PublicTwitter")
    command PublicTwitter :call <SID>get_timeline("public", '', 1)
endif
if !exists(":FriendsTwitter")
    command -count=1 FriendsTwitter :call <SID>get_timeline("friends", '', <count>)
endif
if !exists(":UserTwitter")
    command -range=1 -nargs=? UserTwitter :call <SID>get_timeline("user", <q-args>, <count>)
endif
if !exists(":MentionsTwitter")
    command -count=1 MentionsTwitter :call <SID>get_timeline("replies", '', <count>)
endif
if !exists(":RepliesTwitter")
    command -count=1 RepliesTwitter :call <SID>get_timeline("replies", '', <count>)
endif
if !exists(":DMTwitter")
    command -count=1 DMTwitter :call <SID>Direct_Messages("dmrecv", <count>)
endif
if !exists(":DMSentTwitter")
    command -count=1 DMSentTwitter :call <SID>Direct_Messages("dmsent", <count>)
endif
if !exists(":ListTwitter")
    command -range=1 -nargs=+ ListTwitter :call <SID>DoList(<count>, <f-args>)
endif
if !exists(":RetweetedByMeTwitter")
    command -count=1 RetweetedByMeTwitter :call <SID>get_timeline("retweeted_by_me", '', <count>)
endif
if !exists(":RetweetedToMeTwitter")
    command -count=1 RetweetedToMeTwitter :call <SID>get_timeline("retweeted_to_me", '', <count>)
endif
if !exists(":FavTwitter")
    command -count=1 FavTwitter :call <SID>get_timeline('favorites', '', <count>)
endif

nnoremenu Plugin.TwitVim.-Sep1- :
nnoremenu Plugin.TwitVim.&Friends\ Timeline :call <SID>get_timeline("friends", '', 1)<cr>
nnoremenu Plugin.TwitVim.&User\ Timeline :call <SID>get_timeline("user", '', 1)<cr>
nnoremenu Plugin.TwitVim.&Mentions\ Timeline :call <SID>get_timeline("replies", '', 1)<cr>
nnoremenu Plugin.TwitVim.&Direct\ Messages :call <SID>Direct_Messages("dmrecv", 1)<cr>
nnoremenu Plugin.TwitVim.Direct\ Messages\ &Sent :call <SID>Direct_Messages("dmsent", 1)<cr>
nnoremenu Plugin.TwitVim.&Public\ Timeline :call <SID>get_timeline("public", '', 1)<cr>

nnoremenu Plugin.TwitVim.Retweeted\ &By\ Me :call <SID>get_timeline("retweeted_by_me", '', 1)<cr>
nnoremenu Plugin.TwitVim.Retweeted\ &To\ Me :call <SID>get_timeline("retweeted_to_me", '', 1)<cr>
nnoremenu Plugin.TwitVim.Fa&vorites :call <SID>get_timeline("favorites", '', 1)<cr>

if !exists(":RefreshTwitter")
    command RefreshTwitter :call <SID>RefreshTimeline()
endif
if !exists(":NextTwitter")
    command NextTwitter :call <SID>NextPageTimeline()
endif
if !exists(":PreviousTwitter")
    command PreviousTwitter :call <SID>PrevPageTimeline()
endif

if !exists(":SetLoginTwitter")
    command SetLoginTwitter :call <SID>prompt_twitvim_login()
endif
if !exists(":ResetLoginTwitter")
    command ResetLoginTwitter :call <SID>reset_twitvim_login()
endif
if !exists(':SwitchLoginTwitter')
    command -nargs=? -complete=custom,<SID>name_list_tokens SwitchLoginTwitter :call <SID>switch_twitvim_login(<q-args>)
endif

nnoremenu Plugin.TwitVim.-Sep2- :
nnoremenu Plugin.TwitVim.Set\ Twitter\ Login :call <SID>prompt_twitvim_login()<cr>
nnoremenu Plugin.TwitVim.Reset\ Twitter\ Login :call <SID>reset_twitvim_login()<cr>


" Send a direct message.
function! s:do_send_dm(user, mesg)
    let mesg = a:mesg

    " Remove trailing newline. You see that when you visual-select an entire
    " line. Don't let it count towards the message length.
    let mesg = substitute(mesg, '\n$', '', "")

    " Convert internal newlines to spaces.
    let mesg = substitute(mesg, '\n', ' ', "g")

    let mesglen = s:mbstrlen(mesg)

    " Check message length. Note that the message length should be checked
    " before URL-encoding the special characters because URL-encoding increases
    " the string length.
    if mesglen > s:char_limit
	call s:warnmsg("Your message has ".(mesglen - s:char_limit)." too many characters. It was not sent.")
    elseif mesglen < 1
	call s:warnmsg("Your message was empty. It was not sent.")
    else
	redraw
	echo "Sending message to ".a:user."..."

	let url = s:get_api_root()."/direct_messages/new.xml"
	let parms = { "source" : "twitvim", "user" : a:user, "text" : mesg }

	let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)

	if error != ''
	    let errormsg = s:xml_get_element(output, 'error')
	    call s:errormsg("Error sending your message: ".(errormsg != '' ? errormsg : error))
	else
	    redraw
	    echo "Your message was sent to ".a:user.". You used ".mesglen." characters."
	endif
    endif
endfunction

" Send a direct message. Prompt user for message if not given.
function! s:send_dm(user, mesg)
    if a:user == ""
	call s:warnmsg("No recipient specified for direct message.")
	return
    endif

    let mesg = a:mesg
    if mesg == ""
	call inputsave()
	let mesg = input("DM ".a:user.": ")
	call inputrestore()
    endif

    if mesg == ""
	call s:warnmsg("Your message was empty. It was not sent.")
	return
    endif

    call s:do_send_dm(a:user, mesg)
endfunction

if !exists(":SendDMTwitter")
    command -nargs=1 SendDMTwitter :call <SID>send_dm(<q-args>, '')
endif

" Call Twitter API to get rate limit information.
function! s:get_rate_limit()
    redraw
    echo "Querying Twitter for rate limit information..."

    let url = s:get_api_root()."/account/rate_limit_status.xml"
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting rate limit info: ".(errormsg != '' ? errormsg : error))
	return
    endif

    let remaining = s:xml_get_element(output, 'remaining-hits')
    let resettime = s:time_filter(s:xml_get_element(output, 'reset-time'))
    let limit = s:xml_get_element(output, 'hourly-limit')

    redraw
    echo "Rate limit: ".limit." Remaining: ".remaining." Reset at: ".resettime
endfunction

if !exists(":RateLimitTwitter")
    command RateLimitTwitter :call <SID>get_rate_limit()
endif

" Set location field on Twitter profile.
function! s:set_location(loc)
    redraw
    echo "Setting location on Twitter profile..."

    let url = s:get_api_root()."/account/update_profile.xml"
    let parms = { 'location' : a:loc }

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error setting location: ".(errormsg != '' ? errormsg : error))
	return
    endif

    redraw
    echo "Location: ".s:xml_get_element(output, 'location')
endfunction

if !exists(":LocationTwitter")
    command -nargs=+ LocationTwitter :call <SID>set_location(<q-args>)
endif


" Start following a user.
function! s:follow_user(user)
    redraw
    echo "Following user ".a:user."..."

    let parms = {}
    let parms["screen_name"] = a:user

    let url = s:get_api_root().'/friendships/create.xml'

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error following user: ".(errormsg != '' ? errormsg : error))
    else
	let protected = s:xml_get_element(output, 'protected')
	redraw
	if protected == "true"
	    echo "Made request to follow ".a:user."'s protected timeline."
	else
	    echo "Now following ".a:user."'s timeline."
	endif
    endif
endfunction

if !exists(":FollowTwitter")
    command -nargs=1 FollowTwitter :call <SID>follow_user(<q-args>)
endif


" Stop following a user.
function! s:unfollow_user(user)
    redraw
    echo "Unfollowing user ".a:user."..."

    let parms = {}
    let parms["screen_name"] = a:user

    let url = s:get_api_root()."/friendships/destroy.xml"

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error unfollowing user: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	echo "Stopped following ".a:user."'s timeline."
    endif
endfunction

if !exists(":UnfollowTwitter")
    command -nargs=1 UnfollowTwitter :call <SID>unfollow_user(<q-args>)
endif


" Block a user.
function! s:block_user(user, unblock)
    redraw
    echo (a:unblock ? "Unblocking" : "Blocking")." user ".a:user."..."

    let parms = {}
    let parms["screen_name"] = a:user

    let url = s:get_api_root()."/blocks/".(a:unblock ? "destroy" : "create").".xml"

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error ".(a:unblock ? "unblocking" : "blocking")." user: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	echo "User ".a:user." is now ".(a:unblock ? "unblocked" : "blocked")."."
    endif
endfunction

if !exists(":BlockTwitter")
    command -nargs=1 BlockTwitter :call <SID>block_user(<q-args>, 0)
endif
if !exists(":UnblockTwitter")
    command -nargs=1 UnblockTwitter :call <SID>block_user(<q-args>, 1)
endif


" Report user for spam.
function! s:report_spam(user)
    redraw
    echo "Reporting ".a:user." for spam..."

    let parms = {}
    let parms["screen_name"] = a:user

    let url = s:get_api_root()."/report_spam.xml"

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error reporting user for spam: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	echo "Reported user ".a:user." for spam."
    endif
endfunction

if !exists(":ReportSpamTwitter")
    command -nargs=1 ReportSpamTwitter :call <SID>report_spam(<q-args>)
endif


" Enable/disable retweets from user.
function! s:enable_retweets(user, enable)
    if a:enable
	let msg1 = "Enabling"
	let msg2 = "Enabled"
    else
	let msg1 = "Disabling"
	let msg2 = "Disabled"
    endif
    let msg3 = substitute(msg1, '^.', '\l&', '')

    redraw
    echo msg1." retweets for user ".a:user."..."

    let url = s:get_api_root()."/friendships/update.xml"

    let parms = {}
    let parms['screen_name'] = a:user
    let parms['retweets'] = a:enable ? 'true' : 'false'

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error ".msg3." retweets from user: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	echo msg2." retweets from user ".a:user."."
    endif
endfunction

if !exists(":EnableRetweetsTwitter")
    command -nargs=1 EnableRetweetsTwitter :call <SID>enable_retweets(<q-args>, 1)
endif
if !exists(":DisableRetweetsTwitter")
    command -nargs=1 DisableRetweetsTwitter :call <SID>enable_retweets(<q-args>, 0)
endif


" Add user to a list or remove user from a list.
function! s:add_to_list(remove, listname, username)
    let user = s:get_twitvim_username()
    if user == ''
	call s:errormsg('Twitter login not set. Please specify a username.')
	return -1
    endif

    redraw
    if a:remove
	echo "Removing ".a:username." from list ".a:listname."..."
	let verb = 'destroy'
    else
	echo "Adding ".a:username." to list ".a:listname."..."
	let verb = 'create'
    endif

    let parms = {}
    let parms['slug'] = a:listname
    let parms['owner_screen_name'] = user
    let parms['screen_name'] = a:username

    let url = s:get_api_root().'/lists/members/'.verb.'.xml'

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error ".(a:remove ? "removing user from" : "adding user to")." list: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	if a:remove
	    echo "Removed ".a:username." from list ".a:listname."."
	else
	    echo "Added ".a:username." to list ".a:listname."."
	endif
    endif
endfunction

function! s:do_add_to_list(arg1, ...)
    if a:0 == 0
	call s:errormsg("Syntax: :AddToListTwitter listname username")
    else
	call s:add_to_list(0, a:arg1, a:1)
    endif
endfunction

if !exists(":AddToListTwitter")
    command -nargs=+ AddToListTwitter :call <SID>do_add_to_list(<f-args>)
endif


function! s:do_remove_from_list(arg1, ...)
    if a:0 == 0
	call s:errormsg("Syntax: :RemoveFromListTwitter listname username")
    else
	call s:add_to_list(1, a:arg1, a:1)
    endif
endfunction

if !exists(":RemoveFromListTwitter")
    command -nargs=+ RemoveFromListTwitter :call <SID>do_remove_from_list(<f-args>)
endif


let s:user_winname = "TwitterInfo_".localtime()

" Convert true/false into yes/no.
function! s:yesorno(s)
    let s = tolower(a:s)
    if s == "true" || s == "yes"
	return "yes"
    elseif s == "false" || s == "no" || s == ""
	return "no"
    else
	return s
    endif
endfunction

" Process/format the user information.
function! s:format_user_info(output, fship_output)
    let text = []
    let output = a:output
    let fship_output = a:fship_output

    let name = s:convert_entity(s:xml_get_element(output, 'name'))
    let screen = s:xml_get_element(output, 'screen_name')
    call add(text, 'Name: '.screen.' ('.name.')')

    call add(text, 'Location: '.s:convert_entity(s:xml_get_element(output, 'location')))
    call add(text, 'Website: '.s:xml_get_element(output, 'url'))
    call add(text, 'Bio: '.s:convert_entity(s:xml_get_element(output, 'description')))
    call add(text, '')
    call add(text, 'Following: '.s:xml_get_element(output, 'friends_count'))
    call add(text, 'Followers: '.s:xml_get_element(output, 'followers_count'))
    call add(text, 'Listed: '.s:xml_get_element(output, 'listed_count'))
    call add(text, 'Updates: '.s:xml_get_element(output, 'statuses_count'))
    call add(text, 'Favorites: '.s:xml_get_element(output, 'favourites_count'))
    call add(text, '')

    call add(text, 'Protected: '.s:yesorno(s:xml_get_element(output, 'protected')))

    let follow_req = s:xml_get_element(output, 'follow_request_sent')
    let following_str = follow_req == 'true' ? 'Follow request sent' : s:yesorno(s:xml_get_element(output, 'following'))
    call add(text, 'Following: '.following_str)

    let fship_source = s:xml_get_element(fship_output, 'source')
    call add(text, 'Followed_by: '.s:yesorno(s:xml_get_element(fship_source, 'followed_by')))
    call add(text, 'Blocked: '.s:yesorno(s:xml_get_element(fship_source, 'blocking')))
    call add(text, 'Marked_spam: '.s:yesorno(s:xml_get_element(fship_source, 'marked_spam')))
    call add(text, 'Retweets: '.s:yesorno(s:xml_get_element(fship_source, 'want_retweets')))
    call add(text, 'Notifications: '.s:yesorno(s:xml_get_element(fship_source, 'notifications_enabled')))

    call add(text, '')

    let usernode = s:xml_remove_elements(output, 'status')
    let startdate = s:time_filter(s:xml_get_element(usernode, 'created_at'))
    call add(text, 'Started: |'.startdate.'|')
    let timezone = s:convert_entity(s:xml_get_element(usernode, 'time_zone'))
    call add(text, 'Timezone: '.timezone)
    call add(text, '')

    let statusnode = s:xml_get_element(output, 'status')
    if statusnode != ""
	let status = s:get_status_text(statusnode)
	let pubdate = s:time_filter(s:xml_get_element(statusnode, 'created_at'))
	call add(text, 'Status: '.s:convert_entity(status).' |'.pubdate.'|')
    endif

    " call add(text, fship_output)

    return text
endfunction

" Call Twitter API to get user's info.
function! s:get_user_info(username)
    let user = a:username
    if user == ''
	let user = s:get_twitvim_username()
	if user == ''
	    call s:errormsg('Twitter login not set. Please specify a username.')
	    return
	endif
    endif

    redraw
    echo "Querying Twitter for user information..."

    let url = s:get_api_root()."/users/show.xml?screen_name=".user

    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting user info: ".(errormsg != '' ? errormsg : error))
	return
    endif

    let url = s:get_api_root()."/friendships/show.xml?target_screen_name=".user
    let [error, fship_output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(fship_output, 'error')
	call s:errormsg("Error getting friendship info: ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_user_info(output, fship_output), "userinfo")
    let s:infobuffer.buftype = 'profile'
    let s:infobuffer.next_cursor = 0
    let s:infobuffer.prev_cursor = 0
    let s:infobuffer.cursor = 0
    let s:infobuffer.user = user
    let s:infobuffer.list = ''
    redraw
    call s:save_buffer(1)
    echo "User information retrieved."
endfunction

if !exists(":ProfileTwitter")
    command -nargs=? ProfileTwitter :call <SID>get_user_info(<q-args>)
endif

" Format the list information.
function! s:format_list_info(output)
    let text = []
    let output = a:output
    call add(text, 'Name: '.s:convert_entity(s:xml_get_element(output, 'full_name')))
    call add(text, 'Description: '.s:convert_entity(s:xml_get_element(output, 'description')))
    call add(text, '')
    call add(text, 'Members: '.s:xml_get_element(output, 'member_count'))
    call add(text, 'Subscribers: '.s:xml_get_element(output, 'subscriber_count'))
    call add(text, '')
    call add(text, 'Following: '.s:yesorno(s:xml_get_element(output, 'following')))
    call add(text, 'Mode: '.s:xml_get_element(output, 'mode'))
    return text
endfunction

" Call Twitter API to get list info.
function! s:get_list_info(username, listname)
    let user = a:username
    if user == ''
	let user = s:get_twitvim_username()
	if user == ''
	    call s:errormsg('Twitter login not set. Please specify a username.')
	    return
	endif
    endif

    let list = a:listname

    redraw
    echo 'Querying Twitter for information on list '.user.'/'.list.'...'

    let url = s:get_api_root().'/lists/show.xml?slug='.list.'&owner_screen_name='.user
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg('Error getting information on list '.user.'/'.list.': '.(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_list_info(output), "userinfo")
    let s:infobuffer.buftype = 'listinfo'
    let s:infobuffer.next_cursor = 0
    let s:infobuffer.prev_cursor = 0
    let s:infobuffer.cursor = 0
    let s:infobuffer.user = user
    let s:infobuffer.list = list
    redraw
    call s:save_buffer(1)
    echo 'List information retrieved.'
endfunction

" Get info on a Twitter list. Need to do a little fiddling because the username
" argument is optional.
function! s:DoListInfo(arg1, ...)
    let user = ''
    let list = a:arg1
    if a:0 > 0
	let user = a:arg1
	let list = a:1
    endif
    call s:get_list_info(user, list)
endfunction

if !exists(":ListInfoTwitter")
    command -nargs=+ ListInfoTwitter :call <SID>DoListInfo(<f-args>)
endif

" Format a list of users, e.g. friends/followers list.
function! s:format_user_list(output, title, show_following)
    let text = []

    let showheader = s:get_show_header()
    if showheader
	" The extra stars at the end are for the syntax highlighter to
	" recognize the title. Then the syntax highlighter hides the stars by
	" coloring them the same as the background. It is a bad hack.
	call add(text, a:title.'*')
	call add(text, repeat('=', s:mbstrlen(a:title)).'*')
    endif

    for user in s:xml_get_all(a:output, 'user')
	let following_str = ''
	if a:show_following
	    let following = s:xml_get_element(user, 'following')
	    if following == 'true'
		let following_str = ' Following'
	    else
		let follow_req = s:xml_get_element(user, 'follow_request_sent')
		let following_str = follow_req == 'true' ? ' Follow request sent' : ' Not following'
	    endif
	endif

	let name = s:convert_entity(s:xml_get_element(user, 'name'))
	let screen = s:xml_get_element(user, 'screen_name')
	let location = s:convert_entity(s:xml_get_element(user, 'location'))
	let slocation = location == '' ? '' : '|'.location
	call add(text, 'Name: '.screen.' ('.name.slocation.')'.following_str)

	let desc = s:xml_get_element(user, 'description')
	if desc != ''
	    call add(text, 'Bio: '.s:convert_entity(desc))
	endif

	let statusnode = s:xml_get_element(user, 'status')
	if statusnode != ""
	    let status = s:get_status_text(statusnode)
	    let pubdate = s:time_filter(s:xml_get_element(statusnode, 'created_at'))
	    call add(text, 'Status: '.s:convert_entity(status).' |'.pubdate.'|')
	endif

	call add(text, '')
    endfor
    return text
endfunction

" Call Twitter API to get list of friends/followers IDs.
function! s:get_friends_ids_2(cursor, user, followers)
    let what = a:followers ? 'followers IDs' : 'friends IDs'
    if a:user != ''
	let what .= ' of '.a:user
    endif

    let query = '/' . (a:followers ? 'followers' : 'friends') . '/ids.xml'

    redraw
    echo 'Querying Twitter for '.what.'...'

    let url = s:get_api_root().query.'?cursor='.a:cursor
    if a:user != ''
	let url = s:add_to_url(url, 'screen_name='.a:user)
    endif

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg('Error getting '.what.': '.(errormsg != '' ? errormsg : error))
	return {}
    endif
    let result = {}
    let result.next_cursor = s:xml_get_element(output, 'next_cursor')
    let result.prev_cursor = s:xml_get_element(output, 'previous_cursor')
    let result.ids = s:xml_get_all(output, 'id')
    return result
endfunction

" Call Twitter API to look up friends info from list of IDs.
function! s:get_friends_info_2(ids, index)
    redraw
    echo 'Querying Twitter for friends/followers info...'

    let idslice = a:ids[a:index : a:index + 99]
    let url = s:get_api_root().'/users/lookup.xml?include_entities=true&user_id='.join(idslice, ',')

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg('Error getting friends/followers info: '.(errormsg != '' ? errormsg : error))
	return ''
    endif

    return output
endfunction

" Call Twitter API to get friends or followers list.
function! s:get_friends_2(cursor, ids, next_cursor, prev_cursor, index, user, followers)
    if a:ids == []
	let result = s:get_friends_ids_2(a:cursor, a:user, a:followers)
	if result == {}
	    return
	endif
	let ids = result.ids
	let next_cursor = result.next_cursor
	let prev_cursor = result.prev_cursor
	if a:index < 0
	    " If user is paging backwards, we want the last 100 IDs in the
	    " list.
	    let index = len(ids) - 100
	    if index < 0
		let index = 0
	    endif
	else
	    let index = 0
	endif
    else
	let ids = a:ids
	let next_cursor = a:next_cursor
	let prev_cursor = a:prev_cursor
	let index = a:index
    endif

    let output = s:get_friends_info_2(ids, index)
    if output == ''
	return
    endif

    let title = a:followers ? 'Followers list' : 'Friends list'
    if a:user != ''
	let title .= ' of '.a:user
    endif

    let buftype = a:followers ? 'followers' : 'friends'

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_user_list(output, title, a:followers || a:user != ''), "userinfo")
    let s:infobuffer.buftype = buftype
    let s:infobuffer.next_cursor = next_cursor
    let s:infobuffer.prev_cursor = prev_cursor
    let s:infobuffer.cursor = a:cursor
    let s:infobuffer.user = a:user
    let s:infobuffer.list = ''

    let s:infobuffer.flist = ids
    let s:infobuffer.findex = index

    redraw
    call s:save_buffer(1)
    echo title.' retrieved.'
endfunction

" Call Twitter API to get friends or followers list.
function! s:get_friends(cursor, user, followers)
    if a:followers
	let buftype = 'followers'
	let query = '/statuses/followers.xml'
	if a:user != ''
	    let what = 'followers list of '.a:user
	    let title = 'People following '.a:user
	else
	    let what = 'followers list'
	    let title = 'People following you'
	endif
    else
	let buftype = 'friends'
	let query = '/statuses/friends.xml'
	if a:user != ''
	    let what = 'friends list of '.a:user
	    let title = 'People '.a:user.' is following'
	else
	    let what = 'friends list'
	    let title = "People you're following"
	endif
    endif

    redraw
    echo "Querying Twitter for ".what."..."

    let url = s:add_to_url(s:get_api_root().query, 'cursor='.a:cursor)
    if a:user != ''
	let url = s:add_to_url(url, 'screen_name='.a:user)
    endif

    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting ".what.": ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_user_list(output, title, a:followers || a:user != ''), "userinfo")
    let s:infobuffer.buftype = buftype
    let s:infobuffer.next_cursor = s:xml_get_element(output, 'next_cursor')
    let s:infobuffer.prev_cursor = s:xml_get_element(output, 'previous_cursor')
    let s:infobuffer.cursor = a:cursor
    let s:infobuffer.user = a:user
    let s:infobuffer.list = ''
    redraw
    call s:save_buffer(1)
    echo substitute(what,'^.','\u&','') 'retrieved.'
endfunction

" Call Twitter API to get members or subscribers of list.
function! s:get_list_members(cursor, user, list, subscribers)
    let user = a:user
    if user == ''
	let user = s:get_twitvim_username()
	if user == ''
	    call s:errormsg('Twitter login not set. Please specify a username.')
	    return
	endif
    endif

    if a:subscribers
	let item = "list subscribers"
	let query = "/subscribers"
	let buftype = "listsubs"
	let title = 'Subscribers to list '.user.'/'.a:list
    else
	let item = "list members"
	let query = "/members"
	let buftype = "listmembers"
	let title = 'Members of list '.user.'/'.a:list
    endif

    redraw
    echo "Querying Twitter for ".item."..."

    let url = s:get_api_root().'/lists'.query.'.xml?cursor='.a:cursor.'&slug='.a:list.'&owner_screen_name='.user

    " Include entities to get URL expansions for t.co.
    let url = s:add_to_url(url, 'include_entities=true')

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting ".item.": ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_user_list(output, title, 1), 'userinfo')
    let s:infobuffer.buftype = buftype
    let s:infobuffer.next_cursor = s:xml_get_element(output, 'next_cursor')
    let s:infobuffer.prev_cursor = s:xml_get_element(output, 'previous_cursor')
    let s:infobuffer.cursor = a:cursor
    let s:infobuffer.user = user
    let s:infobuffer.list = a:list
    redraw
    call s:save_buffer(1)
    echo "Retrieved ".item."."
endfunction

" Get Twitter list members. Need to do a little fiddling because the 
" username argument is optional.
function! s:DoListMembers(subscribers, arg1, ...)
    let user = ''
    let list = a:arg1
    if a:0 > 0
	let user = a:arg1
	let list = a:1
    endif
    call s:get_list_members(-1, user, list, a:subscribers)
endfunction

" Format a list of lists, e.g. user's list memberships or list subscriptions.
function! s:format_list_list(output, title)
    let text = []

    let showheader = s:get_show_header()
    if showheader
	" The extra stars at the end are for the syntax highlighter to
	" recognize the title. Then the syntax highlighter hides the stars by
	" coloring them the same as the background. It is a bad hack.
	call add(text, a:title.'*')
	call add(text, repeat('=', s:mbstrlen(a:title)).'*')
    endif

    for list in s:xml_get_all(a:output, 'list')
	let name = s:xml_get_element(list, 'full_name')
	let following = s:xml_get_element(list, 'member_count')
	let followers = s:xml_get_element(list, 'subscriber_count')
	call add(text, 'List: '.name.' (Following: '.following.' Followers: '.followers.')')
	let desc = s:convert_entity(s:xml_get_element(list, 'description'))
	if desc != ""
	    call add(text, 'Desc: '.desc)
	endif
	call add(text, '')
    endfor
    return text
endfunction

" Call Twitter API to get a user's lists, list memberships, or list subscriptions.
function! s:get_user_lists(cursor, user, what)
    let user = a:user
    let titlename = user
    if user == ''
	let titlename = 'you'
    endif
    if a:what == "owned"
	let item = "lists"
	let query = "lists"
	let title = "Lists owned by ".titlename
	let buftype = 'userlists'
    elseif a:what == "memberships"
	let item = "list memberships"
	let query = "lists/memberships"
	let title = "Lists following ".titlename
	let buftype = 'userlistmem'
    else
	let item = "list subscriptions"
	let query = "lists/subscriptions"
	let title = "Lists followed by ".titlename
	let buftype = 'userlistsubs'
    endif

    redraw
    echo "Querying Twitter for user's ".item."..."

    let url = s:get_api_root().'/'.query.'.xml?cursor='.a:cursor
    if user != ''
	let url = s:add_to_url(url, 'screen_name='.user)
    endif
    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error getting user's ".item.": ".(errormsg != '' ? errormsg : error))
	return
    endif

    call s:save_buffer(1)
    let s:infobuffer = {}
    call s:twitter_wintext(s:format_list_list(output, title), 'userinfo')
    let s:infobuffer.buftype = buftype
    let s:infobuffer.next_cursor = s:xml_get_element(output, 'next_cursor')
    let s:infobuffer.prev_cursor = s:xml_get_element(output, 'previous_cursor')
    let s:infobuffer.cursor = a:cursor
    let s:infobuffer.user = user
    let s:infobuffer.list = ''
    redraw
    call s:save_buffer(1)
    echo "User's ".item." retrieved."
endfunction

" Function to load previous or next friends/followers info page.
" For use by next/prev pagination commands.
function! s:load_prevnext_friends_info_2(buftype, infobuffer, previous)
    if a:previous
	if a:infobuffer.findex == 0
	    if a:infobuffer.prev_cursor == 0
		call s:warnmsg('No previous page in info buffer.')
		return
	    endif
	    let cursor = a:infobuffer.prev_cursor
	    let ids = []
	    let next_cursor = 0
	    let prev_cursor = 0

	    " This tells s:get_friends_2() that we are paging backwards so
	    " it'll display the last 100 items in the new ID list.
	    let index = -1 
	else
	    let cursor = a:infobuffer.cursor
	    let ids = a:infobuffer.flist
	    let next_cursor = a:infobuffer.next_cursor
	    let prev_cursor = a:infobuffer.prev_cursor
	    let index = a:infobuffer.findex - 100
	    if index < 0
		let index = 0
	    endif
	endif
    else
	let nextindex = a:infobuffer.findex + 100
	if nextindex >= len(a:infobuffer.flist)
	    if a:infobuffer.next_cursor == 0
		call s:warnmsg('No next page in info buffer.')
		return
	    endif
	    let cursor = a:infobuffer.next_cursor
	    let ids = []
	    let next_cursor = 0
	    let prev_cursor = 0
	    let index = 0
	else
	    let cursor = a:infobuffer.cursor
	    let ids = a:infobuffer.flist
	    let next_cursor = a:infobuffer.next_cursor
	    let prev_cursor = a:infobuffer.prev_cursor
	    let index = nextindex
	endif
    endif

    call s:get_friends_2(cursor, ids, next_cursor, prev_cursor, index, a:infobuffer.user, a:buftype == 'followers')
endfunction

" Function to load an info buffer from the given parameters.
" For use by next/prev pagination commands.
function! s:load_info(buftype, cursor, user, list)
    if a:buftype == "friends"
	call s:get_friends(a:cursor, a:user, 0)
    elseif a:buftype == "followers"
	call s:get_friends(a:cursor, a:user, 1)
    elseif a:buftype == "listmembers"
	call s:get_list_members(a:cursor, a:user, a:list, 0)
    elseif a:buftype == "listsubs"
	call s:get_list_members(a:cursor, a:user, a:list, 1)
    elseif a:buftype == "userlists"
	call s:get_user_lists(a:cursor, a:user, 'owned')
    elseif a:buftype == "userlistmem"
	call s:get_user_lists(a:cursor, a:user, 'memberships')
    elseif a:buftype == "userlistsubs"
	call s:get_user_lists(a:cursor, a:user, 'subscriptions')
    elseif a:buftype == "profile"
	call s:get_user_info(a:user)
    elseif a:buftype == 'listinfo'
	call s:get_list_info(a:user, a:list)
    endif
endfunction

" Go to next page in info buffer.
function! s:NextPageInfo()
    if s:infobuffer != {}
" 	if s:infobuffer.buftype == 'friends' || s:infobuffer.buftype == 'followers'
" 	    call s:load_prevnext_friends_info_2(s:infobuffer.buftype, s:infobuffer, 0)
" 	    return
" 	endif
	if s:infobuffer.next_cursor == 0
	    call s:warnmsg("No next page in info buffer.")
	else
	    call s:load_info(s:infobuffer.buftype, s:infobuffer.next_cursor, s:infobuffer.user, s:infobuffer.list)
	endif
    else
	call s:warnmsg("No info buffer.")
    endif
endfunction

" Go to previous page in info buffer.
function! s:PrevPageInfo()
    if s:infobuffer != {}
" 	if s:infobuffer.buftype == 'friends' || s:infobuffer.buftype == 'followers'
" 	    call s:load_prevnext_friends_info_2(s:infobuffer.buftype, s:infobuffer, 1)
" 	    return
" 	endif
	if s:infobuffer.prev_cursor == 0
	    call s:warnmsg("No previous page in info buffer.")
	else
	    call s:load_info(s:infobuffer.buftype, s:infobuffer.prev_cursor, s:infobuffer.user, s:infobuffer.list)
	endif
    else
	call s:warnmsg("No info buffer.")
    endif
endfunction

" Refresh info buffer.
function! s:RefreshInfo()
    if s:infobuffer != {}
" 	if s:infobuffer.buftype == 'friends' || s:infobuffer.buftype == 'followers'
" 	    call s:get_friends_2(s:infobuffer.cursor, s:infobuffer.flist, s:infobuffer.next_cursor, s:infobuffer.prev_cursor, s:infobuffer.findex, s:infobuffer.user, s:infobuffer.buftype == 'followers')
" 	    return
" 	endif
	call s:load_info(s:infobuffer.buftype, s:infobuffer.cursor, s:infobuffer.user, s:infobuffer.list)
    else
	call s:warnmsg("No info buffer.")
    endif
endfunction

if !exists(":RefreshInfoTwitter")
    command RefreshInfoTwitter :call <SID>RefreshInfo()
endif
if !exists(":NextInfoTwitter")
    command NextInfoTwitter :call <SID>NextPageInfo()
endif
if !exists(":PreviousInfoTwitter")
    command PreviousInfoTwitter :call <SID>PrevPageInfo()
endif

if !exists(":FollowingTwitter")
    command -nargs=? FollowingTwitter :call <SID>get_friends(-1, <q-args>, 0)
"     command -nargs=? FollowingTwitter :call <SID>get_friends_2(-1, [], 0, 0, 0, <q-args>, 0)
endif
if !exists(":FollowersTwitter")
    command -nargs=? FollowersTwitter :call <SID>get_friends(-1, <q-args>, 1)
"     command -nargs=? FollowersTwitter :call <SID>get_friends_2(-1, [], 0, 0, 0, <q-args>, 1)
endif
if !exists(":MembersOfListTwitter")
    command -nargs=+ MembersOfListTwitter :call <SID>DoListMembers(0, <f-args>)
endif
if !exists(":SubsOfListTwitter")
    command -nargs=+ SubsOfListTwitter :call <SID>DoListMembers(1, <f-args>)
endif
if !exists(":OwnedListsTwitter")
    command -nargs=? OwnedListsTwitter :call <SID>get_user_lists(-1, <q-args>, "owned")
endif
if !exists(":MemberListsTwitter")
    command -nargs=? MemberListsTwitter :call <SID>get_user_lists(-1, <q-args>, "memberships")
endif
if !exists(":SubsListsTwitter")
    command -nargs=? SubsListsTwitter :call <SID>get_user_lists(-1, <q-args>, "subscriptions")
endif

" Follow or unfollow a list.
function! s:follow_list(unfollow, arg1, ...)
    if a:0 < 1
	call s:errormsg('Please specify both a username and a list.')
	return
    endif
    let user = a:arg1
    let list = a:1

    if a:unfollow
	let v1 = "Unfollowing"
	let v2 = "unfollowing"
	let v3 = "Stopped following"
	let verb = 'destroy'
    else
	let v1 = "Following"
	let v2 = "following"
	let v3 = "Now following"
	let verb = 'create'
    endif

    redraw
    echo v1." list ".user."/".list."..."

    let parms = {}
    let parms['slug'] = list
    let parms['owner_screen_name'] = user
    let url = s:get_api_root().'/lists/subscribers/'.verb.'.xml'

    let [error, output] = s:run_curl_oauth(url, s:ologin, s:get_proxy(), s:get_proxy_login(), parms)
    if error != ''
	let errormsg = s:xml_get_element(output, 'error')
	call s:errormsg("Error ".v2." list: ".(errormsg != '' ? errormsg : error))
    else
	redraw
	echo v3." list ".user."/".list."."
    endif
endfunction

if !exists(":FollowListTwitter")
    command -nargs=+ FollowListTwitter :call <SID>follow_list(0, <f-args>)
endif
if !exists(":UnfollowListTwitter")
    command -nargs=+ UnfollowListTwitter :call <SID>follow_list(1, <f-args>)
endif

" Call Tweetburner API to shorten a URL.
function! s:call_tweetburner(url)
    redraw
    echo "Sending request to Tweetburner..."

    let [error, output] = s:run_curl('http://tweetburner.com/links', '', s:get_proxy(), s:get_proxy_login(), {'link[url]' : a:url})

    if error != ''
	call s:errormsg("Error calling Tweetburner API: ".error)
	return ""
    else
	redraw
	echo "Received response from Tweetburner."
	return output
    endif
endfunction

" Call SnipURL API to shorten a URL.
function! s:call_snipurl(url)
    redraw
    echo "Sending request to SnipURL..."

    let url = 'http://snipr.com/site/snip?r=simple&link='.s:url_encode(a:url)

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling SnipURL API: ".error)
	return ""
    else
	redraw
	echo "Received response from SnipURL."
	" Get rid of extraneous newline at the beginning of SnipURL's output.
	return substitute(output, '^\n', '', '')
    endif
endfunction

" Call Metamark API to shorten a URL.
function! s:call_metamark(url)
    redraw
    echo "Sending request to Metamark..."

    let [error, output] = s:run_curl('http://metamark.net/api/rest/simple', '', s:get_proxy(), s:get_proxy_login(), {'long_url' : a:url})

    if error != ''
	call s:errormsg("Error calling Metamark API: ".error)
	return ""
    else
	redraw
	echo "Received response from Metamark."
	return output
    endif
endfunction

" Call TinyURL API to shorten a URL.
function! s:call_tinyurl(url)
    redraw
    echo "Sending request to TinyURL..."

    let url = 'http://tinyurl.com/api-create.php?url='.a:url
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling TinyURL API: ".error)
	return ""
    else
	redraw
	echo "Received response from TinyURL."
	return output
    endif
endfunction

" Get bit.ly username and api key if configured by the user. Otherwise, use a
" default username and api key.
function! s:get_bitly_key()
    if exists('g:twitvim_bitly_user') && exists('g:twitvim_bitly_key')
	return [ g:twitvim_bitly_user, g:twitvim_bitly_key ]
    endif
    return [ 'twitvim', 'R_a53414d2f36a90c3e189299c967e6efc' ]
endfunction

" Call bit.ly API to shorten a URL.
function! s:call_bitly(url)
    let [ user, key ] = s:get_bitly_key()

    redraw
    echo "Sending request to bit.ly..."

    let url = 'http://api.bit.ly/shorten?version=2.0.1'
    let url .= '&longUrl='.s:url_encode(a:url)
    let url .= '&login='.user
    let url .= '&apiKey='.key.'&format=xml&history=1'
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling bit.ly API: ".error)
	return ""
    endif

    let status = s:xml_get_element(output, 'statusCode')
    if status != 'OK'
	let errorcode = s:xml_get_element(output, 'errorCode')
	let errormsg = s:xml_get_element(output, 'errorMessage')
	if errorcode == 0
	    " For reasons unknown, bit.ly sometimes return two error codes and
	    " the first one is 0.
	    let errorcode = s:xml_get_nth(output, 'errorCode', 2)
	    let errormsg = s:xml_get_nth(output, 'errorMessage', 2)
	endif
	call s:errormsg("Error from bit.ly: ".errorcode." ".errormsg)
	return ""
    endif

    let shorturl = s:xml_get_element(output, 'shortUrl')
    redraw
    echo "Received response from bit.ly."
    return shorturl
endfunction

" Call is.gd API to shorten a URL.
function! s:call_isgd(url)
    redraw
    echo "Sending request to is.gd..."

    let url = 'http://is.gd/api.php?longurl='.s:url_encode(a:url)
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling is.gd API: ".error)
	return ""
    else
	redraw
	echo "Received response from is.gd."
	return output
    endif
endfunction


" Get urlBorg API key if configured by the user. Otherwise, use a default API
" key.
function! s:get_urlborg_key()
    return exists('g:twitvim_urlborg_key') ? g:twitvim_urlborg_key : '26361-80ab'
endfunction

" Call urlBorg API to shorten a URL.
function! s:call_urlborg(url)
    let key = s:get_urlborg_key()
    redraw
    echo "Sending request to urlBorg..."

    let url = 'http://urlborg.com/api/'.key.'/create_or_reuse/'.s:url_encode(a:url)
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling urlBorg API: ".error)
	return ""
    else
	if output !~ '\c^http'
	    call s:errormsg("urlBorg error: ".output)
	    return ""
	endif

	redraw
	echo "Received response from urlBorg."
	return output
    endif
endfunction


" Get tr.im login info if configured by the user.
function! s:get_trim_login()
    return exists('g:twitvim_trim_login') ? g:twitvim_trim_login : ''
endfunction

" Call tr.im API to shorten a URL.
function! s:call_trim(url)
    let login = s:get_trim_login()

    redraw
    echo "Sending request to tr.im..."

    let url = 'http://tr.im/api/trim_url.xml?url='.s:url_encode(a:url)

    let [error, output] = s:run_curl(url, login, s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error calling tr.im API: ".error)
	return ""
    endif

    let statusattr = s:xml_get_attr(output, 'status')

    let trimmsg = statusattr['code'].' '.statusattr['message']

    if statusattr['result'] == "OK"
	return s:xml_get_element(output, 'url')
    elseif statusattr['result'] == "ERROR"
	call s:errormsg("tr.im error: ".trimmsg)
	return ""
    else
	call s:errormsg("Unknown result from tr.im: ".trimmsg)
	return ""
    endif
endfunction

" Get Cligs API key if configured by the user.
function! s:get_cligs_key()
    return exists('g:twitvim_cligs_key') ? g:twitvim_cligs_key : ''
endfunction

" Call Cligs API to shorten a URL.
function! s:call_cligs(url)
    let url = 'http://cli.gs/api/v1/cligs/create?appid=twitvim&url='.s:url_encode(a:url)

    let key = s:get_cligs_key()
    if key != ''
	let url .= '&key='.key
    endif

    redraw
    echo "Sending request to Cligs..."

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	call s:errormsg("Error calling Cligs API: ".error)
	return ""
    endif

    redraw
    echo "Received response from Cligs."
    return output
endfunction

" Call Zi.ma API to shorten a URL.
function! s:call_zima(url)
    let url = "http://zi.ma/?module=ShortURL&file=Add&mode=API&url=".s:url_encode(a:url)

    redraw
    echo "Sending request to Zi.ma..."

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	call s:errormsg("Error calling Zi.ma API: ".error)
	return ""
    endif

    let error = s:xml_get_element(output, 'h3')
    if error != ''
	call s:errormsg("Error from Zi.ma: ".error)
	return ""
    endif

    redraw
    echo "Received response from Zi.ma."
    return output
endfunction

let s:googl_api_key = 'AIzaSyDvAhCUJppsPnPHgazgKktMoYap-QXCy5c'

" Call Goo.gl API (documented version) to shorten a URL.
function! s:call_googl(url)
    let url = 'https://www.googleapis.com/urlshortener/v1/url?key='.s:googl_api_key
    let parms = { '__json' : '{ "longUrl" : "'.a:url.'" }' }

    redraw
    echo "Sending request to goo.gl..."

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), parms)

    " Remove nul characters.
    let output = substitute(output, '[\x0]', ' ', 'g')

    let result = s:parse_json(output)

    if has_key(result, 'error') && has_key(result.error, 'message')
	call s:errormsg("Error calling goo.gl API: ".result.error.message)
	return ""
    endif

    if has_key(result, 'id')
	redraw
	echo "Received response from goo.gl."
	return result.id
    endif

    if error != ''
	call s:errormsg("Error calling goo.gl API: ".error)
	return ""
    endif

    call s:errormsg("No result returned by goo.gl API.")
    return ""
endfunction


" Call Goo.gl API (old version) to shorten a URL.
function! s:_call_googl(url)
    let url = "http://goo.gl/api/url"
    let parms = { "url": a:url }

    redraw
    echo "Sending request to goo.gl..."

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), parms)

    let result = s:parse_json(output)

    if has_key(result, 'error_message')
	call s:errormsg("Error calling goo.gl API: ".result.error_message)
	return ""
    endif

    if has_key(result, 'short_url')
	redraw
	echo "Received response from goo.gl."
	return result.short_url
    endif

    if error != ''
	call s:errormsg("Error calling goo.gl API: ".error)
	return ""
    endif

    call s:errormsg("No result returned by goo.gl API.")
    return ""
endfunction

" Call Rga.la API to shorten a URL.
function! s:call_rgala(url)
    let url = 'http://rga.la/?url='.s:url_encode(a:url).'&format=plain'
    redraw
    echo "Sending request to Rga.la..."

    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})
    if error != ''
	call s:errormsg("Error calling Rga.la API: ".error)
	return ""
    endif

    redraw
    echo "Received response from Rga.la."
    return output
endfunction

" Invoke URL shortening service to shorten a URL and insert it at the current
" position in the current buffer.
function! s:GetShortURL(tweetmode, url, shortfn)
    let url = a:url

    " Prompt the user to enter a URL if not provided on :Tweetburner command
    " line.
    if url == ""
	call inputsave()
	let url = input("URL to shorten: ")
	call inputrestore()
    endif

    if url == ""
	call s:warnmsg("No URL provided.")
	return
    endif

    let shorturl = call(function("s:".a:shortfn), [url])
    if shorturl != ""
	if a:tweetmode == "cmdline"
	    call s:CmdLine_Twitter(shorturl." ", 0)
	elseif a:tweetmode == "append"
	    execute "normal! a".shorturl."\<esc>"
	else
	    execute "normal! i".shorturl." \<esc>"
	endif
    endif
endfunction

if !exists(":Tweetburner")
    command -nargs=? Tweetburner :call <SID>GetShortURL("insert", <q-args>, "call_tweetburner")
endif
if !exists(":ATweetburner")
    command -nargs=? ATweetburner :call <SID>GetShortURL("append", <q-args>, "call_tweetburner")
endif
if !exists(":PTweetburner")
    command -nargs=? PTweetburner :call <SID>GetShortURL("cmdline", <q-args>, "call_tweetburner")
endif

if !exists(":Snipurl")
    command -nargs=? Snipurl :call <SID>GetShortURL("insert", <q-args>, "call_snipurl")
endif
if !exists(":ASnipurl")
    command -nargs=? ASnipurl :call <SID>GetShortURL("append", <q-args>, "call_snipurl")
endif
if !exists(":PSnipurl")
    command -nargs=? PSnipurl :call <SID>GetShortURL("cmdline", <q-args>, "call_snipurl")
endif

if !exists(":Metamark")
    command -nargs=? Metamark :call <SID>GetShortURL("insert", <q-args>, "call_metamark")
endif
if !exists(":AMetamark")
    command -nargs=? AMetamark :call <SID>GetShortURL("append", <q-args>, "call_metamark")
endif
if !exists(":PMetamark")
    command -nargs=? PMetamark :call <SID>GetShortURL("cmdline", <q-args>, "call_metamark")
endif

if !exists(":TinyURL")
    command -nargs=? TinyURL :call <SID>GetShortURL("insert", <q-args>, "call_tinyurl")
endif
if !exists(":ATinyURL")
    command -nargs=? ATinyURL :call <SID>GetShortURL("append", <q-args>, "call_tinyurl")
endif
if !exists(":PTinyURL")
    command -nargs=? PTinyURL :call <SID>GetShortURL("cmdline", <q-args>, "call_tinyurl")
endif

if !exists(":BitLy")
    command -nargs=? BitLy :call <SID>GetShortURL("insert", <q-args>, "call_bitly")
endif
if !exists(":ABitLy")
    command -nargs=? ABitLy :call <SID>GetShortURL("append", <q-args>, "call_bitly")
endif
if !exists(":PBitLy")
    command -nargs=? PBitLy :call <SID>GetShortURL("cmdline", <q-args>, "call_bitly")
endif

if !exists(":IsGd")
    command -nargs=? IsGd :call <SID>GetShortURL("insert", <q-args>, "call_isgd")
endif
if !exists(":AIsGd")
    command -nargs=? AIsGd :call <SID>GetShortURL("append", <q-args>, "call_isgd")
endif
if !exists(":PIsGd")
    command -nargs=? PIsGd :call <SID>GetShortURL("cmdline", <q-args>, "call_isgd")
endif

if !exists(":UrlBorg")
    command -nargs=? UrlBorg :call <SID>GetShortURL("insert", <q-args>, "call_urlborg")
endif
if !exists(":AUrlBorg")
    command -nargs=? AUrlBorg :call <SID>GetShortURL("append", <q-args>, "call_urlborg")
endif
if !exists(":PUrlBorg")
    command -nargs=? PUrlBorg :call <SID>GetShortURL("cmdline", <q-args>, "call_urlborg")
endif

if !exists(":Trim")
    command -nargs=? Trim :call <SID>GetShortURL("insert", <q-args>, "call_trim")
endif
if !exists(":ATrim")
    command -nargs=? ATrim :call <SID>GetShortURL("append", <q-args>, "call_trim")
endif
if !exists(":PTrim")
    command -nargs=? PTrim :call <SID>GetShortURL("cmdline", <q-args>, "call_trim")
endif

if !exists(":Cligs")
    command -nargs=? Cligs :call <SID>GetShortURL("insert", <q-args>, "call_cligs")
endif
if !exists(":ACligs")
    command -nargs=? ACligs :call <SID>GetShortURL("append", <q-args>, "call_cligs")
endif
if !exists(":PCligs")
    command -nargs=? PCligs :call <SID>GetShortURL("cmdline", <q-args>, "call_cligs")
endif

if !exists(":Zima")
    command -nargs=? Zima :call <SID>GetShortURL("insert", <q-args>, "call_zima")
endif
if !exists(":AZima")
    command -nargs=? AZima :call <SID>GetShortURL("append", <q-args>, "call_zima")
endif
if !exists(":PZima")
    command -nargs=? PZima :call <SID>GetShortURL("cmdline", <q-args>, "call_zima")
endif

if !exists(":Googl")
    command -nargs=? Googl :call <SID>GetShortURL("insert", <q-args>, "call_googl")
endif
if !exists(":AGoogl")
    command -nargs=? AGoogl :call <SID>GetShortURL("append", <q-args>, "call_googl")
endif
if !exists(":PGoogl")
    command -nargs=? PGoogl :call <SID>GetShortURL("cmdline", <q-args>, "call_googl")
endif

if !exists(":OldGoogl")
    command -nargs=? OldGoogl :call <SID>GetShortURL("insert", <q-args>, "_call_googl")
endif
if !exists(":AOldGoogl")
    command -nargs=? AOldGoogl :call <SID>GetShortURL("append", <q-args>, "_call_googl")
endif
if !exists(":POldGoogl")
    command -nargs=? POldGoogl :call <SID>GetShortURL("cmdline", <q-args>, "_call_googl")
endif

if !exists(":Rgala")
    command -nargs=? Rgala :call <SID>GetShortURL("insert", <q-args>, "call_rgala")
endif
if !exists(":ARgala")
    command -nargs=? ARgala :call <SID>GetShortURL("append", <q-args>, "call_rgala")
endif
if !exists(":PRgala")
    command -nargs=? PRgala :call <SID>GetShortURL("cmdline", <q-args>, "call_rgala")
endif

" Parse and format search results from Twitter Search API.
function! s:show_summize(searchres, page)
    let text = []

    let s:curbuffer.dmids = []

    let channel = s:xml_remove_elements(a:searchres, 'entry')
    let title = s:convert_entity(s:xml_get_element(channel, 'title'))

    if a:page > 1
	let title .= ' (page '.a:page.')'
    endif

    let s:curbuffer.showheader = s:get_show_header()
    if s:curbuffer.showheader
	" Index of first status will be 3 to match line numbers in timeline
	" display.
	let s:curbuffer.statuses = [0, 0, 0]
	let s:curbuffer.inreplyto = [0, 0, 0]

	" The extra stars at the end are for the syntax highlighter to
	" recognize the title. Then the syntax highlighter hides the stars by
	" coloring them the same as the background. It is a bad hack.
	call add(text, title.'*')
	call add(text, repeat('=', strlen(title)).'*')
    else
	" Index of first status will be 1 to match line numbers in timeline
	" display.
	let s:curbuffer.statuses = [0]
	let s:curbuffer.inreplyto = [0]
    endif

    for item in s:xml_get_all(a:searchres, 'entry')
	let title = s:xml_get_element(item, 'title')
	let pubdate = s:time_filter(s:xml_get_element(item, 'updated'))
	let sender = substitute(s:xml_get_element(item, 'uri'), 'http://twitter.com/', '', '')

	" Parse and save the status ID.
	let status = substitute(s:xml_get_element(item, 'id'), '^.*:', '', '')
	call add(s:curbuffer.statuses, status)

	call add(text, sender.": ".s:convert_entity(title).' |'.pubdate.'|')
    endfor
    call s:twitter_wintext(text, "timeline")
    let s:curbuffer.buffer = text
endfunction

" Query Twitter Search API and retrieve results
function! s:get_summize(query, page)
    redraw
    echo "Sending search request to Twitter Search..."

    let param = ''

    " Support pagination.
    if a:page > 1
	let param .= 'page='.a:page.'&'
    endif

    " Support count parameter in search results.
    let tcount = s:get_count()
    if tcount > 0
	let param .= 'rpp='.tcount.'&'
    endif

    let url = 'http://search.twitter.com/search.atom?'.param.'q='.s:url_encode(a:query)
    let [error, output] = s:run_curl(url, '', s:get_proxy(), s:get_proxy_login(), {})

    if error != ''
	call s:errormsg("Error querying Twitter Search: ".error)
	return
    endif

    call s:save_buffer(0)
    let s:curbuffer = {}
    call s:show_summize(output, a:page)
    let s:curbuffer.buftype = "search"

    " Stick the query in here to differentiate between sets of search results.
    let s:curbuffer.user = a:query

    let s:curbuffer.list = ''
    let s:curbuffer.page = a:page
    redraw
    call s:save_buffer(0)
    echo "Received search results from Twitter Search."
endfunction

" Prompt user for Twitter Search query string if not entered on command line.
function! s:Summize(query, page)
    let query = a:query

    " Prompt the user to enter a query if not provided on :SearchTwitter
    " command line.
    if query == ""
	call inputsave()
	let query = input("Search Twitter: ")
	call inputrestore()
    endif

    if query == ""
	call s:warnmsg("No query provided for Twitter Search.")
	return
    endif

    call s:get_summize(query, a:page)
endfunction

if !exists(":Summize")
    command -range=1 -nargs=? Summize :call <SID>Summize(<q-args>, <count>)
endif
if !exists(":SearchTwitter")
    command -range=1 -nargs=? SearchTwitter :call <SID>Summize(<q-args>, <count>)
endif

let &cpo = s:save_cpo
finish

" vim:set tw=0:
doc/twitvim.txt	[[[1
2242
*twitvim.txt*  Twitter client for Vim

		      ---------------------------------
		      TwitVim: A Twitter client for Vim
		      ---------------------------------

Author: Po Shan Cheah <morton@mortonfox.com> 
	http://twitter.com/mortonfox

License: The Vim License applies to twitvim.vim and twitvim.txt (see
	|copyright|) except use "TwitVim" instead of "Vim". No warranty,
	express or implied. Use at your own risk.


==============================================================================
1. Contents					*TwitVim* *TwitVim-contents*

	1. Contents...............................: |TwitVim-contents|
	2. Introduction...........................: |TwitVim-intro|
	3. Installation...........................: |TwitVim-install|
	   OpenSSL................................: |TwitVim-OpenSSL|
	   cURL...................................: |TwitVim-cURL|
	   twitvim.vim............................: |TwitVim-add|
	   twitvim_proxy..........................: |twitvim_proxy|
	   twitvim_proxy_login....................: |twitvim_proxy_login|
	3.1. TwitVim and OAuth....................: |TwitVim-OAuth|
	     twitvim_token_file...................: |twitvim_token_file|
	     twitvim_disable_token_file...........: |twitvim_disable_token_file|
	3.2. identi.ca............................: |TwitVim-identica|
	     twitvim_login........................: |twitvim_login|
	     twitvim_api_root.....................: |twitvim_api_root|
	3.3. Base64-Encoded Login.................: |TwitVim-login-base64|
	     twitvim_login_b64....................: |twitvim_login_b64|
	     twitvim_proxy_login_b64..............: |twitvim_proxy_login_b64|
	3.4. Alternatives to cURL.................: |TwitVim-non-cURL|
	     twitvim_enable_perl..................: |twitvim_enable_perl|
	     twitvim_enable_python................: |twitvim_enable_python|
	     twitvim_enable_ruby..................: |twitvim_enable_ruby|
	     twitvim_enable_tcl...................: |twitvim_enable_tcl|
	3.5. Using Twitter SSL API................: |TwitVim-ssl|
	     Twitter SSL via cURL.................: |TwitVim-ssl-curl|
	     twitvim_cert_insecure................: |twitvim_cert_insecure|
	     Twitter SSL via Perl interface.......: |TwitVim-ssl-perl|
	     Twitter SSL via Ruby interface.......: |TwitVim-ssl-ruby|
	     Twitter SSL via Python interface.....: |TwitVim-ssl-python|
	     Twitter SSL via Tcl interface........: |TwitVim-ssl-tcl|
	3.6. Hide the header in timeline buffer...: |TwitVim-hide-header|
	     twitvim_show_header..................: |twitvim_show_header|
	3.7. Timeline filtering...................: |TwitVim-filter|
	     twitvim_filter_enable................: |twitvim_filter_enable|
	     twitvim_filter_regex.................: |twitvim_filter_regex|
	4. Manual.................................: |TwitVim-manual|
	4.1. TwitVim's Buffers....................: |TwitVim-buffers|
	4.2. Update Commands......................: |TwitVim-update-commands|
	     :PosttoTwitter.......................: |:PosttoTwitter|
	     :CPosttoTwitter......................: |:CPosttoTwitter|
	     :BPosttoTwitter......................: |:BPosttoTwitter|
	     :SendDMTwitter.......................: |:SendDMTwitter|
	4.3. Timeline Commands....................: |TwitVim-timeline-commands|
	     :UserTwitter.........................: |:UserTwitter|
	     twitvim_count........................: |twitvim_count|
	     :FriendsTwitter......................: |:FriendsTwitter|
	     :MentionsTwitter.....................: |:MentionsTwitter|
	     :RepliesTwitter......................: |:RepliesTwitter|
	     :PublicTwitter.......................: |:PublicTwitter|
	     :DMTwitter...........................: |:DMTwitter|
	     :DMSentTwitter.......................: |:DMSentTwitter|
	     :ListTwitter.........................: |:ListTwitter|
	     :RetweetedToMeTwitter................: |:RetweetedToMeTwitter|
	     :RetweetedByMeTwitter................: |:RetweetedByMeTwitter|
	     :FavTwitter..........................: |:FavTwitter|
	     :FollowingTwitter....................: |:FollowingTwitter|
	     :FollowersTwitter....................: |:FollowersTwitter|
	     :ListInfoTwitter.....................: |:ListInfoTwitter|
	     :MembersOfListTwitter................: |:MembersOfListTwitter|
	     :SubsOfListTwitter...................: |:SubsOfListTwitter|
	     :OwnedListsTwitter...................: |:OwnedListsTwitter|
	     :MemberListsTwitter..................: |:MemberListsTwitter|
	     :SubsListsTwitter....................: |:SubsListsTwitter|
	     :FollowListTwitter...................: |:FollowListTwitter|
	     :UnfollowListTwitter.................: |:UnfollowListTwitter|
	     :BackTwitter.........................: |:BackTwitter|
	     :BackInfoTwitter.....................: |:BackInfoTwitter|
	     :ForwardTwitter......................: |:ForwardTwitter|
	     :ForwardInfoTwitter..................: |:ForwardInfoTwitter|
	     :RefreshTwitter......................: |:RefreshTwitter|
	     :RefreshInfoTwitter..................: |:RefreshInfoTwitter|
	     :NextTwitter.........................: |:NextTwitter|
	     :NextInfoTwitter.....................: |:NextInfoTwitter|
	     :PreviousTwitter.....................: |:PreviousTwitter|
	     :PreviousInfoTwitter.................: |:PreviousInfoTwitter|
	     :SetLoginTwitter.....................: |:SetLoginTwitter|
	     :SwitchLoginTwitter..................: |:SwitchLoginTwitter|
	     :ResetLoginTwitter...................: |:ResetLoginTwitter|
	     :FollowTwitter.......................: |:FollowTwitter|
	     :UnfollowTwitter.....................: |:UnfollowTwitter|
	     :BlockTwitter........................: |:BlockTwitter|
	     :UnblockTwitter......................: |:UnblockTwitter|
	     :EnableRetweetsTwitter...............: |:EnableRetweetsTwitter|
	     :DisableRetweetsTwitter..............: |:DisableRetweetsTwitter|
	     :ReportSpamTwitter...................: |:ReportSpamTwitter|
	     :AddToListTwitter....................: |:AddToListTwitter|
	     :RemoveFromListTwitter...............: |:RemoveFromListTwitter|
	4.4. Mappings.............................: |TwitVim-mappings|
	     Alt-T................................: |TwitVim-A-t|
	     Ctrl-T...............................: |TwitVim-C-t|
	     Reply Feature........................: |TwitVim-reply|
	     Alt-R................................: |TwitVim-A-r|
	     <Leader>r............................: |TwitVim-Leader-r|
	     Reply to all Feature.................: |TwitVim-reply-all|
	     <Leader>Ctrl-R.......................: |TwitVim-Leader-C-r|
	     Retweet Feature......................: |TwitVim-retweet|
	     <Leader>R............................: |TwitVim-Leader-S-r|
	     Old-style retweets...................: |twitvim_old_retweet|
	     twitvim_retweet_format...............: |twitvim_retweet_format|
	     Direct Message Feature...............: |TwitVim-direct-message|
	     Alt-D................................: |TwitVim-A-d|
	     <Leader>d............................: |TwitVim-Leader-d|
	     Goto Feature.........................: |TwitVim-goto|
	     Alt-G................................: |TwitVim-A-g|
	     <Leader>g............................: |TwitVim-Leader-g|
	     twitvim_browser_cmd..................: |twitvim_browser_cmd|
	     LongURL Feature......................: |TwitVim-LongURL|
	     <Leader>e............................: |TwitVim-Leader-e|
	     User Profiles........................: |TwitVim-profile|
	     <Leader>p............................: |TwitVim-Leader-p|
	     In-reply-to..........................: |TwitVim-inreplyto|
	     <Leader>@............................: |TwitVim-Leader-@|
	     Delete...............................: |TwitVim-delete|
	     <Leader>X............................: |TwitVim-Leader-X|
	     <Leader>f............................: |TwitVim-Leader-f|
	     <Leader>Ctrl-F.......................: |TwitVim-Leader-C-f|
	     Ctrl-O...............................: |TwitVim-C-o|
	     Ctrl-I...............................: |TwitVim-C-i|
	     Refresh..............................: |TwitVim-refresh|
	     <Leader><Leader>.....................: |TwitVim-Leader-Leader|
	     Next page............................: |TwitVim-next|
	     Ctrl-PageDown........................: |TwitVim-C-PageDown|
	     Previous page........................: |TwitVim-previous|
	     Ctrl-PageUp..........................: |TwitVim-C-PageUp|
	4.5. Utility Commands.....................: |TwitVim-utility|
	     :Tweetburner.........................: |:Tweetburner|
	     :ATweetburner........................: |:ATweetburner|
	     :PTweetburner........................: |:PTweetburner|
	     :Snipurl.............................: |:Snipurl|
	     :ASnipurl............................: |:ASnipurl|
	     :PSnipurl............................: |:PSnipurl|
	     :Metamark............................: |:Metamark|
	     :AMetamark...........................: |:AMetamark|
	     :PMetamark...........................: |:PMetamark|
	     :TinyURL.............................: |:TinyURL|
	     :ATinyURL............................: |:ATinyURL|
	     :PTinyURL............................: |:PTinyURL|
	     :BitLy...............................: |:BitLy|
	     twitvim_bitly_user...................: |twitvim_bitly_user|
	     twitvim_bitly_key....................: |twitvim_bitly_key|
	     :ABitLy..............................: |:ABitLy|
	     :PBitLy..............................: |:PBitLy|
	     :IsGd................................: |:IsGd|
	     :AIsGd...............................: |:AIsGd|
	     :PIsGd...............................: |:PIsGd|
	     :UrlBorg.............................: |:UrlBorg|
	     twitvim_urlborg_key..................: |twitvim_urlborg_key|
	     :AUrlBorg............................: |:AUrlBorg|
	     :PUrlBorg............................: |:PUrlBorg|
	     :Trim................................: |:Trim|
	     twitvim_trim_login...................: |twitvim_trim_login|
	     :ATrim...............................: |:ATrim|
	     :PTrim...............................: |:PTrim|
	     :Cligs...............................: |:Cligs|
	     twitvim_cligs_key....................: |twitvim_cligs_key|
	     :ACligs..............................: |:ACligs|
	     :PCligs..............................: |:PCligs|
	     :Zima................................: |:Zima|
	     :AZima...............................: |:AZima|
	     :PZima...............................: |:PZima|
	     :Googl...............................: |:Googl|
	     :AGoogl..............................: |:AGoogl|
	     :PGoogl..............................: |:PGoogl|
	     :Rgala...............................: |:Rgala|
	     :ARgala..............................: |:ARgala|
	     :PRgala..............................: |:PRgala|
	     :SearchTwitter.......................: |:SearchTwitter|
	     :RateLimitTwitter....................: |:RateLimitTwitter|
	     :ProfileTwitter......................: |:ProfileTwitter|
	     :LocationTwitter.....................: |:LocationTwitter|
	     :TrendTwitter........................: |:TrendTwitter|
	     :SetTrendLocationTwitter.............: |:SetTrendLocationTwitter|
	     twitvim_woeid........................: |twitvim_woeid|
	5. Timeline Highlighting..................: |TwitVim-highlight|
	   twitterUser............................: |hl-twitterUser|
	   twitterTime............................: |hl-twitterTime|
	   twitterTitle...........................: |hl-twitterTitle|
	   twitterLink............................: |hl-twitterLink|
	   twitterReply...........................: |hl-twitterReply|
	6. Tips and Tricks........................: |TwitVim-tips|
	6.1. Timeline Hotkeys.....................: |TwitVim-hotkeys|
	6.2. Switching between identi.ca users....: |TwitVim-switch|
	6.3. Line length in status line...........: |TwitVim-line-length|
	7. History................................: |TwitVim-history|
	8. Credits................................: |TwitVim-credits|


==============================================================================
2. Introduction						*TwitVim-intro*

	TwitVim is a plugin that allows you to post to Twitter, a
	microblogging service at http://www.twitter.com.

	Since version 0.2.19, TwitVim also supports other microblogging
	services, such as identi.ca, that offer Twitter-compatible APIs. See
	|TwitVim-identica| for information on configuring TwitVim for those
	services.


==============================================================================
3. Installation						*TwitVim-install*

	
	Note: These instructions are for configuring TwitVim for use with
	Twitter. If you intend to use TwitVim only with identi.ca, see
	|TwitVim-identica|.


	1. Install OpenSSL or compile Vim with |Python|, |Perl|, |Ruby|, or |Tcl|.

	In order to compute HMAC-SHA1 digests and sign Twitter OAuth requests,
	TwitVim needs to either run the openssl command line tool from the
	OpenSSL toolkit or call a HMAC-SHA1 digest function from one of the
	above scripting interfaces.

	
							*TwitVim-OpenSSL*
	If you are using a precompiled Vim executable and do not wish to
	recompile Vim to add a scripting interface, then the OpenSSL approach
	is the simplest.

	If OpenSSL is not already on your system, you can download it from
	http://openssl.org/  If you are using Windows, check the OpenSSL FAQ
	for a link to a precompiled OpenSSL for Windows.

	After installing OpenSSL, make sure that the directory where the
	openssl executable resides is listed in your PATH environment
	variable so that TwitVim can find it.

	Note: TwitVim uses the openssl -hmac option, which is not available in
	old versions of OpenSSL. I recommend updating to OpenSSL 0.9.8o,
	1.0.0a, or later to get the -hmac option and the latest security
	fixes.


	Instead of using the openssl command line tool, you can also have
	TwitVim compute HMAC-SHA1 digests via a Vim scripting interface. This
	approach is significantly faster because it does not need to run an
	external program. You can use Perl, Python, Ruby, or Tcl.


	If you compiled Vim with Perl, add the following to your vimrc:
>
		let twitvim_enable_perl = 1
<
	Also, verify that your Perl installation has the Digest::HMAC_SHA1
	module. This module comes standard in some Perl distributions, e.g.
	ActivePerl. In other Perl setups, you'll need to download and install
	Digest::HMAC_SHA1 from CPAN. The Perl Package Manager PPM may be
	helpful here.


	If you compiled Vim with Python, add the following to your vimrc:
>
		let twitvim_enable_python = 1
<
	Also, verify that your Python installation has the base64, hashlib,
	and hmac modules. All of these are in the Python standard library as
	of Python 2.5.


	If you compiled Vim with Ruby, add the following to your vimrc:
>
		let twitvim_enable_ruby = 1
<
	TwitVim requires the openssl and base64 modules, both of which are
	in the Ruby standard library. However, you may need to install the
	OpenSSL library from http://www.openssl.org if it is not already on
	your system.


	If you compiled Vim with Tcl, add the following to your vimrc:
>
		let twitvim_enable_tcl = 1
<
	Also, verify that your Tcl installation has the base64 and sha1
	packages. These packages are in the Tcllib library. See
	|twitvim_enable_tcl| for help on obtaining and installing this
	library.


	2. Install cURL.				*TwitVim-cURL*

	If you don't already have cURL on your system, download it from
	http://curl.haxx.se/. Make sure that the curl executable is in a
	directory listed in your PATH environment variable, or the equivalent
	for your system.

	If you have already compiled Vim with Perl, Python, Ruby, or Tcl for
	Step 1, I recommend that you use the scripting interface instead of
	installing cURL. See |TwitVim-non-cURL| for setup details. Using a
	scripting interface for network I/O is faster because it avoids the
	overhead of running an external program.


	3. twitvim.vim					*TwitVim-add*

	Add twitvim.vim to your plugins directory. The location depends on
	your operating system. See |add-global-plugin| for details.

	If you installed from the Vimball (.vba) file, twitvim.vim should
	already be in its correct place.


	4. twitvim_proxy				*twitvim_proxy*

	This step is only needed if you access the web through a HTTP proxy.
	If you use a HTTP proxy, add the following to your vimrc:
>
		let twitvim_proxy = "proxyserver:proxyport"
<
	Replace proxyserver with the address of the HTTP proxy and proxyport
	with the port number of the HTTP proxy.


	5. twitvim_proxy_login				*twitvim_proxy_login*

	If the HTTP proxy requires authentication, add the following to your
	vimrc:
>
		let twitvim_proxy_login = "proxyuser:proxypassword"
<
	Where proxyuser is your proxy user and proxypassword is your proxy
	password.

	It is possible to avoid having your proxy password in plaintext in
	your vimrc. See |TwitVim-login-base64| for details.


	6. Set twitvim_browser_cmd.

	In order to log in with Twitter OAuth, TwitVim needs to launch your
	web browser and bring up the Twitter authentication web page.

	See |twitvim_browser_cmd| for details. For example, if you use Firefox
	under Windows, add the following to your vimrc:
>
		let twitvim_browser_cmd = 'firefox.exe'
<
	Note: If you do not set up twitvim_browser_cmd, TwitVim will display
	the authentication URL and wait for you to visit it in your browser
	manually and approve the application. If possible, this auth URL
	will be shortened with is.gd or Bit.ly for ease of entry.


	7. Sign into Twitter with OAuth.

	Use any TwitVim command that requires authentication. For example,
	run |:FriendsTwitter|. |:SetLoginTwitter| is the normal way to
	initiate authentication without running a timeline command.

	Since TwitVim does not yet have an OAuth access token, it will
	initiate the Twitter OAuth handshake. Then it'll launch your web
	browser to a Twitter web page that says "Authorize TwitVim to use your
	account?". On this page, sign in to Twitter, if necessary, and then
	click on "Authorize app" to allow TwitVim access to your Twitter
	account.

	Twitter will then report that you have granted access to TwitVim and
	display a 7-digit PIN. Copy the PIN and paste it to the TwitVim input
	prompt "Enter Twitter OAuth PIN:".

	
	And now you are ready to use TwitVim.


------------------------------------------------------------------------------
3.1. TwitVim and OAuth					*TwitVim-OAuth*

	After you log into Twitter with OAuth, TwitVim stores the OAuth access
	token in a file so that you won't have to log in again when you
	restart TwitVim. By default, this file is $HOME/.twitvim.token

						*twitvim_token_file*
	You can change the name and location of this token file by setting
	twitvim_token_file in your vimrc. For example:
>
		let twitvim_token_file = "/etc/.twitvim.token"
<
	Since the access token grants full access to your Twitter account, it
	is recommended that you place the token file in a directory that is
	not readable or accessible by other users.


						*twitvim_disable_token_file*
	If you are using TwitVim on an insecure system, you may prefer to 
	not save access tokens at all. To turn off the token file, add
	the following to your vimrc:
>
		let twitvim_disable_token_file = 1
<
	If the token file is disabled, TwitVim will initiate an OAuth
	handshake every time you restart it.


	If TwitVim is logged into Twitter and you need to log in as a
	different Twitter user, use either the |:SetLoginTwitter| or
	|:ResetLoginTwitter| commands to discard the access token. When the
	Twitter authentication web page comes up, use the "Sign Out" link on
	that page to switch Twitter users.


	Note: If you have set up TwitVim to use the Twitter SSL API (See
	|TwitVim-ssl|), TwitVim will also use SSL endpoints to do the OAuth
	handshake. If you are running TwitVim on an insecure network,
	especially an open wireless network, it is recommended that you set up
	TwitVim for SSL before using :SetLoginTwitter. Failure to do so may
	expose your OAuth access token to packet sniffers.


------------------------------------------------------------------------------
3.2. identi.ca						*TwitVim-identica*

	identi.ca offers a Twitter-compatible API so you can use TwitVim with
	identi.ca. Setting up TwitVim for identi.ca is a bit different from
	setting up TwitVim for Twitter because identi.ca uses Basic
	authentication instead of OAuth.

	1. Install cURL

	See |TwitVim-cURL|.


	2. twitvim_login				*twitvim_login*

	Add the following to your vimrc:
>
		let twitvim_login = "USER:PASS"
<
	Replace USER with your Twitter user name and PASS with your Twitter
	password.

	It is possible to avoid having your Twitter password in plaintext in
	your vimrc. See |TwitVim-login-base64| for details.


	3. Set up proxy info, if necessary.

	See |twitvim_proxy| and |twitvim_proxy_login|.


	4. Set twitvim_api_root				*twitvim_api_root*

	This setting allows you to configure TwitVim to communicate with
	servers other than twitter.com that implement a Twitter-compatible
	API.

	For identi.ca, add the following to your vimrc:
>
		let twitvim_api_root = "http://identi.ca/api"
<

	And now you are ready to use TwitVim with identi.ca.


------------------------------------------------------------------------------
3.3. Base64-Encoded Login				*TwitVim-login-base64*

	For safety purposes, TwitVim allows you to configure your login and
	proxy login information preencoded in base64. This is not truly secure
	as it is not encryption but it can stop casual onlookers from reading
	off your password when you edit your vimrc.

						*twitvim_login_b64*
	To do that, set the following in your vimrc:
>
		let twitvim_login_b64 = "base64string"
<
	Note: This is only for identi.ca and other services that use Basic
	authentication. Twitter uses OAuth, so you do not need to add Twitter
	login info to your vimrc.

	
						*twitvim_proxy_login_b64*
	If your HTTP proxy needs authentication, set the following:
>
		let twitvim_proxy_login_b64 = "base64string"
<
	Where base64string is your username:password encoded in base64.


	An example:

	Let's say Joe User has a Twitter login of "joeuser" and a password of
	"joepassword". His first step is to encode "joeuser:joepassword" in
	Base64. He can either use a standalone utility to do that or, in a
	pinch, he can do the encoding at websites such as the following:
	http://makcoder.sourceforge.net/demo/base64.php
	http://www.opinionatedgeek.com/dotnet/tools/Base64Encode/

	The result is: am9ldXNlcjpqb2VwYXNzd29yZA==

	Then he adds the following to his vimrc:
>
		let twitvim_login_b64 = "am9ldXNlcjpqb2VwYXNzd29yZA=="
<
	And his setup is ready.


------------------------------------------------------------------------------
3.4. Alternatives to cURL				*TwitVim-non-cURL*

	TwitVim supports http networking through Vim's |Perl|, |Python|,
	|Ruby|, and |Tcl| interfaces, so if you have any of those interfaces
	compiled into your Vim program, you can use that instead of cURL.
	
	Generally, it is slightly faster to use one of those scripting
	interfaces for networking because it avoids running an external
	program. On Windows, it also avoids a brief taskbar flash when cURL
	runs.

	To find out if you have those interfaces, use the |:version| command
	and check the |+feature-list|. Then to enable this special http
	networking code in TwitVim, add one of the following lines to your
	vimrc:
>
		let twitvim_enable_perl = 1
		let twitvim_enable_python = 1
		let twitvim_enable_ruby = 1
		let twitvim_enable_tcl = 1
<
	You can enable more than one scripting language but TwitVim will only
	use the first one it finds.


	1. Perl interface				*twitvim_enable_perl*

	To enable TwitVim's Perl networking code, add the following to your
	vimrc:
>
		let twitvim_enable_perl = 1
<
	TwitVim requires the MIME::Base64 and LWP::UserAgent modules. If you
	have ActivePerl, these modules are included in the default
	installation.


	2. Python interface				*twitvim_enable_python*

	To enable TwitVim's Python networking code, add the following to your
	vimrc:
>
		let twitvim_enable_python = 1
<
	TwitVim requires the urllib, urllib2, and base64 modules. These
	modules are in the Python standard library.


	3. Ruby interface				*twitvim_enable_ruby*

	To enable TwitVim's Ruby networking code, add the following to your
	vimrc:
>
		let twitvim_enable_ruby = 1
<
	TwitVim requires the net/http, uri, and Base64 modules. These modules
	are in the Ruby standard library.

	In addition, if using the Ruby interface, TwitVim requires Vim
	7.2.360 or later to fix an if_ruby problem with Windows sockets.

	Alternatively, you can add the following patch to the Vim sources:

	http://www.mail-archive.com/vim_dev@googlegroups.com/msg03693.html

	See also Bram's correction to the patch:

	http://www.mail-archive.com/vim_dev@googlegroups.com/msg03713.html


	3. Tcl interface				*twitvim_enable_tcl*

	To enable TwitVim's Tcl networking code, add the following to your
	vimrc:
>
		let twitvim_enable_tcl = 1
<
	TwitVim requires the http, uri, and base64 packages. uri and base64
	are in the Tcllib library so you may need to install that. See
	http://tcllib.sourceforge.net/

	If you have ActiveTcl 8.5, the default installation does not include
	Tcllib. Run the following command from the shell to add Tcllib:
>
		teacup install tcllib85
<

------------------------------------------------------------------------------
3.5. Using Twitter SSL API				*TwitVim-ssl*

	For added security, TwitVim can use the Twitter SSL API instead of the
	regular Twitter API. You configure this by setting |twitvim_api_root|
	to the https version of the URL:
>
		let twitvim_api_root = "https://api.twitter.com/1"
<
	For identi.ca:
>
		let twitvim_api_root = "https://identi.ca/api"
<
	There are certain pre-requisites, as explained below.


	1. Twitter SSL via cURL				*TwitVim-ssl-curl*

	To use SSL via cURL, you need to install the SSL libraries and an
	SSL-enabled build of cURL.

							*twitvim_cert_insecure*
	Even after you've done that, cURL may complain about certificates that
	failed verification. If you need to override certificate checking, set
	twitvim_cert_insecure:
>
		let twitvim_cert_insecure = 1
<

	2. Twitter SSL via Perl interface		*TwitVim-ssl-perl*

	To use SSL via the TwitVim Perl interface (See |twitvim_enable_perl|),
	you need to install the SSL libraries and the Crypt::SSLeay Perl
	module.

	If you are using Twitter SSL over a proxy, do not set twitvim_proxy
	and twitvim_proxy_login. Crypt::SSLeay gets proxy information from
	the environment, so do this instead:
>
		let $HTTPS_PROXY="http://proxyserver:proxyport"
		let $HTTPS_PROXY_USERNAME="user"
		let $HTTPS_PROXY_PASSWORD="password"
<
	Alternatively, you can set those environment variables before starting
	Vim.


	3. Twitter SSL via Ruby interface		*TwitVim-ssl-ruby*

	To use SSL via Ruby, you need to install the SSL libraries and an
	SSL-enabled build of Ruby.

	If Ruby produces the error "`write': Bad file descriptor" in http.rb,
	then you need to check your certificates or override certificate
	checking. See |twitvim_cert_insecure|.

	Set twitvim_proxy and twitvim_proxy_login as usual if using Twitter
	SSL over a proxy.


	4. Twitter SSL via Python interface		*TwitVim-ssl-python*

	To use SSL via Python, you need to install the SSL libraries and an
	SSL-enabled build of Python.

	The Python interface does not yet support Twitter SSL over a proxy.
	This is due to a missing feature in urllib2.


	5. Twitter SSL via Tcl interface		*TwitVim-ssl-tcl*

	To use SSL via Tcl, you need to install the SSL libraries and Tcllib.
	To be more specific, TwitVim needs the tls package from Tcllib.

	All known versions of Vim (up to 7.3f beta, as of this writing) have a
	bug that prevents the tls package from being loaded if you compile Vim
	with Tcl 8.5. This discussion thread explains the problem:
>
	http://objectmix.com/tcl/15892-tcl-interp-inside-vim-throws-error-w-clock-format.html
<
	If you need to use Twitter SSL with the Tcl interface, you can try one
	of the following workarounds:

	a. Downgrade to Tcl 8.4.
	b. Edit if_tcl.c in the Vim source code to remove the redefinition of
	catch. Then rebuild Vim.


------------------------------------------------------------------------------
3.6. Hide the header in timeline and info buffers	*TwitVim-hide-header*

	In the timeline and info buffers, the first two lines are header
	lines. The first line tells you the type of buffer it is (e.g.
	friends, user, replies, direct messages, search in the timeline
	buffer; friends, followers, user profile in the info buffer) and other
	relevant buffer information. (e.g. user name, search terms, page
	number) The second line is a separator line.

	If you wish to suppress the header display, set twitvim_show_header
	to 0:

							*twitvim_show_header*
>
		let twitvim_show_header = 0
<
	If twitvim_show_header is unset, it defaults to 1, i.e. show the
	header.

	Note: Setting twitvim_show_header does not change the timeline buffer
	immediately. Use |:RefreshTwitter| to refresh the timeline (or
	|:RefreshInfoTwitter| to refresh the info buffer) to see the
	effect. Also, twitvim_show_header does not retroactively alter
	previous timelines in the timeline stack.


------------------------------------------------------------------------------
3.7. Timeline filtering					*TwitVim-filter*

	TwitVim allows you to filter your timeline buffer to hide tweets
	containing a pattern.

	To enable timeline filtering, set twitvim_filter_enable to 1:

							*twitvim_filter_enable*
>
		let twitvim_filter_enable = 1
<
	Then set twitvim_filter_regex to the pattern you wish to filter out of
	the timeline. For example, to hide GetGlue tweets and tweets
	containing Youtube URLs, use the following:

							*twitvim_filter_regex*
>
		let twitvim_filter_regex = '@GetGlue\|/youtu\.be/'
<
	The filter is a regular expression. See |pattern| for patterns that
	are accepted. The |'ignorecase'| option sets the ignore-caseness of
	the pattern. |'smartcase'| is not used. The matching is always done
	like 'magic' is set and 'cpoptions' is empty. (Essentially, this is
	the same as |match()| because that is what it uses.)

	Be as specific as possible when setting the filter. For example, if
	you filter on "youtube", you are potentially also filtering out
	conversations about Youtube in addition to Youtube status updates.

	Timeline filtering removes tweets from your timeline, so the timeline
	display may be shorter than usual. Increase |twitvim_count| to
	compensate, if necessary.


==============================================================================
4. TwitVim Manual					*TwitVim-manual*

------------------------------------------------------------------------------
4.1. TwitVim's Buffers					*TwitVim-buffers*

	TwitVim has 2 buffers, a timeline buffer and an info buffer.

	Commands such as |:FriendsTwitter|, |:MentionsTwitter|, |:DMTwitter|,
	and |:ListTwitter| bring up a timeline buffer. This buffer consists of
	a list of tweets or messages. See |TwitVim-mappings| for a list of
	mappings that are local to this buffer.

	Commands such as |:ProfileTwitter|, |:FollowingTwitter|,
	|:FollowersTwitter|, and |:OwnedListsTwitter| bring up an info buffer.
	This buffer may consist of a list of users or a list of Twitter lists.
	In the case of |:ProfileTwitter|, it is a list of fields from one user
	profile. Only a subset of the mappings in |:TwitVim-mappings| will
	work in the info buffer.

	TwitVim brings up a new timeline buffer only if one does not already
	exist. Otherwise, it reuses the existing timeline buffer. The same
	behavior applies to the info buffer.


------------------------------------------------------------------------------
4.2. Update Commands				*TwitVim-update-commands*

	These commands post an update to your Twitter account. If the friends,
	user, or public timeline is visible, TwitVim will insert the update
	into the timeline view after posting it.

	Note: If you are replying to a tweet, use the <Leader>r mapping in the
	timeline buffer instead. See |TwitVim-reply|. That mapping will set
	the in-reply-to field, which :PosttoTwitter can't handle.

	:PosttoTwitter					*:PosttoTwitter*

	This command will prompt you for a message and post it to Twitter.

	:CPosttoTwitter					*:CPosttoTwitter*

	This command posts the current line in the current buffer to Twitter.

	:BPosttoTwitter					*:BPosttoTwitter*

	This command posts the contents of the current buffer to Twitter.

	:SendDMTwitter {username}			*:SendDMTwitter*

	This command will prompt you for a direct message to send to user
	{username}.

	Note: If you get a "403 Forbidden" error when you try to send a direct
	message, check if the user you're messaging is following you. That is
	the most common reason for this error when sending a direct message.

------------------------------------------------------------------------------
4.3. Timeline Commands				*TwitVim-timeline-commands*

	These commands retrieve a Twitter timeline and display it in a special
	Twitter buffer. TwitVim applies syntax highlighting to highlight
	certain elements in the timeline view. See |TwitVim-highlight| for a
	list of highlighting groups it uses.


	:[count]UserTwitter				*:UserTwitter*
	:[count]UserTwitter {username}

	This command displays your Twitter timeline.

	If you specify a {username}, this command displays the timeline for
	that user.

	If you specify [count], that number is used as the page number. For
	example, :2UserTwitter displays the second page from your user
	timeline.

							*twitvim_count*
	You can configure the number of tweets returned by :UserTwitter by
	setting twitvim_count. For example,
>
		let twitvim_count = 50
<
	will make :UserTwitter return 50 tweets instead of the default of 20.
	You can set twitvim_count to any integer from 1 to 200.


	:[count]FriendsTwitter				*:FriendsTwitter*

	This command displays your Twitter timeline with updates from friends
	merged in.

	If you specify [count], that number is used as the page number. For
	example, :2FriendsTwitter displays the second page from your friends
	timeline.

	You can configure the number of tweets returned by :FriendsTwitter by
	setting |twitvim_count|.


	:[count]MentionsTwitter				*:MentionsTwitter*
	:[count]RepliesTwitter				*:RepliesTwitter*

	This command displays a timeline of mentions (updates containing
	@username) that you've received from other Twitter users.

	If you specify [count], that number is used as the page number. For
	example, :2MentionsTwitter displays the second page from your mentions
	timeline.

	:RepliesTwitter is the old name for :MentionsTwitter.

	You can configure the number of tweets returned by :MentionsTwitter by
	setting |twitvim_count|.


	:PublicTwitter					*:PublicTwitter*

	This command displays the public timeline.


	:[count]DMTwitter				*:DMTwitter*

	This command displays direct messages that you've received.

	If you specify [count], that number is used as the page number. For
	example, :2DMTwitter displays the second page from your direct
	messages timeline.


	:[count]DMSentTwitter				*:DMSentTwitter*

	This command displays direct messages that you've sent.

	If you specify [count], that number is used as the page number. For
	example, :2DMSentTwitter displays the second page from your direct
	messages sent timeline.


	:[count]ListTwitter {list}			*:ListTwitter*
	:[count]ListTwitter {user} {list}

	This command displays a Twitter list timeline.

	In the first form, {user} is assumed to be you so the command will
	display a list of yours named {list}.

	In the second form, the command displays list {list} from user
	{user}.

	If you specify [count], that number is used as the page number. For
	example, :2ListTwitter list1 displays the second page from the list1
	list timeline.


	:[count]RetweetedToMeTwitter			*:RetweetedToMeTwitter*

	This command displays a timeline of retweets by others to you.

	If you specify [count], that number is used as the page number. For
	example, :2RetweetedToMeTwitter displays the second page from the
	retweets timeline.


	:[count]RetweetedByMeTwitter			*:RetweetedByMeTwitter*

	This command displays a timeline of retweets by you.

	If you specify [count], that number is used as the page number. For
	example, :2RetweetedByMeTwitter displays the second page from the
	retweets timeline.


	:[count]FavTwitter				*:FavTwitter*

	This command displays a timeline of your favorites.

	If you specify [count], that number is used as the page number. For
	example, :2FavTwitter displays the second page from the favorites
	timeline.


	:FollowingTwitter				*:FollowingTwitter*
	:FollowingTwitter {user}

	This command displays a list of people you're following.

	If {user} is specified, this command displays a list of people that
	user is following.

	You can use Ctrl-PageUp and Ctrl-PageDown to page back and forth in
	this list. See |TwitVim-previous| and |TwitVim-next|.


	:FollowersTwitter				*:FollowersTwitter*
	:FollowersTwitter {user}

	This command displays a list of people who follow you.

	If {user} is specified, this command displays a list of people
	following that user.

	You can use Ctrl-PageUp and Ctrl-PageDown to page back and forth in
	this list. See |TwitVim-previous| and |TwitVim-next|.


	:ListInfoTwitter {list}				*:ListInfoTwitter*
	:ListInfoTwitter {user} {list}

	This command displays summary information on the Twitter list {list}
	owned by user {user}. If not specified, {user} is the currently
	logged-in user.


	:MembersOfListTwitter {list}			*:MembersOfListTwitter*
	:MembersOfListTwitter {user} {list}

	This command displays members of the Twitter list {list} owned by 
	user {user}. If not specified, {user} is the currently logged-in user.


	:SubsOfListTwitter {list}			*:SubsOfListTwitter*
	:SubsOfListTwitter {user} {list}

	This command displays subscribers to the Twitter list {list} owned by 
	user {user}. If not specified, {user} is the currently logged-in user.


	:OwnedListsTwitter				*:OwnedListsTwitter*
	:OwnedListsTwitter {user}

	This command displays the lists owned by {user}. If not specified,
	{user} is the currently logged-in user.


	:MemberListsTwitter				*:MemberListsTwitter*
	:MemberListsTwitter {user}

	This command displays the lists following {user}. If not specified,
	{user} is the currently logged-in user.


	:SubsListsTwitter				*:SubsListsTwitter*
	:SubsListsTwitter {user}

	This command displays the lists followed by {user}. If not specified,
	{user} is the currently logged-in user.


	:FollowListTwitter {user} {list}		*:FollowListTwitter*

	Start following the list {list} owned by {user}.


	:UnfollowListTwitter {user} {list}		*:UnfollowListTwitter*

	Stop following the list {list} owned by {user}.


	:BackTwitter					*:BackTwitter*

	This command takes you back to the previous timeline in the timeline
	stack. TwitVim saves a limited number of timelines. This command
	will display a warning if you attempt to go beyond the oldest saved
	timeline. See |TwitVim-C-o|.


	:BackInfoTwitter				*:BackInfoTwitter*

	This command is similar to |:BackTwitter| but takes you to the
	previous display in the info buffer stack instead. See |TwitVim-C-o|.


	:ForwardTwitter					*:ForwardTwitter*

	This command takes you to the next timeline in the timeline stack.
	It will display a warning if you attempt to go past the newest saved
	timeline so this command can only be used after :BackTwitter.
	See |TwitVim-C-i|.
	

	:ForwardInfoTwitter				*:ForwardInfoTwitter*

	This command is similar to |:ForwardTwitter| but takes you to the
	next display in the info buffer stack instead. See |TwitVim-C-o|.


	:RefreshTwitter					*:RefreshTwitter*

	This command refreshes the timeline. See |TwitVim-Leader-Leader|.


	:RefreshInfoTwitter				*:RefreshInfoTwitter*

	This command refreshes the info buffer. See |TwitVim-Leader-Leader|.


	:NextTwitter					*:NextTwitter*

	This command loads the next (older) page in the timeline.
	See |TwitVim-C-PageDown|.


	:NextInfoTwitter				*:NextInfoTwitter*

	This command loads the next page in the info buffer.
	See |TwitVim-C-PageDown|.


	:PreviousTwitter				*:PreviousTwitter*

	This command loads the previous (newer) page in the timeline. If the
	timeline is on the first page, this command issues a warning and
	doesn't do anything. See |TwitVim-C-PageUp|.


	:PreviousInfoTwitter				*:PreviousInfoTwitter*

	This command loads the previous page in the info buffer. If the info
	buffer is on the first page, this command issues a warning and doesn't
	do anything. See |TwitVim-C-PageUp|.


	:SetLoginTwitter				*:SetLoginTwitter*

	This command initiates an OAuth login handshake. 

	Use this command if you need to log in as another Twitter user. When
	the Twitter authentication web page comes up, use the "Sign Out" link
	to log in as a different Twitter user and grant TwitVim access to that
	user.

	When you use SetLoginTwitter, TwitVim does not discard the previous
	access token. So you can switch back to the previous user using
	|:SwitchLoginTwitter|.

	This command has no effect in identi.ca and other Twitter-compatible
	services that use Basic authentication.


	:SwitchLoginTwitter				*:SwitchLoginTwitter*
	:SwitchLoginTwitter {username}

	Switch to another user from the list of saved access tokens. If
	{username} is not specified, SwitchLoginTwitter will display a list of
	user names and prompt you to select one of those.

	SwitchLoginTwitter knows only about user accounts to which you have
	logged in previously. To switch to a new user account, use
	|:SetLoginTwitter| instead.

	This command has no effect in identi.ca and other Twitter-compatible
	services that use Basic authentication.


	:ResetLoginTwitter				*:ResetLoginTwitter*

	This command discards the current OAuth access token and all saved
	tokens. The next TwitVim command that needs Twitter authentication
	will initiate an OAuth handshake.

	After using ResetLoginTwitter, you won't be able to switch to any
	users using |:SwitchLoginTwitter| because ResetLoginTwitter discards
	all saved access tokens.

	This command has no effect in identi.ca and other Twitter-compatible
	services that use Basic authentication.


	:FollowTwitter {username}			*:FollowTwitter*

	Start following user {username}'s timeline. If the user's timeline is
	protected, this command makes a request to follow that user.

	Note: This command does not enable notifications for the target user.
	If you need that, you'll have to do that separately through the web
	interface.


	:UnfollowTwitter {username}			*:UnfollowTwitter*

	Stop following user {username}'s timeline.


	:BlockTwitter {username}			*:BlockTwitter*

	Block user {username}.


	:UnblockTwitter {username}			*:UnblockTwitter*

	Unblock user {username}.


	:ReportSpamTwitter {username}			*:ReportSpamTwitter*

	Reports user {username} for spam. This command will also block the
	user.


	:EnableRetweetsTwitter {username}	*:EnableRetweetsTwitter*

	Start showing retweets from user {username} in friends timeline.
	
	Note: This option may not take effect immediately since Twitter uses
	cached data to construct the timeline.


	:DisableRetweetsTwitter {username}	*:DisableRetweetsTwitter*

	Stop showing retweets from user {username} in friends timeline.
	
	Note: This option may not take effect immediately since Twitter uses
	cached data to construct the timeline.


	:AddToListTwitter {listname} {username}		*:AddToListTwitter*

	Adds user {username} to list {listname}.


	:RemoveFromListTwitter {listname} {username}	*:RemoveFromListTwitter*

	Removes user {username} from list {listname}.


------------------------------------------------------------------------------
4.4. Mappings						*TwitVim-mappings*

	Alt-T						*TwitVim-A-t*
	Ctrl-T						*TwitVim-C-t*

	In visual mode, Alt-T posts the highlighted text to Twitter.

	Ctrl-T is an alternative to the Alt-T mapping. If the menu bar is
	enabled, Alt-T pulls down the Tools menu. So use Ctrl-T instead.


							*TwitVim-reply*
	Alt-R						*TwitVim-A-r*
	<Leader>r					*TwitVim-Leader-r*

	This mapping is local to the timeline buffer. In the timeline buffer,
	it starts composing an @-reply on the command line to the author of
	the tweet on the current line.

	Under Cygwin, Alt-R is not recognized so you can use <Leader>r as an
	alternative. The <Leader> character defaults to \ (backslash) but see
	|mapleader| for information on customizing that.


							*TwitVim-reply-all*
	<Leader>Ctrl-R					*TwitVim-Leader-C-r*

	This mapping is local to the timeline buffer. It starts composing a
	reply to all, i.e. a reply to the tweet author and also to everyone
	mentioned in @-replies on the current line.


							*TwitVim-retweet*
	<Leader>R					*TwitVim-Leader-S-r*

	This mapping (Note: uppercase 'R' instead of 'r'.) is local to the
	timeline buffer. It is similar to the retweet feature in popular
	Twitter clients. In the timeline buffer, it retweets the current line.


							*twitvim_old_retweet*
	If you prefer old-style retweets, add this to your vimrc:
>
		let twitvim_old_retweet = 1
<	
	The difference is an old-style retweet does not use the retweet API.
	Instead, it copies the current line to the command line so that you
	can repost it as a new tweet and optionally edit it or add your own
	comments. Note that an old-style retweet may end up longer than 140
	characters. If you have problems posting a retweet, try editing it to
	make it shorter.

						    *twitvim_retweet_format*
	If you use old-style retweets, you can configure the retweet format.
	By default, TwitVim retweets tweets in the following format:

		RT @user: text of the tweet

	You can customize the retweet format by adding the following to your
	vimrc, for example:
>
		let twitvim_retweet_format = 'Retweet from %s: %t'

		let twitvim_retweet_format = '%t (retweeted from %s)'
<
	When you retweet a tweet, TwitVim will replace "%s" in
	twitvim_retweet_format with the user name of the original poster and
	"%t" with the text of the tweet.

	The default setting of twitvim_retweet_format is "RT %s: %t"


							*TwitVim-direct-message*
	Alt-D						*TwitVim-A-d*
	<Leader>d					*TwitVim-Leader-d*

	This mapping is local to the timeline buffer. In the timeline buffer,
	it starts composing a direct message on the command line to the author
	of the tweet on the current line.

	Under Cygwin, Alt-D is not recognized so you can use <Leader>d as an
	alternative. The <Leader> character defaults to \ (backslash) but see
	|mapleader| for information on customizing that.

	Note: If you get a "403 Forbidden" error when you try to send a direct
	message, check if the user you're messaging is following you. That is
	the most common reason for this error when sending a direct message.


							*TwitVim-goto*
	Alt-G						*TwitVim-A-g*
	<Leader>g					*TwitVim-Leader-g*

	This mapping is local to the timeline and info buffers. It
	launches the web browser with the URL at the cursor position. If you
	visually select text before invoking this mapping, it launches the web
	browser with the selected text as is.

	Special cases:

	- If the cursor is on a word of the form @user or in the user: portion
	  at the beginning of a line, TwitVim displays that user's
	  timeline.

	- If the cursor is on a Name: line in the info buffer, TwitVim
	  displays that user's timeline.

	- If the cursor is on a word of the form #hashtag, TwitVim does a
	  Twitter Search for that #hashtag.

	- In a trending topics buffer, TwitVim does a Twitter Search for the
	  phrase on the cursor line.


							*twitvim_browser_cmd*
	Before using this command, you need to tell TwitVim how to launch your
	browser. For example, you can add the following to your vimrc:
>
		let twitvim_browser_cmd = 'firefox.exe'
<
	Of course, replace firefox.exe with the browser of your choice.


							*TwitVim-LongURL*
	<Leader>e					*TwitVim-Leader-e*

	This mapping is local to the timeline and info buffers. It
	calls the LongURL API (see http://longurl.org/) to expand the short
	URL at the cursor position. A short URL is a URL from a URL shortening
	service such as TinyURL, SnipURL, etc. Use this feature if you wish to
	preview a URL before browsing to it with |TwitVim-goto|.

	If you visually select text before invoking this mapping, it calls the
	LongURL API with the selected text as is.

	If successful, TwitVim will display the result from LongURL in the
	message area.


							*TwitVim-profile*
	<Leader>p					*TwitVim-Leader-p*

	This mapping is local to the timeline and info buffers. It
	calls the Twitter API to retrieve user profile information (e.g. name,
	location, bio, update count) for the user name at the cursor position.
	It displays the profile information in an info buffer.

	If you visually select text before invoking this mapping, it uses the
	selected text for the user name.

	See also |:ProfileTwitter|.


							*TwitVim-inreplyto*
	<Leader>@					*TwitVim-Leader-@*

	This mapping is local to the timeline buffer. If the current line is
	an @-reply tweet, it calls the Twitter API to retrieve the tweet to
	which this one is replying. Then it will display that predecessor
	tweet below the current one.
	
	If there is no in-reply-to information, it will show a warning and do
	nothing.

	This mapping is useful in the replies timeline. See |:RepliesTwitter|.


							*TwitVim-delete*
	<Leader>X					*TwitVim-Leader-X*

	This mapping is local to the timeline buffer. The 'X' in the mapping
	is uppercase. It calls the Twitter API to delete the tweet or message
	on the current line.

	Note: You have to be the author of the tweet in order to delete it.
	You can delete direct messages that you sent or received.


							*TwitVim-fave*
							*TwitVim-Leader-f*
	<Leader>f

	This mapping is local to the timeline buffer. It adds the tweet on the
	current line to your favorites.


							*TwitVim-unfave*
							*TwitVim-Leader-C-f*
	<Leader>Ctrl-F

	This mapping is local to the timeline buffer. It removes the tweet on
	the current line from your favorites.


	Ctrl-O						*TwitVim-C-o*

	This mapping takes you to the previous timeline in the timeline stack.
	See |:BackTwitter|.

	This mapping also works in the info buffer but uses a separate history
	stack. See |:BackInfoTwitter|.


	Ctrl-I						*TwitVim-C-i*

	This mapping takes you to the next timeline in the timeline stack.
	See |:ForwardTwitter|.

	This mapping also works in the info buffer but uses a separate history
	stack. See |:ForwardInfoTwitter|.


							*TwitVim-refresh*
	<Leader><Leader> 				*TwitVim-Leader-Leader*

	This mapping refreshes the timeline. See |:RefreshTwitter|.

	This mapping also works in the info buffer but is of limited utility
	there because that info shouldn't change as often as a timeline.
	See |:RefreshInfoTwitter|.


							*TwitVim-next*
	Ctrl-PageDown					*TwitVim-C-PageDown*

	This mapping loads the next (older) page in the timeline.
	See |:NextTwitter|.

	This mapping also works in the info buffer but only if the list is
	long enough to use more than one page. It does nothing in the user
	profile display. See |:NextInfoTwitter|.

	
							*TwitVim-previous*
	Ctrl-PageUp					*TwitVim-C-PageUp*

	This command loads the previous (newer) page in the timeline. If the
	timeline is on the first page, it issues a warning and doesn't do
	anything. See |:PreviousTwitter|.

	This mapping also works in the info buffer but only if the list is
	long enough to use more than one page. It does nothing in the user
	profile display. See |:PreviousInfoTwitter|.


------------------------------------------------------------------------------
4.5. Utility Commands					*TwitVim-utility*

	:Tweetburner					*:Tweetburner*
	:Tweetburner {url}

	Tweetburner is a URL forwarding and shortening service. See
	http://tweetburner.com/

	This command calls the Tweetburner API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:ATweetburner					*:ATweetburner*
	:ATweetburner {url}

	Same as :Tweetburner but appends, i.e. inserts after the current
	position instead of at the current position,  the short URL instead.

	:PTweetburner					*:PTweetburner*
	:PTweetburner {url}
	
	Same as :Tweetburner but prompts for a tweet on the command line with
	the short URL already inserted.


	:Snipurl					*:Snipurl*
	:Snipurl {url}

	SnipURL is a URL forwarding and shortening service. See
	http://www.snipurl.com/

	This command calls the SnipURL API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:ASnipurl					*:ASnipurl*
	:ASnipurl {url}

	Same as :Snipurl but appends, i.e. inserts after the current
	position instead of at the current position,  the short URL instead.

	:PSnipurl					*:PSnipurl*
	:PSnipurl {url}
	
	Same as :Snipurl but prompts for a tweet on the command line with
	the short URL already inserted.


	:Metamark					*:Metamark*
	:Metamark {url}

	Metamark is a URL forwarding and shortening service. See
	http://metamark.net/

	This command calls the Metamark API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:AMetamark					*:AMetamark*
	:AMetamark {url}

	Same as :Metamark but appends, i.e. inserts after the current
	position instead of at the current position,  the short URL instead.

	:PMetamark					*:PMetamark*
	:PMetamark {url}
	
	Same as :Metamark but prompts for a tweet on the command line with
	the short URL already inserted.


	:TinyURL					*:TinyURL*
	:TinyURL {url}

	TinyURL is a URL forwarding and shortening service. See
	http://tinyurl.com

	This command calls the TinyURL API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:ATinyURL					*:ATinyURL*
	:ATinyURL {url}

	Same as :TinyURL but appends, i.e. inserts after the current
	position instead of at the current position,  the short URL instead.

	:PTinyURL					*:PTinyURL*
	:PTinyURL {url}
	
	Same as :TinyURL but prompts for a tweet on the command line with
	the short URL already inserted.


	:BitLy						*:BitLy*
	:BitLy {url}

	bit.ly is a URL forwarding and shortening service. See
	http://bit.ly/

	This command calls the bit.ly API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	The bit.ly API requires a bit.ly login and a bit.ly API key. A default
	login and key pair is provided with TwitVim and no configuration is
	needed. However, if you wish to supply your own login and key to track
	your bit.ly history and stats, visit
	http://bit.ly/account/your_api_key to retrieve your API info and add
	the following to your vimrc:

							*twitvim_bitly_user*
							*twitvim_bitly_key*
>
		let twitvim_bitly_user = "username"
		let twitvim_bitly_key = "R_123456789"
<

	Replace username with your bit.ly login and R_123456789 with your
	bit.ly API key.

	:ABitLy						*:ABitLy*
	:ABitLy {url}

	Same as :BitLy but appends, i.e. inserts after the current
	position instead of at the current position, the short URL instead.

	:PBitLy						*:PBitLy*
	:PBitLy {url}
	
	Same as :BitLy but prompts for a tweet on the command line with
	the short URL already inserted.


	:IsGd						*:IsGd*
	:IsGd {url}

	is.gd is a URL forwarding and shortening service. See
	http://is.gd

	This command calls the is.gd API to get a short URL in place of <url>.
	If {url} is not provided on the command line, the command will prompt
	you to enter a URL. The short URL is then inserted into the current
	buffer at the current position.

	:AIsGd						*:AIsGd*
	:AIsGd {url}

	Same as :IsGd but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PIsGd						*:PIsGd*
	:PIsGd {url}
	
	Same as :IsGd but prompts for a tweet on the command line with the
	short URL already inserted.


	:UrlBorg					*:UrlBorg*
	:UrlBorg {url}

	urlBorg is a URL forwarding and shortening service. See
	http://urlborg.com

	This command calls the urlBorg API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	The urlBorg API requires an API key. A default API key is provided
	with TwitVim and no configuration is needed. However, if you wish to
	supply your own key in order to track your urlBorg history and stats,
	visit http://urlborg.com/a/account/ to retrieve your API key and then
	add the following to your vimrc:

							*twitvim_urlborg_key*
>
		let twitvim_urlborg_key = "12345-6789"
<
	Replace 12345-6789 with your API key.

	:AUrlBorg					*:AUrlBorg*
	:AUrlBorg {url}

	Same as :UrlBorg but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PUrlBorg					*:PUrlBorg*
	:PUrlBorg {url}
	
	Same as :UrlBorg but prompts for a tweet on the command line with the
	short URL already inserted.


	:Trim						*:Trim*
	:Trim {url}

	tr.im is a URL forwarding and shortening service. See http://tr.im/

	This command calls the tr.im API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	If you login to the tr.im API, tr.im will keep track
	of URLs that you have shortened. In order to do that, add the
	following to your vimrc:

							*twitvim_trim_login*
>
		let twitvim_trim_login = "trimuser:trimpassword"
<
	Where trimuser and trimpassword are your tr.im account user name and
	password.

	You may also specify trimuser:trimpassword as a base64 encoded string:
>
		let twitvim_trim_login = "base64string"
<
	See |TwitVim-login-base64| for information on generating base64
	strings.

	:ATrim						*:ATrim*
	:ATrim {url}

	Same as :Trim but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PTrim						*:PTrim*
	:PTrim {url}
	
	Same as :Trim but prompts for a tweet on the command line with the
	short URL already inserted.


	:Cligs						*:Cligs*
	:Cligs {url}

	Cligs is a URL forwarding and shortening service. See http://cli.gs/

	This command calls the Cligs API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	If you supply a Cligs API key, Cligs will keep track of URLs that you
	have shortened. In order to do that, add the following to your vimrc:

							*twitvim_cligs_key*
>
		let twitvim_cligs_key = "hexstring"
<
	where hexstring is the API key. You can get an API key by registering
	for a user account at Cligs and then visiting http://cli.gs/user/api

	:ACligs						*:ACligs*
	:ACligs {url}

	Same as :Cligs but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PCligs						*:PCligs*
	:PCligs {url}
	
	Same as :Cligs but prompts for a tweet on the command line with the
	short URL already inserted.


	:Zima						*:Zima*
	:Zima {url}

	Zima is a URL forwarding and shortening service. See http://zi.ma/

	This command calls the Zi.ma API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:AZima						*:AZima*
	:AZima {url}

	Same as :Zima but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PZima						*:PZima*
	:PZima {url}
	
	Same as :Zima but prompts for a tweet on the command line with the
	short URL already inserted.


	:Googl						*:Googl*
	:Googl {url}

	Goo.gl is Google's URL forwarding and shortening service.
	See http://goo.gl/

	This command calls the goo.gl API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:AGoogl						*:AGoogl*
	:AGoogl {url}

	Same as :Googl but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PGoogl						*:PGoogl*
	:PGoogl {url}
	
	Same as :Googl but prompts for a tweet on the command line with the
	short URL already inserted.


	:Rgala						*:Rgala*
	:Rgala {url}

	Rga.la is SoFurry.com's URL forwarding and shortening service.
	See http://rga.la/

	This command calls the Rga.la API to get a short URL in place of
	<url>. If {url} is not provided on the command line, the command will
	prompt you to enter a URL. The short URL is then inserted into the
	current buffer at the current position.

	:ARgala						*:ARgala*
	:ARgala {url}

	Same as :Rgala but appends, i.e. inserts after the current position
	instead of at the current position, the short URL instead.

	:PRgala						*:PRgala*
	:PRgala {url}
	
	Same as :Rgala but prompts for a tweet on the command line with the
	short URL already inserted.


	:[count]SearchTwitter					*:SearchTwitter*
	:[count]SearchTwitter {query}
	
	This command calls the Twitter Search API to search for {query}. If
	{query} is not provided on the command line, the command will prompt
	you for it. Search results are then displayed in the timeline buffer.

	All of the Twitter Search operators are supported implicitly. See
	http://search.twitter.com/operators for a list of search operators.

	If you specify [count], that number is used as the page number. For
	example, :2SearchTwitter hello displays the second page of search
	results for the word hello.

	You can configure the number of tweets returned by :SearchTwitter by
	setting |twitvim_count|.


	:RateLimitTwitter				*:RateLimitTwitter*

	This command calls the Twitter API to retrieve rate limit information.
	It shows the current hourly limit, how many API calls you have
	remaining, and when your quota will be reset. You can use it to check
	if you have been temporarily locked out of Twitter for hitting the
	rate limit. This command does not work on identi.ca.


	:ProfileTwitter					*:ProfileTwitter*
	:ProfileTwitter {username}

	This command calls the Twitter API to retrieve user profile
	information (e.g. name, location, bio, update count) for the specified
	user {username}. It displays the information in an info buffer.

	If {username} is not specified, this command will retrieve
	information for the currently logged-in user.

	See also |TwitVim-Leader-p|.


	:LocationTwitter {location}			*:LocationTwitter*

	This command calls the Twitter API to set the location field in your
	profile. There is no mandatory format for the location. It could be a
	zip code, a town, coordinates, or pretty much anything.

	For example:
>
	:LocationTwitter 10027
	:LocationTwitter New York, NY, USA
	:LocationTwitter 40.811583, -73.954486
<

	:TrendTwitter					*:TrendTwitter*

	This command retrieves a list of Twitter trending topics and displays
	them in the timeline buffer.

	In trending topics, |TwitVim-Leader-g| does a Twitter search for the
	phrase on the cursor line.

	By default, this command shows worldwide trends. To show regional
	trends, use |:SetTrendLocationTwitter| or set |twitvim_woeid|.


	:SetTrendLocationTwitter		 *:SetTrendLocationTwitter*

	This command displays a menu of trend locations by country and by
	town. It sets the region for |:TrendTwitter|.
	

							*twitvim_woeid*
	If you wish to set the default location for |:TrendTwitter| to
	something other than worldwide, set twitvim_woeid in your vimrc.
	
	For example:
>
		let twitvim_woeid = 2357024
<
	sets the location to Atlanta.
	
	You can find out what number to use for a location by checking the
	message displayed after |:SetTrendLocationTwitter| or by checking
	twitvim_woeid after |:SetTrendLocationTwitter|.


==============================================================================
5. Timeline Highlighting				*TwitVim-highlight*

	TwitVim uses a number of highlighting groups to highlight certain
	elements in the Twitter timeline views. See |:highlight| for details
	on how to customize these highlighting groups.

	twitterUser					*hl-twitterUser*
	
	The Twitter user name at the beginning of each line.

	twitterTime					*hl-twitterTime*

	The time a Twitter update was posted.

	twitterTitle					*hl-twitterTitle*

	The header at the top of the timeline view.

	twitterLink					*hl-twitterLink*

	Link URLs and #hashtags in a Twitter status.

	twitterReply					*hl-twitterReply*

	@-reply in a Twitter status.


==============================================================================
6. Tips and Tricks					*TwitVim-tips*

	Here are a few tips for using TwitVim more efficiently.


------------------------------------------------------------------------------
6.1. Timeline Hotkeys					*TwitVim-hotkeys*

	TwitVim does not autorefresh. However, you can make refreshing your
	timeline easier by mapping keys to the timeline commands. For example,
	I use the <F8> key for that:
>
		nnoremap <F8> :FriendsTwitter<cr>
		nnoremap <S-F8> :UserTwitter<cr>
		nnoremap <A-F8> :RepliesTwitter<cr>
		nnoremap <C-F8> :DMTwitter<cr>
<

------------------------------------------------------------------------------
6.2. Switching between identi.ca users			*TwitVim-switch*

	If you have multiple user accounts on identi.ca, you can add something
	like to following to your vimrc to make it easy to switch between
	those accounts:
>
		function! Switch_to_identica_user1()
		    let g:twitvim_api_root = "http://identi.ca/api"

		    let g:twitvim_login = "logininfo1"

		    FriendsTwitter
		endfunction

		function! Switch_to_identica_user2()
		    let g:twitvim_api_root = "http://identi.ca/api"

		    let g:twitvim_login = "logininfo2"

		    FriendsTwitter
		endfunction

		command! ToIdentica1 :call Switch_to_identica_user1()
		command! ToIdentica2 :call Switch_to_identica_user2()
<	
	With that in place, you can use :ToIdentica1 and :ToIdentica2 to
	switch between user accounts. There is a call to |:FriendsTwitter| at
	the end of each function to refresh the timeline view after switching.

	Note: This won't work on Twitter because logging in is handled via
	OAuth. Use |:SetLoginTwitter| or |:ResetLoginTwitter| instead to
	switch to a different Twitter user account.


------------------------------------------------------------------------------
6.3. Line length in status line				*TwitVim-line-length*

	Add the following to your |'statusline'| to display the length of the
	current line:
>
		%{strlen(getline('.'))}
<	
	This is useful if you compose tweets in a separate buffer and post
	them with |:CPosttoTwitter|. With the line length in your status line,
	you will know when you've reached the 140-character boundary.


==============================================================================
7. TwitVim History					*TwitVim-history*

	0.7.1 : 2011-09-21 * Added trending topics. |:TrendTwitter| and
			     |:SetTrendLocationTwitter|
			   * Some fixes for browser-launching issues.
			   * Fix for quoting issue when doing goo.gl URL
			     shortening with cURL network interface under
			     Windows.
			   * Support for HTML hex entities.
			   * Show 'follow request sent' in user profile
			     display if that is the case.
	0.7.0 : 2011-07-06 * Replaced many deprecated Twitter API calls with
			     updated versions.
			   * Improved XML parsing speed for high
			     |twitvim_count|.
			   * Added |:SwitchLoginTwitter| and other code to
			     support multiple saved OAuth logins.
	0.6.3 : 2011-05-13 * Expand t.co URLs in timeline displays.
			   * Added timeline filtering. |TwitVim-filter|
	0.6.2 : 2011-02-21 * Added more user relationship info to
			     |:ProfileTwitter|.
			   * Added |:EnableRetweetsTwitter| and
			     |:DisableRetweetsTwitter|.
			   * Switch to new (documented) goo.gl API.
			   * Added |:ListInfoTwitter|.
	0.6.1 : 2011-01-06 * Fix for buffer stack bug if user closes
			     a window manually.
			   * Use https OAuth endpoints if user has set up
			     https API root.
			   * Match a URL even if prefix is in mixed case.
	0.6.0 : 2010-10-27 * Added |:FollowingTwitter|, |:FollowersTwitter|.
			   * Added |:MembersOfListTwitter|,
			     |:SubsOfListTwitter|, |:OwnedListsTwitter|,
			     |:MemberListsTwitter|, |:SubsListsTwitter|,
			     |:FollowListTwitter|, |:UnfollowListTwitter|.
			   * Added support for goo.gl |:Googl| and Rga.la.
			     |:Rgala|
			   * Extended |TwitVim-Leader-g| to support Name: lines
			     in user profile and following/followers lists.
			   * Added history stack for info buffer.
			   * Added |:BackInfoTwitter|, |:ForwardInfoTwitter|,
			     |:RefreshInfoTwitter|, |:NextInfoTwitter|,
			     |:PreviousInfoTwitter| for the info buffer. Also
			     added support for |TwitVim-C-PageDown| and
			     |TwitVim-C-PageUp| in info buffer.
			   * Added twitvim filetype for user customization
			     via autocommands.
			   * Changed display of retweets to show the full
			     version instead of the truncated version
			     when the retweeted status is near the 
			     character limit.
			   * |:ProfileTwitter| with no argument now shows
			     info on logged-in user.
			   * Make |TwitVim-Leader-@| work on new-style
			     retweets by showing the retweeted status
			     as the parent.
	0.5.6 : 2010-09-19 * Exception handling for Python net interface.
			   * Added converter functions for non-UTF8 encoding
			     by @mattn_jp.
			   * Convert entities in profile name, bio, and
			     location. (Suggested by code933k)
			   * Fix for posting foreign chars when encoding is
			     not UTF8 and net method is not Curl.
			   * Support |twitvim_count| in |:DMTwitter| and
			     |:DMSentTwitter|.
			   * Added |:FavTwitter|.
			   * Added mappings to favorite and unfavorite tweets.
			     |TwitVim-Leader-f| |TwitVim-Leader-C-f|
	0.5.5 : 2010-08-16 * Added support for computing HMAC-SHA1 digests
			     using the openssl command line tool from the
			     OpenSSL toolkit. |TwitVim-OpenSSL|
	0.5.4 : 2010-08-11 * Added Ruby and Tcl versions of HMAC-SHA1 digest
			     code.
			   * Improved error messages for cURL users.
			   * Fix to keep |'nomodifiable'| setting from leaking
			     out into other buffers.
			   * Support Twitter SSL via Tcl interface.
			     |TwitVim-ssl-tcl|
	0.5.3 : 2010-06-23 * Improved error messages for most commands if 
			     using Perl, Python, Ruby, or Tcl interfaces.
			   * Added |:FollowTwitter|, |:UnfollowTwitter|,
			     |:BlockTwitter|, |:UnblockTwitter|,
			     |:ReportSpamTwitter|, |:AddToListTwitter|,
			     |:RemoveFromListTwitter|.
	0.5.2 : 2010-06-22 * More fixes for Twitter OAuth.
	0.5.1 : 2010-06-19 * Shorten auth URL with is.gd/Bitly if we need
			     to ask the user to visit it manually.
			   * Fixed the |:PublicTwitter| invalid request error.
			   * Include new-style retweets in user timeline.
	0.5.0 : 2010-06-16 * Switched to OAuth for user authentication on 
			     Twitter. |TwitVim-OAuth|
			   * Improved |:ProfileTwitter|.
	0.4.7 : 2010-03-13 * Added |:MentionsTwitter| as an alias for
			     |:RepliesTwitter|.
			   * Support |twitvim_count| in |:MentionsTwitter|.
			   * Fixed |twitvim_count| bug in |:ListTwitter|.
			   * Fixed Ruby interface problem with
			     Vim patch 7.2.374.
			   * Fixed |:BackTwitter| behavior when timeline
			     window is hidden by user.
			   * Handle SocketError exception in Ruby code.
	0.4.6 : 2010-02-05 * Added option to hide header in timeline buffer.
			     |TwitVim-hide-header|
	0.4.5 : 2009-12-20 * Prompt for login info if not configured.
			     |:SetLoginTwitter| |:ResetLoginTwitter|
			   * Reintroduced old-style retweet via
			     |twitvim_old_retweet|.
	0.4.4 : 2009-12-13 * Upgraded bit.ly API support to version 2.0.1
			     with configurable user login and key.
			   * Added support for Zima. |:Zima|
			   * Fixed :BackTwitter behavior when browsing
			     multiple lists.
			   * Added support for displaying retweets in
			     friends timeline.
			   * Use Twitter Retweet API to retweet.
			   * Added commands to display retweets to you or
			     by you. |:RetweetedToMeTwitter|
			     |:RetweetedByMeTwitter|
	0.4.3 : 2009-11-27 * Fixed some minor breakage in LongURL support.
			   * Added |:ListTwitter|
			   * Omit author's name from the list when doing a
			     reply to all. |TwitVim-reply-all|
	0.4.2 : 2009-06-22 * Bugfix: Reset syntax items in Twitter window.
			   * Bugfix: Show progress message before querying
			     for in-reply-to tweet.
			   * Added reply to all feature. |TwitVim-reply-all|
	0.4.1 : 2009-03-30 * Fixed a problem with usernames and search terms
			     that begin with digits.
	0.4.0 : 2009-03-09 * Added |:SendDMTwitter| to send direct messages
			     through API without relying on the "d user ..."
			     syntax.
			   * Modified Alt-D mapping in timeline to use
			     the :SendDMTwitter code.
			   * Added |:BackTwitter| and |:ForwardTwitter|
			     commands, Ctrl-O and Ctrl-I mappings to move back
			     and forth in the timeline stack.
			   * Improvements in window handling. TwitVim commands
			     will restore the cursor to the original window
			     when possible.
			   * Wrote some notes on using TwitVim with Twitter
			     SSL API.
			   * Added mapping to show predecessor tweet for an
			     @-reply. |TwitVim-inreplyto|
			   * Added mapping to delete a tweet or message.
			     |TwitVim-delete|
			   * Added commands and mappings to refresh the
			     timeline and load the next or previous page.
			     |TwitVim-refresh|, |TwitVim-next|,
			     |TwitVim-previous|.
	0.3.5 : 2009-01-30 * Added support for pagination and page length to
			     :SearchTwitter.
			   * Shortened default retweet prefix to "RT".
	0.3.4 : 2008-11-11 * Added |twitvim_count| option to allow user to
			     configure the number of tweets returned by
			     :FriendsTwitter and :UserTwitter.
	0.3.3 : 2008-10-06 * Added support for Cligs. |:Cligs|
	                   * Fixed a problem with not being able to unset
			     the proxy if using Tcl http.
	0.3.2 : 2008-09-30 * Added command to display rate limit info.
			     |:RateLimitTwitter|
			   * Improved error reporting for :UserTwitter.
			   * Added command and mapping to display user
			     profile information. |:ProfileTwitter|
			     |TwitVim-Leader-p|
			   * Added command for updating location.
			     |:LocationTwitter|
			   * Added support for tr.im. |:Trim|
			   * Fixed error reporting in Tcl http code.
	0.3.1 : 2008-09-18 * Added support for LongURL. |TwitVim-LongURL|
			   * Added support for posting multibyte/Unicode
			     tweets in cURL mode.
			   * Remove newlines from text before retweeting.
	0.3.0 : 2008-09-12 * Added support for http networking through Vim's
			     Perl, Python, Ruby, and Tcl interfaces, as
			     alternatives to cURL. |TwitVim-non-cURL|
			   * Removed UrlTea support.
	0.2.24 : 2008-08-28 * Added retweet feature. See |TwitVim-retweet|
	0.2.23 : 2008-08-25 * Support in_reply_to_status_id parameter.
			    * Added tip on line length in statusline.
			    * Report browser launch errors.
			    * Set syntax highlighting on every timeline refresh.
	0.2.22 : 2008-08-13 * Rewrote time conversion code in Vim script
			      so we don't need Perl or Python any more.
			    * Do not URL-encode digits 0 to 9.
	0.2.21 : 2008-08-12 * Added tips section to documentation.
			    * Use create_or_reuse instead of create in UrlBorg
			      API so that it will always generate the same
			      short URL for the same long URL.
			    * Added support for highlighting #hashtags and
			      jumping to Twitter Searches for #hashtags.
			    * Added Python code to convert Twitter timestamps
			      to local time and simplify them.
	0.2.20 : 2008-07-24 * Switched from Summize to Twitter Search.
			      |:SearchTwitter|
	0.2.19 : 2008-07-23 * Added support for non-Twitter servers
			      implementing the Twitter API. This is for
			      identi.ca support. See |twitvim-identi.ca|.
	0.2.18 : 2008-07-14 * Added support for urlBorg API. |:UrlBorg|
	0.2.17 : 2008-07-11 * Added command to show DM Sent Timeline.
	                      |:DMSentTwitter|
			    * Added support for pagination in Friends, User,
			      Replies, DM, and DM Sent timelines.
			    * Added support for bit.ly API and is.gd API.
			      |:BitLy| |:IsGd|
	0.2.16 : 2008-05-16 * Removed quotes around browser launch URL.
			    * Escape ! character in browser launch URL.
	0.2.15 : 2008-05-13 * Extend :UserTwitter and :FriendsTwitter to show
			      another user's timeline if argument supplied.
			    * Extend Alt-G mapping to jump to another user's
			      timeline if invoked over @user or user:
			    * Escape special Vim shell characters in URL when
			      launching web browser.
	0.2.14 : 2008-05-12 * Added support for Summize search API.
	0.2.13 : 2008-05-07 * Added mappings to launch web browser on URLs in
			      timeline.
	0.2.12 : 2008-05-05 * Allow user to specify Twitter login info and
			      proxy login info preencoded in base64.
			      |twitvim_login_b64| |twitvim_proxy_login_b64|
	0.2.11 : 2008-05-02 * Scroll to top in timeline window after adding
			      an update line.
			    * Add <Leader>r and <Leader>d mappings as
			      alternative to Alt-R and Alt-D because the
			      latter are not valid key combos under Cygwin.
	0.2.10 : 2008-04-25 * Shortened snipurl.com to snipr.com
			    * Added support for proxy authentication.
			      |twitvim_proxy_login|
			    * Handle Perl module load failure. Not that I
			      expect those modules to ever be missing.
	0.2.9 : 2008-04-23 * Added some status messages.
			   * Added menu items under Plugin menu.
			   * Allow Ctrl-T as an alternative to Alt-T to avoid
			     conflict with the menu bar.
			   * Added support for UrlTea API.
			   * Generalize URL encoding to all non-alpha chars.
	0.2.8 : 2008-04-22 * Encode URLs sent to URL-shortening services.
	0.2.7 : 2008-04-21 * Add support for TinyURL API. |:TinyURL|
			   * Add quick direct message feature.
			     |TwitVim-direct-message|
	0.2.6 : 2008-04-15 * Delete Twitter buffer to the blackhole register
			     to avoid stepping on registers unnecessarily.
			   * Quote login and proxy arguments before sending to
			     cURL.
			   * Added support for SnipURL API and Metamark API.
			     |:Snipurl| |:Metamark|
	0.2.5 : 2008-04-14 * Escape the "+" character in sent tweets.
			   * Added Perl code to convert Twitter timestamps to
			     local time and simplify them.
			   * Fix for timestamp highlight when the "|"
			     character appears in a tweet.
	0.2.4 : 2008-04-13 * Use <q-args> in Tweetburner commands.
			   * Improve XML parsing so that order of elements
			     does not matter.
			   * Changed T mapping to Alt-T to avoid overriding
			     the |T| command.
	0.2.3 : 2008-04-12 * Added more Tweetburner commands.
	0.2.2 : 2008-04-11 * Added quick reply feature.
			   * Added Tweetburner support. |:Tweetburner|
			   * Changed client ident to "from twitvim".
	0.2.1 : 2008-04-10 * Bug fix for Chinese characters in timeline.
			     Thanks to Leiyue.
			   * Scroll up to newest tweet after refreshing
			     timeline.
			   * Changed Twitter window name to avoid unsafe
			     special characters and clashes with file names.
	0.2.0 : 2008-04-09 * Added views for public, friends, user timelines,
			     replies, and direct messages. 
			   * Automatically insert user's posts into
			     public, friends, or user timeline, if visible.
			   * Added syntax highlighting for timeline view.
	0.1.2 : 2008-04-03 * Make plugin conform to guidelines in
    			    |write-plugin|.
			   * Add help documentation.
	0.1.1 : 2008-04-01 * Add error reporting for cURL problems.
	0.1   : 2008-03-28 * Initial release.


==============================================================================
8. TwitVim Credits					*TwitVim-credits*

	Thanks to Travis Jeffery, the author of the original VimTwitter script
	(vimscript #2124), who came up with the idea of running cURL from Vim
	to access the Twitter API.

	Techniques for managing the Twitter buffer were adapted from the NERD
	Tree plugin (vimscript #1658) by Marty Grenfell.


==============================================================================
vim:tw=78:ts=8:ft=help:norl:
