" Vim plugin file
" Author:       Maksim Ryzhikov <rv.maksim@gmail.com>
" Maintainer:		Maksim Ryzhikov <rv.maksim@gmail.com>
" Version:      1.0

if !exists(":Jstranslate")
	command! -nargs=* -complet=custom,Completer Jstranslate call JsTranslator('<args>')
endif

func! JsTranslator(...)
	let langpair = exists("g:langpair") ? g:langpair : "en|ru"
	let hl = strpart(langpair,0,2)
	let tl = strpart(langpair,3)
	let query = string(a:000)
	let result = system("xpcshell ~/.vim/bundle/vim-gtranslate/plugin/js/simple.js ".hl." ".tl." ".query)
	echo result
endfunction
