" File: autoload/gmail/win.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)

let s:gmail_title_prefix = 'gmail-'
let s:gmail_winname = [ 'mailbox', 'list', 'body', 'new' ]
let s:gmail_list_menu = '   [more] [update] [unread] [readed] [delete]'
let s:gmail_body_menu = '[reply] [reply_all] [forward] [easy_html_view]'
let s:gmail_mailbox_item_count = 0

function! gmail#win#open(mode)
  let pref = s:gmail_winname[a:mode]
  let bufname = s:gmail_title_prefix . pref

  let winnum = winnr('$')
  for winno in range(1, winnum)
    let bn = bufname(winbufnr(winno))
    if bn == bufname
       exe winno . "wincmd w"
       return
    endif
  endfor

  if a:mode == g:GMAIL_MODE_MAILBOX
    vert new
    vert res 25
  elseif a:mode == g:GMAIL_MODE_LIST
    new
    wincmd K
    exe 'res ' . string(g:gmail_page_size+1)
  else
    let finded = 0
    let winnum = winnr('$')
    for winno in range(1, winnum)
      let bn = bufname(winbufnr(winno))
      let title_mbox = s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_MAILBOX]
      let title_list = s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_LIST]
      if bn != title_mbox && bn != title_list
         exe winno . "wincmd w"
         let finded = 1
      endif
    endfor
    if finded == 0
      botright new
      wincmd J
    endif
  endif

  silent edit `=bufname`
  setl bt=nofile noswf nowrap hidden nolist nomodifiable ft=gmail

  augroup gmail
    au!
    exe 'au BufDelete <buffer> call gmail#imap#exit()'
    exe 'au VimLeavePre * call gmail#imap#exit()'
  augroup END

  nnoremap <buffer> <CR>    :call gmail#open()<CR>
  nnoremap <buffer> <BS>    :call gmail#win#back()<CR>
  nnoremap <buffer> <TAB>   :call gmail#win#tab(1)<CR>
  nnoremap <buffer> <s-TAB> :call gmail#win#tab(-1)<CR>
  if a:mode == g:GMAIL_MODE_MAILBOX || a:mode == g:GMAIL_MODE_LIST
    nnoremap <buffer> u   :call gmail#update()<CR>
    nnoremap <buffer> s   :call gmail#search()<CR>
    nnoremap <buffer> c   :call gmail#smtp#open('',[],'')<CR>
    nnoremap <buffer> a   :call gmail#win#select_all()<CR>
    nnoremap <buffer> <space>   :call gmail#win#select('.',  1, '')<CR>
    nnoremap <buffer> <s-space> :call gmail#win#select('.', -1, '')<CR>
  endif
endfunction

function! gmail#win#setline(idx, txt)
  setl modifiable
  call setline(a:idx, a:txt)
  setl nomodifiable
endfunction

function! gmail#win#clear()
  setl modifiable
  % delete _
  setl nomodifiable
endfunction

function! gmail#win#hilightLine(name, line)
  call clearmatches()
  redraw
  call matchadd(a:name, '\%' . a:line . 'l')
  redraw
endfunction

function! gmail#win#mode()
  let bufname = bufname('%')
  if bufname =~ s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_MAILBOX]
    return g:GMAIL_MODE_MAILBOX
  elseif bufname =~ s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_LIST]
    return g:GMAIL_MODE_LIST
  elseif bufname =~ s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_BODY]
    return g:GMAIL_MODE_BODY
  elseif bufname =~ s:gmail_title_prefix . s:gmail_winname[g:GMAIL_MODE_CREATE]
    return g:GMAIL_MODE_CREATE
  endif
  return -1
endfunction

function! gmail#win#select(line, direct, mark)
  if gmail#win#mode() != g:GMAIL_MODE_LIST
    return
  endif
  let line = line(a:line)
  if line == 1
    return
  endif

  let l = getline(line)
  if len(l) > 0
    if a:mark == ''
      if l[0] == '>'
        let l = ' ' . l[1:]
      else
        let l = '>' . l[1:]
      endif
    else
      let l = a:mark . l[1:]
    endif
    call gmail#win#setline(line, l)
    call cursor(line+a:direct, 0)
  endif
endfunction

function! gmail#win#select_all()
  if gmail#win#mode() != g:GMAIL_MODE_LIST
    return
  endif

  let line = getline('.')
  if line[0] == '>'
    let mark = ' '
  else
    let mark = '>'
  endif

  for l in range(2, line('$'))
    call gmail#win#select(l, 0, mark)
  endfor
endfunction

function! gmail#win#get_selections()
  let ids = []
  if gmail#win#mode() != g:GMAIL_MODE_LIST
    return ids
  endif

  for line in getline(1, line('$'))
    if line[0] == '>'
      let item = split(line[2:], ' ')
      call add(ids, item[0])
    endif
  endfor
  return ids
endfunction

