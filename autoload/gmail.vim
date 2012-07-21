
" http://wiki.mediatemple.net/w/Email_via_IMAP_using_Telnet
" http://www.lins.jp/~obata/imap/rfc/rfc2060ja.html#s6.4.4
" http://www.atmarkit.co.jp/fmobile/rensai/imap04/imap04.html
"
" 添付ファイルは？？？
" メール送信しらべる smtp x openssl
" http://bobpeers.com/technical/telnet_imap
" http://b.ruyaka.com/2010/08/11/openssl-s_client%E3%81%A7gmail%E3%83%A1%E3%83%BC%E3%83%AB%E9%80%81%E4%BF%A1/
" http://d.hatena.ne.jp/yatt/20110728/1311868549
" http://code-life.net/?p=1679
"

let s:gmail_search_key = 'ALL'
let s:gmail_title_prefix = 'gmail-'
let s:gmail_timeout = 200
let s:gmail_mailbox_idx = 0
let s:gmail_encoding = ''
let [ s:MODE_MAILBOX, s:MODE_LIST, s:MODE_BODY ] = range(3)

function! gmail#start()
  call s:login()
  call s:mailbox(0)
  if g:gmail_default_mailbox != ''
    let mbidx = -1
    let idx = 0
    for item in s:gmail_mailbox
      if item.name =~ g:gmail_default_mailbox
        let mbidx = idx
        break
      endif
      let idx += 1
    endfor
    if mbidx != -1
      call s:select(mbidx)
      call s:list(0, 1)
    endif
  endif
endfunction

function! gmail#exit()
  if exists('s:sub')
    try
      call s:sub.kill(9)
    catch /.*/
    endtry
    unlet s:sub
  endif
endfunction

function! gmail#open()
  let l = line('.')
  if s:mode() == s:MODE_MAILBOX
    call s:select(l-1)
    call s:list(0, 1)
  elseif s:mode() == s:MODE_LIST
    if l == line('$')
      call s:list(s:gmail_page+1, 0)
    else
      call s:hilightLine('gmailSelect', l)
      let cline = getline('.')
      let line = split(cline[1:], ' ')
      call s:setline(line('.'), ' ' . cline[1:])
      call s:body(line[0])
    endif
  endif
endfunction

function! gmail#update()
  if s:mode() == s:MODE_MAILBOX
    if exists('s:gmail_mailbox')
      unlet s:gmail_mailbox
    endif
    call s:mailbox(1)
  elseif s:mode() == s:MODE_LIST
    if exists('s:gmail_uids')
      unlet s:gmail_uids
    endif
    if exists('s:gmail_list')
      unlet s:gmail_list
    endif
    call s:list(0, 1)
  endif
endfunction

function! gmail#search()
  if s:mode() == s:MODE_LIST
    let s:gmail_search_key = input('search key:', s:gmail_search_key)
    unlet s:gmail_list
    unlet s:gmail_uids
    call s:list(0, 1)
  endif
endfunction

function! s:login()
  let s:gmail_login_now = 1
  call s:openWindow(s:MODE_MAILBOX)
  if !exists('g:gmail_user_name')
    let g:gmail_user_name = input('input mail address:', '@gmail.com')
  endif
  if !exists('g:gmail_user_pass')
    let g:gmail_user_pass = input('input password:')
  endif

  let cmd = [g:gmail_command, 's_client', '-connect', g:gmail_server, '-quiet']
  let s:sub = vimproc#popen3(cmd)
  let cnt = 0
  while !s:sub.stdout.eof
    let line = substitute(s:sub.stdout.read(), nr2char(10), '', 'g')
    if line != ''
      call s:message(line)
      if stridx(line, '* OK') >= 0
        break
      endif
    else
      sleep 10ms
      let cnt += 1
      if cnt >= s:gmail_timeout
        call s:message('login timeout!!')
        let s:gmail_login_now = 0
        return
      endif
    endif
  endwhile

  call s:request("? LOGIN " . g:gmail_user_name . " " . g:gmail_user_pass)
  let s:gmail_login_now = 0
