"if (exists('g:pushremote_loaded'))
"	finish
"endif
"let g:pushremote_loaded = 1

"function pushremote#Install(...)
	
	execute 'augroup pushremote'
		au!
		au BufNewFile * : call s:PrepareBuffer()
		"au BufReadPre * : call s:PrepareBuffer()
		au BufWinEnter * : call s:PrepareBuffer()
	augroup END

"endfunction

function! s:PrepareBuffer()

	if (exists('b:pushremote_prepared'))
		return
	endif

	let b:pushremote_prepared = 1

	" bind Upload
	command! Up call s:Upload()

endfunction


function! s:Upload()
	
	let l:here = substitute(expand('%:p:h'), '/\+$', '', '')

	" load connection before proceeding
	if (! exists('b:pushremote_connection'))
		call s:FindConnection(l:here)
	endif

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


" TODO: implement as buffer autocommand (see stuff at bottom after finish)
function! s:FindConnection(dir)
	
	let l:configFile = '.pushremote-connection'
	let l:connection = a:dir . '/' . l:configFile
	
	" if current directory contains a config file, load it and upload
	if (filereadable(l:connection))
		let b:pushremote_connection = l:connection
		exec 'source' . l:connection
		return 1
	endif

	" no config file found yet, move up one folder
	let l:nextDir = strpart(a:dir, 0,  match(a:dir, '/[^/]\+$'))

	" if home directory, then quit search and throw error
	if ! strlen(l:nextDir) || (stridx(l:nextDir, $HOME) == 0 && strlen(l:nextDir) == strlen($HOME))
		echoerr 'No connection found. Create a ' . l:configFile . ' in your project''s root directory'
		return 0
	endif

	" search again
	call s:FindConnection(l:nextDir)

endfunction