function! gmail#win#tab(direct)
  let mode = gmail#win#mode()
  let l = line('.')
  if l > 1
    if mode == g:GMAIL_MODE_LIST
      if a:direct == 1
        call cursor(1, 3)
      else
        call cursor(1, 1) 
        call cursor(1, col('$'))
      endif
    elseif mode == g:GMAIL_MODE_BODY
      if a:direct == 1
        call cursor(1, 1)
      else
        call cursor(1, 1) 
        call cursor(1, col('$'))
      endif
    endif
    return
  endif

  if mode == g:GMAIL_MODE_LIST
    call cursor(1, 0)
  elseif mode == g:GMAIL_MODE_BODY
    call cursor(1, 0)
  else
    return
  endif

  if a:direct == 1
    call feedkeys('f[', 'n')
  else
    call feedkeys('F[', 'n')
  endif
endfunction

function! gmail#win#back()
  if gmail#win#mode() == g:GMAIL_MODE_CREATE
    call gmail#win#open(g:GMAIL_MODE_BODY)
  endif
endfunction

function! gmail#win#update_mailbox(mode)
  call gmail#win#open(g:GMAIL_MODE_MAILBOX)
  call gmail#win#clear()
  call gmail#win#setline(1, gmail#imap#list(a:mode))
endfunction

function! gmail#win#select_mailbox(mb)
  let s:gmail_mailbox_item_count = gmail#imap#select(a:mb)
  call gmail#win#hilightLine('gmailSelect', a:mb+1)
  call gmail#win#setline(a:mb+1, gmail#imap#mailbox_line(a:mb))
  redraw
endfunction

function! gmail#win#show_body(id)
  call gmail#win#open(g:GMAIL_MODE_BODY)
  call gmail#win#clear()
  let list = gmail#imap#fetch_body(a:id)
  call gmail#win#setline(1, s:gmail_body_menu)
  call gmail#win#setline(2, list)
  call gmail#util#message('show message ok.')
endfunction

function! gmail#win#reselect()
  call gmail#win#open(g:GMAIL_MODE_MAILBOX)
  let s:gmail_mailbox_item_count = gmail#imap#select(gmail#imap#mailbox_index())
endfunction

function! gmail#win#newly_list()
  call gmail#win#reselect()
  call gmail#win#open(g:GMAIL_MODE_LIST)
  let newly_uids = gmail#imap#search_uids(g:gmail_search_key)

  call gmail#win#open(g:GMAIL_MODE_LIST)
  if len(newly_uids) > len(s:gmail_uids)
    let new_message_num = len(newly_uids) - len(s:gmail_uids)
    let fs = newly_uids[-new_message_num]
    let fe = newly_uids[-1]
    let s:gmail_uids = newly_uids
    let old_list = s:gmail_list
    let s:gmail_list = gmail#imap#fetch_header(fs, fe)
    call extend(s:gmail_list, old_list)
    call gmail#win#clear()
    call gmail#win#setline(1, s:gmail_list)
    redraw
  else
    call gmail#util#message('new message is nothing.')
  endif
endfunction

function! gmail#win#more_list()
  call gmail#win#update_list(s:gmail_page+1, 0)
endfunction

function! s:clear_list()
  if exists('s:gmail_list')
    unlet s:gmail_list
  endif
  if exists('s:gmail_uids')
    unlet s:gmail_uids
  endif
  let s:gmail_page = -1
endfunction

function! gmail#win#update_list(page, clear)
  if a:clear
    call s:clear_list()
  endif

  call gmail#win#open(g:GMAIL_MODE_LIST)
  call clearmatches()

  if !exists('s:gmail_page')
    let s:gmail_page = -1
  endif

  if !exists('s:gmail_list') || s:gmail_page != a:page
    if !exists('s:gmail_uids')
      if a:clear
        let s:gmail_uids = gmail#imap#search_uids(g:gmail_search_key)
      else
        let s:gmail_uids = range(1, s:gmail_mailbox_item_count)
      endif
    endif
    if empty(s:gmail_uids)
      call gmail#win#clear()
      return
    endif

    let last = len(s:gmail_uids)
    let is = last - g:gmail_page_size*a:page - g:gmail_page_size
    let ie = last - g:gmail_page_size*a:page - 1
    if is < 0
      let is = 0
    endif
    if ie < 0
      let ie = 0
    endif
    let fs = s:gmail_uids[is]
    let fe = s:gmail_uids[ie]
    if a:page == 0
      let s:gmail_list = []
      call insert(s:gmail_list, s:gmail_list_menu . ' search:' . g:gmail_search_key, 0)
    endif
    call extend(s:gmail_list, gmail#imap#fetch_header(fs, fe))
  endif

  call gmail#win#clear()
  call gmail#win#setline(1, s:gmail_list)
  redraw

  if a:page > 0
    call cursor(line('$'), 0)
  endif
  let s:gmail_page = a:page

endfunction
