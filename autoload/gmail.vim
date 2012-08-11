" File: autoload/gmail.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)
"
" [TODO]
" - 添付ファイルは？？？
"
"
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

  call gmail#win#update_mailboxs(0)
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

function! gmail#exit()
  call gmail#win#all_close()
endfunction

function! gmail#checkNewMail()
  call gmail#imap#list(0)
  let target = ''
  let idx = 0
  for item in gmail#imap#get_mailbox()
    if item.dname =~ g:gmail_check_target_mail
"   if item.dname =~ g:gmail_default_mailbox
      let target = item.name
      break
    endif
    let idx += 1
  endfor

" let cnt = gmail#imap#status_unseen(target)
  let cnt = gmail#imap#status_recent(target)
  redraw
  if cnt > 0
    call gmail#util#message('You have ' . cnt . ' new mails!!' )
  elseif cnt == 0
    call gmail#util#message('There is no new mail.')
  else
    call gmail#util#message('Check new mail error.')
  endi
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
          call gmail#imap#store_seen(ids, 0)
          call gmail#win#reselect()
          call gmail#win#update_list(0, 1)
        endif
      elseif menu == 'readed'
        let ids = gmail#win#get_selections()
        if empty(ids)
          call gmail#util#message('Please select item by space key.')
        else
          call gmail#imap#store_seen(ids, 1)
          call gmail#win#reselect()
          call gmail#win#update_list(0, 1)
        endif
      elseif menu == 'delete'
        let ids = gmail#win#get_selections()
        if empty(ids)
          call gmail#util#message('Please select item by space key.')
        else
          if gmail#util#confirm('Delete selected files. Are you OK?[y/n]:') == 0
            call gmail#util#message('Cancel delete...')
            return
          endif
          call gmail#imap#store_deleted(ids, 1)
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
        if gmail#util#confirm('Send e-mail. Are you OK?[y/n]:') == 0
          call gmail#util#message('Cancel send...')
          return
        endif
        call gmail#smtp#send()
      endif
    endif
  endif
endfunction

function! gmail#update()
  if gmail#win#mode() == g:GMAIL_MODE_MAILBOX
    call gmail#win#update_cur_mailbox(line('.'))
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

