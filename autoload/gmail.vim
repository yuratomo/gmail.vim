" File: autoload/gmail.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)
"
" [参考]
" - http://wiki.mediatemple.net/w/Email_via_IMAP_using_Telnet
" - http://www.lins.jp/~obata/imap/rfc/rfc2060ja.html#s6.4.4
" - http://www.atmarkit.co.jp/fmobile/rensai/imap04/imap04.html
" - http://bobpeers.com/technical/telnet_imap
" - http://b.ruyaka.com/2010/08/11/openssl-s_client%E3%81%A7gmail%E3%83%A1%E3%83%BC%E3%83%AB%E9%80%81%E4%BF%A1/
" - http://d.hatena.ne.jp/yatt/20110728/1311868549
" - http://code-life.net/?p=1679
" - http://d.hatena.ne.jp/hogem/20100122/1264169093
" - http://www.hidekik.com/cookbook/p2h.cgi?id=smtptext
"
" [TODO]
" - 添付ファイルは？？？
"
"
let g:gmail_timeout_for_unseen = 5000
let g:gmail_timeout_for_body   = 5000
let g:gmail_timeout = 2000
let g:gmail_search_key = 'ALL'
let [ g:GMAIL_MODE_MAILBOX, g:GMAIL_MODE_LIST, g:GMAIL_MODE_BODY, g:GMAIL_MODE_CREATE ] = range(4)

function! gmail#start()
  " check depend
  if !has('iconv')
    call gmail#util#message('gmail.vim is depend on  iconv. Please install it.')
    return
  endif
  if !exists('g:loaded_vimproc')
    call gmail#util#message("gmail.vim is depend on vimproc. Please install it.")
    return
  endif
  if !executable(g:gmail_command)
    call gmail#util#message("gmail.vim is depend on openssl. Please install it.")
    return
  endif

  if gmail#imap#login() == 0
    return
  endif

  call gmail#win#update_mailbox(0)
  if g:gmail_default_mailbox != ''
    let mbidx = -1
    let idx = 0
    for item in gmail#imap#get_mailbox()
      if item.name =~ g:gmail_default_mailbox
        let mbidx = idx
        break
      endif
      let idx += 1
    endfor
    if mbidx != -1
      call gmail#win#select_mailbox(mbidx)
      call gmail#win#update_list(0, 1)
    endif
  endif
endfunction

function! gmail#open()
  let l = line('.')
  if gmail#win#mode() == g:GMAIL_MODE_MAILBOX
    call gmail#win#select_mailbox(l-1)
    call gmail#win#update_list(0, 1)
  elseif gmail#win#mode() == g:GMAIL_MODE_LIST
    if l == 1
      let menu = expand('<cword>')
      if menu == 'more'
        call gmail#win#more_list()
      elseif menu == 'update'
        call gmail#win#newly_list()
      elseif menu == 'unread'
        let ids = gmail#win#get_selections()
        if empty(ids)
          call gmail#util#message('Please select item by space key.')
        else
          for id in ids
            call gmail#imap#store_unseen(id, 1)
            call gmail#imap#store_seen(id, 0)
          endfor
          call gmail#win#reselect()
          call gmail#win#update_list(0, 1)
        endif
      elseif menu == 'readed'
        let ids = gmail#win#get_selections()
        if empty(ids)
          call gmail#util#message('Please select item by space key.')
        else
          for id in ids
            call gmail#imap#store_unseen(id, 0)
            call gmail#imap#store_seen(id, 1)
          endfor
          call gmail#win#reselect()
          call gmail#win#update_list(0, 1)
        endif
      elseif menu == 'delete'
        let ids = gmail#win#get_selections()
        if empty(ids)
          call gmail#util#message('Please select item by space key.')
        else
          for id in ids
            call gmail#imap#store_deleted(id, 1)
          endfor
          call gmail#win#reselect()
          call gmail#win#update_list(0, 1)
        endif
      endif
    else
      call gmail#win#hilightLine('gmailSelect', l)
      let cline = getline('.')
      let line = split(cline[2:], ' ')
      call gmail#win#setline(line('.'), '  ' . cline[2:])
      call gmail#win#show_body(line[0])
    endif
  elseif gmail#win#mode() == g:GMAIL_MODE_BODY
    if l == 1
      let head = gmail#imap#get_header()
      let menu = expand('<cword>')
      if menu == 'reply'
        call gmail#smtp#open(head.Return_Path, [], 'Re:' . head.Subject)
      elseif menu == 'reply_all'
        call gmail#smtp#open(head.Return_Path, head.Cc, 'Re:' . head.Subject)
      elseif menu == 'forward'
        call gmail#smtp#open('', [], 'Fw:' . head.Subject)
      elseif menu == 'easy_html_view'
        call gmail#util#neglect_htmltag()
      endif
    endif
  elseif gmail#win#mode() == g:GMAIL_MODE_CREATE
    if l == 1
      if expand('<cword>') == 'send'
        call gmail#smtp#send()
      endif
    endif
  endif
endfunction

function! gmail#update()
  if gmail#win#mode() == g:GMAIL_MODE_MAILBOX
    call gmail#win#update_mailbox(1)
  elseif gmail#win#mode() == g:GMAIL_MODE_LIST
    call gmail#win#update_list(0, 1)
  endif
endfunction

function! gmail#search()
  if gmail#win#mode() == g:GMAIL_MODE_LIST
    let g:gmail_search_key = input('search key:', g:gmail_search_key)
    call gmail#win#update_list(0, 1)
  endif
endfunction

