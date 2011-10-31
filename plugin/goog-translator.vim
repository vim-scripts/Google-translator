" AUTHOR:     Maksim Ryzhikov
" Maintainer: Maksim Ryzhikov <rv.maksim@gmail.com>
" VERSION:    1.3.0b
" DONE: remove json dependency, g:vtranslate, g:langpair
" ADD: configuration variable
" TODO: fix output text with quotes, some problem with encoding, add
" implementation on javascript for v8 and nodejs

"@configuration
function! s:googMergeConf(gconf,uconf)
  if type(a:gconf) == 4 && type(a:uconf) == 4
    for key in keys(a:uconf)
        let a:gconf[key] = a:uconf[key]
    endfor
  endif
endfunction

let s:goog_conf = { 'charset': 'utf-8', 'langpair' : 'en|ru'}


"@complete
"gets words from open file
function! s:GoogComplete(A,L,C) abort
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

"@visual mode
"translate block text
function! GoogTranslateBlock() abort
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

  call s:GoogTranslate(str)
endfunction

"global translator function
"@return String
function! s:GoogTranslate(...)
  "define variable
  let s:query = a:000

  "call sub translator
  let outp = s:_googRBTranslate(s:query)

  echo iconv(outp,s:goog_conf.charset,&enc)

  return outp
endfunction

"sub translator is implemented on ruby
"@return String
function! s:_googRBTranslate(query)
  "warnings
  if !has("ruby")
    echohl ErrorMsg
    echon "Sorry, Google Translator requires ruby support"
    finish
  endif

  let result = ""

ruby <<EOF
  require 'uri'
  require 'cgi'
  require 'net/http'

  class RBTranslator #singleton
    class << self
      attr_accessor :langpair

      def translate(text)
        url = construct_uri(text)
        jstxt = Net::HTTP.get(URI.parse(url))
        resp = eval(jstxt.gsub(/,{2,}/,","))

        CGI.unescapeHTML(resp.first.first.first)
      end

      def langpair
        @langpair ||= "en|ru"
      end

      protected

      def host
        @host ||= "http://translate.google.com/translate_a/t?client=t&text="
      end

      def construct_uri(text)
        hl, tl = langpair.split("|")
        sl = hl
        %Q{#{host}#{CGI.escape(text)}&hl=#{hl}&sl=#{sl}&tl=#{tl}&multires=1&otf=1&trs=1&sc=1}
      end
    end
  end

  lng = VIM::evaluate("s:goog_conf.langpair")
  query = VIM::evaluate("a:query")
  query = query.join(" ") if query.is_a?(Array)

  RBTranslator.langpair = lng
  outp = query.to_s.scan(/(.{1,200})/).flatten.inject('') do |result,str|
    result += RBTranslator.translate(str)
  end

  VIM::command('let s:outp = "%s"' % outp)

EOF

  return s:outp
endfunction

"Declaration/check global functions and variables
if exists('g:goog_user_conf')
  call s:googMergeConf(s:goog_conf, g:goog_user_conf)
endif

if !exists(":Translate")
	command! -nargs=* -complet=custom,s:GoogComplete Translate call s:GoogTranslate('<args>')
endif

if exists("s:goog_conf.v_key")
	nnoremap <silent> <plug>TranslateBlockText :call GoogTranslateBlock()<cr>
	vnoremap <silent> <plug>TranslateBlockText <ESC>:call GoogTranslateBlock()<cr>
	let cmd = "vmap ".s:goog_conf.v_key." <Plug>TranslateBlockText"
	exec cmd
endif
