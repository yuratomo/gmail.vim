" File: autoload/gmail.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)
"
" [TODO]
" - 添付ファイルは？？？
"
"
function! gmail#start()
  " check depend
  if !has('iconv')
    call gmail#util#message('gmail.vim depends on +iconv. Please use vim with +iconv.')
    return
  endif
  if !exists('g:loaded_vimproc')
    call gmail#util#message("gmail.vim depends on vimproc. Please install it.")
    return
  endif
  if !executable(g:gmail_command)
    call gmail#util#message("gmail.vim depends on openssl. Please install it.")
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

function! gmail#changeUser()
  unlet g:gmail_user_name
  unlet g:gmail_user_pass
  call gmail#start()
endfunction

function! gmail#checkNewMail()
  call gmail#imap#list(0)
  let target = ''
  let idx = 0
  for item in gmail#imap#get_mailbox()
    if item.dname =~ g:gmail_default_mailbox
      let target = item.name
      break
    endif
    let idx += 1
  endfor

  let cnt = gmail#imap#status_unseen(target)
  redraw
  if cnt > 0
    call gmail#util#message('You have ' . cnt . ' new mails!!' )
  elseif cnt == 0
    call gmail#util#message('There is no new mails.')
  else
    call gmail#util#message('Check new mail error.')
  endi
endfunction

