" AUTHOR:     Maksim Ryzhikov
" Maintainer: Maksim Ryzhikov <rv.maksim@gmail.com>
" VERSION:    1.3.1b
" DONE: remove json dependency, g:vtranslate, g:langpair, fix encoding
" ADD: configuration variable
" TODO: fix output text with quotes in nodejs

"@configuration
function! s:googMergeConf(gconf,uconf)
  if type(a:gconf) == 4 && type(a:uconf) == 4
    for key in keys(a:uconf)
        let a:gconf[key] = a:uconf[key]
    endfor
  endif
endfunction

let s:goog_conf = { 'langpair' : 'en|ru', 'cmd' : 'ruby'}


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
  let outp = ""

  "call sub translator
  if s:goog_conf.cmd == "ruby"
    let outp = s:_googRBTranslate(s:query)
  elseif s:goog_conf.cmd == "node"
    let outp = system("node ~/.vim/bundle/vim-translator/plugin/js/goog-translator-coffee.js ".string(s:query).' '.string(s:goog_conf.langpair))
  elseif s:goog_conf.cmd == "lua"
    let outp = s:_googLuaTranslate(s:query)
  endif

  if has_key(s:goog_conf, 'charset')
    echo iconv(outp,s:goog_conf.charset,&enc)
  else
    echo outp
  endif

  return outp
endfunction

"sub translator is implemented on lua
"@return String
function! s:_googLuaTranslate(query)
    silent! exec "luafile ~/.vim/bundle/vim-translator/plugin/goog-translator.lua"
    return s:outp
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
        url = URI.parse(path(text))
        http = Net::HTTP.new(url.host,url.port)
        req = Net::HTTP::Get.new(url.request_uri)
        req.initialize_http_header({
          'User-Agent' => 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1'
        })

        jstxt = http.request(req).body
        resp = eval(jstxt.gsub(/,{2,}/,","))

        CGI.unescapeHTML(resp.first.first.first)
      end

      def langpair
        @langpair ||= "en|ru"
      end

      protected
      def host
        @host ||= "http://translate.google.com"
      end

      def path(text)
        hl, tl = langpair.split("|")
        sl = hl
        %Q{#{host}/translate_a/t?client=t&text=#{CGI.escape(text)}&hl=#{hl}&sl=#{sl}&tl=#{tl}&multires=1&otf=1&trs=1&sc=1}
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
