"Author: Maksim Ryzhikov <rv.maksim@gmail.com>"

This plugin uses Ajax Google Translator ("http://ajax.googleapis.com/")

Depending:
1) Ruby          (Ubuntu: sudo apt-get install ruby)
2) Ruby gem json (Ubuntu: sudo gem install json)

Installation:
Put file in Vim plugin directory (.vim/plugin)
Add your .vimrc file string [ let g:lengpair="en|ru" ] whre "en" <- form English, to Russian ->"ru"

Use:
:Translate Hello World

About Jstranslate. (BETA)
This new implementation "Google Translator" for Vim. It is written in javascript and XPCOM.
To use it is necessary to have installed "xpcshell"
path to js file ~/.vim/bundle/vim-gtranslate/plugin/js/simple.js
:Jstranslate Hello World
