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
" - リファクタリング

let g:gmail_timeout_for_unseen = 5000
let g:gmail_timeout_for_body   = 4000
let g:gmail_timeout = 2000
let g:gmail_search_key = 'ALL'
let [ g:GMAIL_MODE_MAILBOX, g:GMAIL_MODE_LIST, g:GMAIL_MODE_BODY, g:GMAIL_MODE_CREATE ] = range(4)

function! gmail#start()
  if gmail#imap#login() == 0
    return
  endif
  call gmail#imap#update_mailbox(0, 0)
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
      call gmail#imap#select(mbidx)
      call gmail#imap#update_list(0, 1)
    endif
  endif
endfunction

function! gmail#open()
  let l = line('.')
  if gmail#win#mode() == g:GMAIL_MODE_MAILBOX
    call gmail#imap#select(l-1)
    call gmail#imap#update_list(0, 1)
  elseif gmail#win#mode() == g:GMAIL_MODE_LIST
    if l == line('$')
      call gmail#imap#next_list()
    else
      call gmail#win#hilightLine('gmailSelect', l)
      let cline = getline('.')
      let line = split(cline[1:], ' ')
      call gmail#win#setline(line('.'), ' ' . cline[1:])
      call gmail#imap#body(line[0])
    endif
  elseif gmail#win#mode() == g:GMAIL_MODE_BODY
    if l == 1
      let head = gmail#imap#get_header()
      if expand('<cword>') == 'reply'
        call gmail#smtp#open(head.Return_Path, [], 'Re:' . head.Subject)
      elseif expand('<cword>') == 'reply_all'
        call gmail#smtp#open(head.Return_Path, head.Cc, 'Re:' . head.Subject)
      elseif expand('<cword>') == 'forward'
        call gmail#smtp#open('', [], 'Fw:' . head.Subject)
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
    call gmail#imap#update_mailbox(1, 1)
  elseif gmail#win#mode() == g:GMAIL_MODE_LIST
    call gmail#imap#update_list(0, 1)
  endif
endfunction

function! gmail#search()
  if gmail#win#mode() == g:GMAIL_MODE_LIST
    let g:gmail_search_key = input('search key:', g:gmail_search_key)
    call gmail#imap#update_list(0, 1)
  endif
endfunction

function! gmail#back()
  if gmail#win#mode() == g:GMAIL_MODE_CREATE
    call gmail#win#open(g:GMAIL_MODE_BODY)
  endif
endfunction
