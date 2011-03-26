" Vim plugin file
" Author:       Maksim Ryzhikov <rv.maksim@gmail.com>
" Maintainer:		Maksim Ryzhikov <rv.maksim@gmail.com>
" Version:      1.0

if !exists(":Jstranslate")
	command! -nargs=* -complet=custom,Completer Jstranslate call JsTranslator('<args>')
endif

func! Completer(A,L,C)
	let lines = getline(0,'$')
	let wlist = []
	for line in lines
		let words = split(line, '\W\+')
		if len(words) > 0
			let wlist = add(wlist,join(words,"\n"))
		endif
	endfor
	let result = join(wlist,"\n")
	return result
endfunction

func! JsTranslator(...)
	let langpair = exists("g:langpair") ? g:langpair : "en|ru"
	let hl = strpart(langpair,0,1)
	let tl = strpart(langpair,3)
	let query = string(a:000)
	let result = system("xpcshell ~/.vim/bundle/vim-gtranslate/plugin/js/simple.js ".hl." ".tl." \"".query."\"")
	echo result
endfunction
