
let s:gmail_title_prefix = 'gmail-'
let s:gmail_winname = [ 'mailbox', 'list', 'body', 'new' ]

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

  nnoremap <buffer> <CR> :call gmail#open()<CR>
  nnoremap <buffer> <BS> :call gmail#back()<CR>
  nnoremap <buffer> u    :call gmail#update()<CR>
  nnoremap <buffer> s    :call gmail#search()<CR>
  nnoremap <buffer> c    :call gmail#smtp#open('',[],'')<CR>
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
