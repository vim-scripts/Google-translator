" Vim plugin file
" Author:           Maksim Ryzhikov <rv.maaksim@gmail.com>
" Maintainer:		Maksim Ryzhikov <rv.maksim@gmail.com>
" Version:          1.0
" ----------------------------------------------------------------------------

if !exists(":Translate")
	command! -nargs=* Translate call GoogleTranslater('<args>')
endif


func! GoogleTranslater(...)

	if !has("ruby")
		echohl ErrorMsg
		echon "Sorry, Google Translater requires ruby support. And ruby gem json"
		finish
	endif

	if !exists("g:lengpair")
		echohl WarningMsg
		echon "Use default langpair. You must define g:lengpair in .vimrc"
	endif

	let s:query = a:000
	let s:langpair = exists("g:lengpair") ? g:lengpair : "en|ru"

	func! Query()
		return s:query
	endfunction

	func! Langpair()
		return s:langpair
	endfunction

ruby <<EOF
	require 'rubygems'
	require 'json'
	require 'net/http'
	query = VIM::evaluate('Query()')
	langpair = VIM::evaluate('Langpair()')
	base_url = "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0"
	url = "#{base_url}&q=#{URI.encode(query)}&langpair=#{URI.encode(langpair)}"
	resp = Net::HTTP.get_response(URI.parse(url))
	data = resp.body
	result = JSON.parse(data)
	text = (result['responseStatus'] == 200) ? result['responseData']['translatedText'] : "Invalid translation..."
	VIM::message(text)
EOF
endfunction
