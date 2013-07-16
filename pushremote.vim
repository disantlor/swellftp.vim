" TODO: implement as buffer autocommand (see stuff at bottom after finish)
" TODO: doesn't seem to find connection file in parent dir???
function! s:FindConnection(dir)
	
	let l:connection = a:dir . '/' . s:configFile

	" if current directory contains a config file, load it and upload
	if (filereadable(l:connection))
		exec 'source ' . l:connection
		return 1
	endif

	" no config file found yet, move up one folder
	let l:nextDir = strpart(a:dir, 0,  match(a:dir, '/[^/]\+$'))

	" if home directory, then quit search and throw error
	if (!strlen(l:nextDir) || (stridx(l:nextDir, $HOME) == 0 && strlen(l:nextDir) == strlen($HOME))) 
		echoerr 'No connection found. Create a ' . s:configFile . ' in your project''s root directory'
		return 0
	endif

	" search again
	call s:FindConnection(l:nextDir)

endfunction

function! b:Upload()
	" compose base remote filepath
	let l:fileBasePath = b:pushremote['mode'] . '://' . b:pushremote['user'] . '@' . b:pushremote['hostname'] . '/' . b:pushremote['remoteroot']
	
	" find the file path relative to local root
	let l:fileRelativePath = substitute(expand('%:p'), b:pushremote['localroot'], '', '')

	" TODO: if relative path has a subfolder, need to make sure those exist remotely
	" or else upload will fail
	
	" prepare upload by setting user/pass if standard ftp
	if b:pushremote['mode'] == 'ftp' && has_key(b:pushremote, 'password')
		call NetUserPass(b:pushremote['user'], b:pushremote['password'])
	endif

	" combine paths
	let l:filePath = l:fileBasePath . l:fileRelativePath
	echo 'About to upload: ' . l:filePath


	" store previous error setting, then turn errors off
	" TODO: try/catch block?
	let l:netrw_errorlvl = g:netrw_errorlvl
	let g:netrw_errorlvl = 9999
	
	exec 'write ' . l:filePath 
	
	"" restore
	let g:netrw_errorlvl = l:netrw_errorlvl

endfunction

" load connection
let s:configFile = '.pushremote-connection'
let s:here = substitute(expand('%:p:h'), '/\+$', '', '')
call s:FindConnection(s:here)

" bind Upload
command! Upload 'call b:Upload()'


finish

if (exists('g:pushremote_loaded'))
	finish
endif
let g:pushremote_loaded = 1

function pushremote#Install(...)
	
	execute 'augroup ' . l:augroup
		au!
		execute 'au BufNewFile * : call s:PrepareBuffer(''BufNewFile'')'
		execute 'au BufReadPre * : call s:PrepareBuffer(''BufReadPre'')'
		execute 'au BufWinEnter * : call s:PrepareBuffer(''BufWinEnter'')'
	augroup END

endfunction

function s:PrepareBuffer(event, fname, dname, rootpath)

	if (exists('b:pushremote_prepared'))
		return
	endif

	let b:pushremote_prepared = 1
	let b:configFile = '.pushremote-connection'

	let l:here = substitute(expand('%:p:h'), '/\+$', '', '')

	call s:FindConnection(l:here)
	execute 'doautocmd ' . a:event . ' <buffer>'

endfunction
