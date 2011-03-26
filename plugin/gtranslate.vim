" Vim plugin file
" Author:           Maksim Ryzhikov <rv.maksim@gmail.com>
" Maintainer:		Maksim Ryzhikov <rv.maksim@gmail.com>
" Version:          1.2.3
" ----------------------------------------------------------------------------
" Settings:
"          let g:vtranslate="T"       note: Translate selected text in visual-mode
"          :echohl <TAB>              note: Color tranlated text

if !exists(":Translate")
	command! -nargs=* -complet=custom,Gcomplete Translate call GoogleTranslator('<args>')
endif

"Auto-completion for google translator
func! Gcomplete(A,L,C)
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

"Translate text in visual mod
if exists("g:vtranslate")
	nnoremap <silent> <plug>TranslateBlockText :call TranslateBlockText()<cr>
	vnoremap <silent> <plug>TranslateBlockText <ESC>:call TranslateBlockText()<cr>
	let cmd = "vmap ".g:vtranslate." <Plug>TranslateBlockText"
	exec cmd
endif


"-------- new realization--------
func! TranslateBlockText()
	let start_v = col("'<") - 1
	let end_v = col("'>")
	let lines = getline("'<","'>")

	if len(lines) > 1
		let lines[0] = strpart(lines[0],start_v)
		let lines[-1] = strpart(lines[-1],0,end_v)
		let str = join(lines)
	else
		let str = strpart(lines[0],start_v,end_v-start_v)
	endif

	call GoogleTranslator(str)
endfunction


"-------- old realization--------
func! BlockTranslate()
	normal! gv"ay
	let s:str = @a
	call GoogleTranslator(s:str)
endfunction
"-------------------------------

func! GoogleTranslator(...)

	if !has("ruby")
		echohl ErrorMsg
		echon "Sorry, Google Translator requires ruby support. And ruby gem json"
		finish
	endif

	if !exists("g:langpair")
		echohl WarningMsg
		echon "Use default langpair. You must define g:langpair in .vimrc"
	endif

	let s:query = a:000
	let s:langpair = exists("g:langpair") ? g:langpair : "en|ru"

	func! Query()
		return s:query
	endfunction

	func! Langpair()
		return s:langpair
	endfunction

	call s:_cmdOutputText()

endfunction

func! s:_cmdOutputText()

ruby <<EOF
	require 'rubygems'
	require 'json'
	require 'cgi'
	require 'net/http'

	@max_length = 1000.0
	query = VIM::evaluate('Query()')
	langpair = VIM::evaluate('Langpair()')
	base_url = "http://ajax.googleapis.com/ajax/services/language/translate?v=2.0"

	len = (query.length/@max_length).ceil
	text = ""
	for i in (1..len)
		qry = query[(i-1)*@max_length..i*@max_length]
		url = "#{base_url}&q=#{URI.escape(qry)}&langpair=#{URI.escape(langpair)}"
		resp = Net::HTTP.get_response(URI.parse(url))
		data = resp.body
		result = JSON.parse(data)
		text += (result['responseStatus'] == 200) ? CGI.unescapeHTML(result['responseData']['translatedText']).gsub("'","\"") : "Invalid translation..."
	end

	VIM::evaluate("ViewTranlatedText('#{text}')")
EOF

endfunction

func! ViewTranlatedText(text)
		echon a:text
endfunction