endfunction

function! s:relogin()
  let mode = s:mode()
  call gmail#exit()
  call s:login()
  call s:select(s:gmail_mailbox_idx)
  call s:openWindow(mode)
endfunction

function! s:logout()
  let res = s:request("? LOGOUT")
  call s:setline(1, res)
endfunction

function! s:mailbox(mode)
  call s:openWindow(s:MODE_MAILBOX)

  call s:clear()
  if !exists('s:gmail_mailbox')
    let idx = 1
    let s:gmail_mailbox = []
    let s:gmail_maibox_line = []
    let results = s:request('? LIST "" "*"')
    for line in results[ 0 : -2 ]
      let s = strridx(line, '"', len(line)-2)
      call add(s:gmail_mailbox, { 'name' : line[ s+1 : -2 ] } )
      if a:mode == 1
        let stat = s:request('? STATUS "' . s:gmail_mailbox[idx-1].name . '" (UNSEEN)')
        if len(stat) > 1
          let stats = split(stat[0], ' ')
          let unseen = '(' . stats[4]
        else
          let unseen = ''
        endif
      else 
        let unseen = '(-)'
      endif
      call add(s:gmail_maibox_line, s:decodeUtf7(s:gmail_mailbox[idx-1].name . unseen))
      call s:setline(idx, s:gmail_maibox_line[idx-1])
      redraw
      let idx += 1
    endfor
  else
    call s:setline(1, s:gmail_maibox_line)
  endif
endfunction

function! s:select(mb)
  call s:request("? SELECT " . s:gmail_mailbox[a:mb].name)
  let s:gmail_mailbox_idx = a:mb
  call s:hilightLine('gmailSelect', a:mb+1)

  let res = s:request("? SEARCH UNSEEN")
  if len(res) == 0
    call s:message('select error(' . a:mb . ')')
    return
  endif
  let uitems = split(res[0], ' ')
  let s:gmail_unseens = uitems[ 2 : -1 ]
  let unseen = '(' . len(s:gmail_unseens) . ')'
  let s:gmail_maibox_line[a:mb] = s:decodeUtf7(s:gmail_mailbox[a:mb].name . unseen)

  call s:setline(a:mb+1, s:gmail_maibox_line[a:mb])
  redraw
endfunction

function! s:list(page, clear)
  if a:clear && exists('s:gmail_list')
    unlet s:gmail_list
    unlet s:gmail_uids
  endif

  call s:openWindow(s:MODE_LIST)
  call clearmatches()

  if !exists('s:gmail_page')
    let s:gmail_page = -1
  endif

  if !exists('s:gmail_list') || s:gmail_page != a:page

    if !exists('s:gmail_uids')
      let res = s:request("? SEARCH " . s:gmail_search_key)
      let items = split(res[0], ' ')
      let s:gmail_uids = items[ 2 : -1 ]
    endif
    if !exists('s:gmail_uids')
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
      let ins_pos = 0
    else
      let s:gmail_list = s:gmail_list[ 0 : -2 ]
      let ins_pos = len(s:gmail_list)
    endif

    let res = s:request("? FETCH " . fs . ":" . fe . " (FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT DATE FROM )])")
    let mail = ''
    for r in res
      let parts = split(r, ' ')
      if stridx(r, '*') == 0
        if index(s:gmail_unseens, parts[1]) >= 0
          let mark = '*'
        else
          let mark = ' '
        endif
        let mail = mark . parts[1] . ' '
      elseif r == ")"
        call insert(s:gmail_list, mail, ins_pos)
      elseif r =~ '=?.*?='
        let mail .= s:decodeMime(r)
      else
        let parts = split(r, ': ')
        if len(parts) > 1
          let mail .= parts[1] . ' '
        endif
      endif
    endfor

    call add(s:gmail_list, 'next  search:' . s:gmail_search_key)
  endif

  call s:clear()
  call s:setline(1, s:gmail_list)
  redraw

  if a:page > 0
    call cursor(line('$'), 0)
  endif

  let s:gmail_page = a:page
