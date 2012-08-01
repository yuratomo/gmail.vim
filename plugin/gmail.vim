" File: plugin/gmail.vim
" Last Modified: 2012.07.20
" Author: yuratomo (twitter @yusetomo)
"

if !exists('g:gmail_command')
  let g:gmail_command = 'openssl'
endif

if !exists('g:gmail_imap')
  let g:gmail_imap = 'imap.gmail.com:993'
endif

if !exists('g:gmail_smtp')
  let g:gmail_smtp = 'smtp.gmail.com:465'
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

if !exists('g:gmail_signature')
  let g:gmail_signature = "// signathre"
endif

command! -nargs=0 Gmail :call gmail#start()

