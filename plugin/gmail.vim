" File: plugin/gmail.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)

if exists('g:loaded_gmail') && g:loaded_gmail == 1
  finish
endif

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
  if exists('g:gmail_user_name')
    let g:gmail_signature = '# ' . g:gmail_user_name . '(by gmail.vim)'
  else
    let g:gmail_signature = '# This e-mail was sent by gmail.vim'
  endif
endif

if !exists('g:gmail_mailbox_trash')
  let g:gmail_mailbox_trash = "[Gmail]/trash"
endif

if !exists('g:gmail_timeout_for_search')
  let g:gmail_timeout_for_search = 4000
endif

if !exists('g:gmail_timeout_for_body')
  let g:gmail_timeout_for_body   = 10000
endif

if !exists('g:gmail_timeout')
  let g:gmail_timeout = 2000
endif

command! -nargs=0 Gmail             :call gmail#start()
command! -nargs=0 GmailChangeUser   :call gmail#changeUser()
command! -nargs=0 GmailExit         :call gmail#exit()
command! -nargs=0 GmailCheckNewMail :call gmail#checkNewMail()

nnoremap <silent> <Plug>(gmail_open)            :<C-u>call gmail#win#click()<CR>
nnoremap <silent> <Plug>(gmail_back)            :<C-u>call gmail#win#back()<CR>
nnoremap <silent> <Plug>(gmail_next_menu)       :<C-u>call gmail#win#tab(1)<CR>
nnoremap <silent> <Plug>(gmail_prev_menu)       :<C-u>call gmail#win#tab(-1)<CR>
nnoremap <silent> <Plug>(gmail_update)          :<C-u>call gmail#win#update()<cr>
nnoremap <silent> <Plug>(gmail_update_all)      :<C-u>call gmail#win#update_all()<cr>
nnoremap <silent> <Plug>(gmail_new_mail)        :<C-u>call gmail#smtp#open('',[],'',[])<CR>
nnoremap <silent> <Plug>(gmail_select_all)      :<C-u>call gmail#win#select_all()<CR>
nnoremap <silent> <Plug>(gmail_select_and_next) :<C-u>call gmail#win#select('.',  1, '')<CR>
nnoremap <silent> <Plug>(gmail_select_and_prev) :<C-u>call gmail#win#select('.', -1, '')<CR>
nnoremap <silent> <Plug>(gmail_delete)          :<C-u>call gmail#win#delete()<CR>
nnoremap <silent> <Plug>(gmail_mark_readed)     :<C-u>call gmail#win#mark_readed()<CR>
nnoremap <silent> <Plug>(gmail_mark_unreaded)   :<C-u>call gmail#win#mark_unreaded()<CR>
nnoremap <silent> <Plug>(gmail_archive)         :<C-u>call gmail#win#archive()<CR>

let g:loaded_gmail = 1