endfunction

function! s:body(id)
  call s:openWindow(s:MODE_BODY)
  call s:clear()
  let res = s:request("? FETCH " . a:id . " (body[header.fields (from to subject date)])")
  let list = []
  let mail = ''
  for r in res[1:-4]
    let parts = split(r, ' ')
    if r == ")"
      call add(list, mail)
    elseif r =~ '=?.*?='
      let mail .= s:decodeMime(r)
    else
      call add(list, r)
    endif
  endfor
  call add(list, '                                                                  ')
  call s:setline(1, list)
  call s:hilightLine('gmailHorizontal', len(list))
  let res = s:request("? FETCH " . a:id . " RFC822.TEXT")
  call s:setline(line('$')+1, map(res[1 : -3], "iconv(v:val, s:gmail_encoding, &enc)"))
endfunction

function! s:request(cmd)
  let cmd = a:cmd . "\r\n"

  if s:gmail_login_now == 0
    call s:message(a:cmd)
  endif

  try
    call s:sub.stdin.write(cmd)
  catch /.*/
    if s:gmail_login_now == 0
      call s:relogin()
      call s:sub.stdin.write(cmd)
    endif
  endtry

  let cnt = 0
  let res = ''
  let end = 0
  while !s:sub.stdout.eof
    let line = substitute(s:sub.stdout.read(), nr2char(10), '', 'g')
    if line != ''
      let res = res . line
      for line2 in split(line, "\r")
        if stridx(line2, '? ') == 0
          let end = 1
          break
        endif
      endfor
      if end == 1
        break
      endif
    else
      sleep 10ms
      let cnt += 1
      if cnt >= s:gmail_timeout
        call s:message('request timeout!!')
        if s:gmail_login_now == 0
          let s:gmail_login_now = 1
          call s:relogin()
          let ret = s:request(a:cmd)
          let s:gmail_login_now = 0
          return ret
        else
          return []
        endif
      endif
    endif
  endwhile
  return split(res, "\r")
endfunction

function! s:openWindow(mode)
  let pref = ''
  if a:mode == s:MODE_MAILBOX
    let pref = 'mailbox'
  elseif a:mode == s:MODE_LIST
    let pref = 'list'
  elseif a:mode == s:MODE_BODY
    let pref = 'body'
  endif
  let bufname = s:gmail_title_prefix . pref

  let winnum = winnr('$')
  for winno in range(1, winnum)
    let bn = bufname(winbufnr(winno))
    if bn == bufname
       exe winno . "wincmd w"
       return
    endif
  endfor

  if a:mode == s:MODE_MAILBOX
    vert new
    vert res 25
  elseif a:mode == s:MODE_LIST
    new
    wincmd K
    exe 'res ' . string(g:gmail_page_size+1)
  else
    let winnum = winnr('$')
    for winno in range(1, winnum)
      let bn = bufname(winbufnr(winno))
      if stridx(bn, s:gmail_title_prefix) != 0
         exe winno . "wincmd w"
      endif
    endfor
  endif

  silent edit `=bufname`
  setl bt=nofile noswf nowrap hidden nolist nomodifiable ft=gmail

  augroup gmail
    au!
    exe 'au BufDelete <buffer> call gmail#exit()'
    exe 'au VimLeavePre * call gmail#exit()'
  augroup END

  nnoremap <buffer> <CR> :call gmail#open()<CR>
  nnoremap <buffer> u    :call gmail#update()<CR>
  nnoremap <buffer> s    :call gmail#search()<CR>

endfunction

