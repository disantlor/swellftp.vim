" TODO: implement as buffer autocommand (see stuff at bottom after finish)
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
	if ! strlen(l:nextDir) || (stridx(l:nextDir, $HOME) == 0 && strlen(l:nextDir) == strlen($HOME))
		echoerr 'No connection found. Create a ' . s:configFile . ' in your project''s root directory'
		return 0
	endif

	" search again
	call s:FindConnection(l:nextDir)

endfunction

function! b:Upload()

	let l:remoteBasePath = b:pushremote['mode'] . '://' . b:pushremote['user'] . '@' . b:pushremote['hostname'] . '/' . b:pushremote['remoteroot']
	let l:localRelativeFolder = substitute(expand('%:p:h'), b:pushremote['localroot'], '', '') | " find the folder relative to local root

	" prepare upload by setting user/pass if standard ftp
	if b:pushremote['mode'] == 'ftp' && has_key(b:pushremote, 'password')
		call NetUserPass(b:pushremote['user'], b:pushremote['password'])
	endif

	if b:pushremote['mode'] == 'scp'
		" create necessary directory (and all required parent directories)
		execute "!ssh " .
		\		b:pushremote['user'] . '@' . b:pushremote['hostname'] . 
		\		" mkdir -p " . b:pushremote['remoteroot'] . l:localRelativeFolder 
	endif

	" combine paths
	let l:remoteFilePath = l:remoteBasePath . l:localRelativeFolder . '/' . expand('%:t')

	" execute save
	exec 'write ' . l:remoteFilePath 

endfunction


" load connection
let s:configFile = '.pushremote-connection'
let s:here = substitute(expand('%:p:h'), '/\+$', '', '')
call s:FindConnection(s:here)

" bind Upload
command! Up call b:Upload()


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
