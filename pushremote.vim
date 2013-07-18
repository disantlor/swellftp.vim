"if (exists('g:pushremote_loaded'))
"	finish
"endif
"let g:pushremote_loaded = 1

	
" bind Upload
command! Up call s:Upload()

function! s:Upload()
	let l:here = substitute(expand('%:p:h'), '/\+$', '', '')

	" load connection before proceeding
	if (! exists('b:pushremote'))
		call s:FindConnection(l:here)
	endif

	" defaults
	if (! has_key(b:pushremote, 'port'))
		let b:pushremote['port'] = '22'
	endif

	let l:remoteBasePath = '/' . b:pushremote['remoteroot']
	let l:localRelativeFolder = substitute(expand('%:p:h'), b:pushremote['localroot'], '', '') | " find the folder relative to local root

	" prepare upload by setting user/pass if standard ftp
	if b:pushremote['mode'] == 'ftp' && has_key(b:pushremote, 'password')
		call NetUserPass(b:pushremote['user'], b:pushremote['password'])
	endif

	if b:pushremote['mode'] == 'scp'
		" create necessary directory (and all required parent directories)
		execute "!ssh " . b:pushremote['user'] . '@' . b:pushremote['hostname'] . ' -p ' . b:pushremote['port']
		\				" mkdir -p " . b:pushremote['remoteroot'] . l:localRelativeFolder 
	endif

	" combine paths
	let l:remoteFilePath = l:remoteBasePath . l:localRelativeFolder . '/' . expand('%:t')

	" execute save
	exec 'write ' . b:pushremote['mode'] . '://' . b:pushremote['user'] . '@' . b:pushremote['hostname'] . ':' . b:pushremote['port'] . l:remoteFilePath 

endfunction

" Recursively search up folder tree from current file to find project's
" connection file
function! s:FindConnection(dir)
	
	let l:configFile = '.pushremote-connection'
	let l:connection = a:dir . '/' . l:configFile
	
	" if current directory contains a config file, load it and upload
	if (filereadable(l:connection))
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
