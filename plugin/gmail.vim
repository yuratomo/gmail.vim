" File: plugin/gmail.vim
" Last Modified: 2012.07.20
" Author: yuratomo (twitter @yusetomo)
"

if !exists('g:gmail_command')
  let g:gmail_command = 'openssl'
endif

if !exists('g:gmail_server')
  let g:gmail_server = 'imap.gmail.com:993'
endif

if !exists('g:gmail_page_size')
  let g:gmail_page_size = 10
endif

if !exists('g:gmail_default_mailbox')
  let g:gmail_default_mailbox = 'INBOX'
endif

if !exists('g:gmail_default_encoding')
  let g:gmail_default_encoding = "iso-2022-jp"
endif

command! -nargs=0 Gmail :call gmail#start()