function! s:decodeUtf7(str)
  let mod1 = substitute(a:str, '&', '+', '')
  let mod2 = substitute(mod1, '&-', '&', 'g')
  let mod3 = substitute(mod2, ',', '/', 'g')
  return iconv(mod3, 'UTF-7', &enc)
endfunction

function! s:decodeMime(str)
  let end   = strridx(a:str, '?=')
  let start = strridx(a:str, '?', end-1)
  if start == -1 || end == -1
    return a:str
  endif

  let enc_e = strridx(a:str, '?', start-1)
  let enc_s = strridx(a:str, '=?', enc_e-1)
  if enc_s == -1
    let enc = g:gmail_default_encoding
  else
    let enc = a:str[ enc_s+2 : enc_e-1 ]
  endif
  let s:gmail_encoding = enc
  return iconv(s:decodeBase64(a:str[ start+1 : end-1 ]), enc, &enc)
endfunction

function! s:setline(idx, txt)
  setl modifiable
  call setline(a:idx, a:txt)
  setl nomodifiable
endfunction

function! s:clear()
  setl modifiable
  % delete _
  setl nomodifiable
endfunction

function! s:mode()
  let bufname = bufname('%')
  if bufname =~ s:gmail_title_prefix . 'mailbox'
    return s:MODE_MAILBOX
  elseif bufname =~ s:gmail_title_prefix . 'list'
    return s:MODE_LIST
  elseif bufname =~ s:gmail_title_prefix . 'body'
    return s:MODE_BODY
  endif
  return -1
endfunction

function! s:hilightLine(name, line)
  call clearmatches()
  redraw
  call matchadd(a:name, '\%' . a:line . 'l')
  redraw
endfunction

function! s:message(msg)
  echon 'gmail:' . a:msg
  redraw
endfunction

let s:standard_table = [
      \ "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
      \ "Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
      \ "g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v",
      \ "w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"]

function! s:encodeBase64(data)
  let b64 = s:b64encode(s:str2bytes(a:data), s:standard_table, '=')
  return join(b64, '')
endfunction

function! s:decodeBase64(data)
  try
    let bytes = s:b64decode(split(a:data, '\zs'), s:standard_table, '=')
    return s:bytes2str(bytes)
  catch /.*/
    return a:data
  endtry
endfunction

function! s:b64decode(b64, table, pad)
  let a2i = {}
  for i in range(len(a:table))
    let a2i[a:table[i]] = i
  endfor
  let bytes = []
  for i in range(0, len(a:b64) - 1, 4)
    let n = a2i[a:b64[i]] * 0x40000
          \ + a2i[a:b64[i + 1]] * 0x1000
          \ + (a:b64[i + 2] == a:pad ? 0 : a2i[a:b64[i + 2]]) * 0x40
          \ + (a:b64[i + 3] == a:pad ? 0 : a2i[a:b64[i + 3]])
    call add(bytes, n / 0x10000)
    call add(bytes, n / 0x100 % 0x100)
    call add(bytes, n % 0x100)
  endfor
  if a:b64[-1] == a:pad
    unlet a:b64[-1]
  endif
  if a:b64[-2] == a:pad
    unlet a:b64[-1]
  endif
  return bytes
endfunction

function! s:b64encode(bytes, table, pad)
  let b64 = []
  for i in range(0, len(a:bytes) - 1, 3)
    let n = a:bytes[i] * 0x10000
          \ + get(a:bytes, i + 1, 0) * 0x100
          \ + get(a:bytes, i + 2, 0)
    call add(b64, a:table[n / 0x40000])
    call add(b64, a:table[n / 0x1000 % 0x40])
    call add(b64, a:table[n / 0x40 % 0x40])
    call add(b64, a:table[n % 0x40])
  endfor
  if len(a:bytes) % 3 == 1
    let b64[-1] = a:pad
    let b64[-2] = a:pad
  endif
  if len(a:bytes) % 3 == 2
    let b64[-1] = a:pad
  endif
  return b64
endfunction

function! s:bytes2str(bytes)
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

