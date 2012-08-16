" File: autoload/gmail/imap.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)

let s:gmail_mailbox_idx = 0
let s:gmail_body_separator = ''
let s:gmail_allow_headers = [ 'From', 'To', 'Cc', 'Bcc', 'Subject' ]
let s:gmail_headers = {'Cc':[]}
let s:gmail_login_now = 0
let [ s:CTE_7BIT, s:CTE_BASE64, s:CTE_PRINTABLE ] = range(3)

" LOGIN/LOGOUT
function! gmail#imap#login()
  if !exists('g:gmail_user_name')
    let g:gmail_user_name = input('input mail address:', '@gmail.com')
  endif
  if !exists('g:gmail_user_pass')
    let g:gmail_user_pass = inputsecret('input password:')
  endif
  call gmail#imap#exit()

  let cmd = [g:gmail_command, 's_client', '-connect', g:gmail_imap, '-quiet']
  let s:sub = vimproc#popen3(cmd)
  let ret = gmail#util#response(s:sub, '^* OK', g:gmail_timeout_for_body)
  if empty(ret)
    call s:common_error('connect', res)
    return 0
  endif

  let s:gmail_login_now = 1
  let res = s:request("? LOGIN " . g:gmail_user_name . " " . g:gmail_user_pass, g:gmail_timeout)
  let s:gmail_login_now = 0

  if s:is_response_error(res)
    call s:common_error('login', res)
    unlet g:gmail_user_pass
    return 0
  endif

  return 1
endfunction

function! s:relogin()
  let s:gmail_login_now = 1
  if gmail#imap#login() == 0
    call s:common_error('login', res)
    let s:gmail_login_now = 0
    return 0
  endif

  call gmail#imap#list(0)
  call gmail#imap#select(s:gmail_mailbox_idx)

  let s:gmail_login_now = 0
  return 1
endfunction

function! s:logout()
  call s:request("? LOGOUT", g:gmail_timeout)
endfunction

function! gmail#imap#exit()
  if exists('s:sub')
    try
      call s:sub.kill(9)
    catch /.*/
    endtry
    unlet s:sub
  endif
endfunction

" LIST

function! gmail#imap#list(mode)
  let idx = 1
  let s:gmail_mailbox = []
  let s:gmail_maibox_line = []

  let res = s:request('? LIST "" "*"', g:gmail_timeout)
  if s:is_response_error(res)
    call s:common_error('list', res)
    return
  endif

  for line in res[ 0 : -2 ]
    let s = strridx(line, '"', len(line)-2)
    let name = line[ s+1 : -2 ]
    let dname = gmail#util#decodeUtf7(name)
    call add(s:gmail_mailbox, { 'name' : name, 'dname' : dname } )
    if a:mode == 1
      let unseen = gmail#imap#status_unseen(s:gmail_mailbox[idx-1].name)
      if ret > 0
        let unseen = '(' . unseen . ')'
      else
        let unseen = ''
      endif
    else 
      let unseen = '(-)'
    endif
    call add(s:gmail_maibox_line, dname . unseen)
    redraw
    let idx += 1
  endfor
  return s:gmail_maibox_line
endfunction

function! gmail#imap#get_mailbox()
  if !exists('s:gmail_mailbox')
    return []
  endif
  return s:gmail_mailbox
endfunction

function! gmail#imap#mailbox_index()
  return s:gmail_mailbox_idx
endfunction

function! gmail#imap#mailbox_line(mb)
  return s:gmail_maibox_line[a:mb]
endfunction

function! gmail#imap#set_mailbox_line(mb, line)
  let s:gmail_maibox_line[a:mb] = a:line
endfunction

" SELECT

function! gmail#imap#select(mb)
  let item_count = 0
  let res =  s:request("? SELECT " . s:gmail_mailbox[a:mb].name, g:gmail_timeout)
  for r in res
    if r =~ "\d* EXISTS"
      let parts = split(r, ' ')
      let item_count = parts[1]
      break
    endif
  endfor
  let s:gmail_mailbox_idx = a:mb

  let s:gmail_unseens = gmail#imap#search('UNSEEN')
  let s:gmail_maibox_line[a:mb] = gmail#util#decodeUtf7(s:gmail_mailbox[a:mb].name . '(' . len(s:gmail_unseens) . ')')
  return item_count
endfunction

" FETCH

function! gmail#imap#fetch_header(fs, fe)
  let res = s:request("? FETCH " . a:fs . ":" . a:fe . " rfc822.header", g:gmail_timeout)
  let list = []
  if s:is_response_error(res)
    call s:common_error('fetch header', res)
    return list
  endif

  let [ date, subject, from, to, mark, number ] = [ '', '', '', '', '', '' ]
  for r in res
    let parts = split(r, ' ')
    if stridx(r, '*') == 0
      if index(s:gmail_unseens, parts[1]) >= 0
        let mark = ' *'
      else
        let mark = '  '
      endif
      let number = parts[1]
    elseif r == ")"
      call insert(list, join( [ mark, number, date, subject, '(From)' . from, '(To)' . to], ' '), 0)
    else
      let header = substitute(r, ':\s*', ':', '')
      let lidx = stridx(header, ':')
      let label = header[ 0 : lidx-1 ]
      let value = header[ lidx+1 : ]
      if value =~ '=?.*?='
        let value = gmail#util#decodeMime(value)
      endif
      if label == 'From'
        let from = value
      elseif label == 'To'
        let to = value
      elseif label == 'Subject'
        let subject = value
      elseif label == 'Date'
        let date = value
      endif
    endif
  endfor

  return list
endfunction

function! gmail#imap#fetch_body(id)
  let res = s:request("? FETCH " . a:id . " RFC822", g:gmail_timeout)
  if s:is_response_error(res)
    call s:common_error('fetch body', res)
    return []
  endif

  let list = []
  let [ _HEADER, _HEADER_MULTI_MIME_HEADER, _HEADER_MULTI_MIME_BODY, _BODY ] = range(4)
  let status = _HEADER
  let enc = g:gmail_default_encoding
  let cte = s:CTE_7BIT
  let b64txt = ''
  let output_now = 0
  let s:gmail_headers = {'Cc':[]}
  for r in res[1:-4]
    "echoerr r
    if status == _HEADER
      if r == ''
        call add(list, s:gmail_body_separator)
        let status = _BODY
      elseif r =~ '^Content-type:\s\?'
        let enc = s:parse_content_type(r)
        call gmail#util#message('encoding is ' . enc)
      elseif r =~ '^Content-Transfer-Encoding:'
        let cte = s:parse_content_transfer_encoding(r)
      else
        let coron = stridx(r, ':')
        let key = r[ 0 : coron-1 ]
        if index(s:gmail_allow_headers, key) != -1 || ( coron == -1 && output_now == 1 )
          if r =~ '=?.*?='
            let st = stridx(r, '=?')
            let encoded_value = r[0 : st-1] . gmail#util#decodeMime(r[st : ])
          else
            let encoded_value = r
          endif
          if coron == -1 && output_now == 1
            call add(list, remove(list, -1) . encoded_value)
          else
            call add(list, encoded_value)
          endif
          let output_now = 1
        else
          let encoded_value = r
          let output_now = 0
        endif
        "for header info
        if r =~ '^Subject:\s\?'
          let s:gmail_headers.Subject = substitute(encoded_value, 'Subject:\s\?', '', '')
        elseif r =~ '^Return-Path:\s\?'
          let s:gmail_headers.Return_Path = substitute(encoded_value, 'Return-Path:\s\?', '', '')
        elseif r =~ '^Cc:\s\?'
          call add(s:gmail_headers.Cc, substitute(encoded_value, 'Cc:\s\?', '', ''))
        endif
      endif
    elseif status == _BODY
      if r =~ '^--'
        let b64txt = ''
        let status = _HEADER_MULTI_MIME_HEADER
        let multipart_mark = r
      else
        if cte == s:CTE_7BIT
          call add(list, iconv(r, enc, &enc))
        else
          let b64txt .= r
        endif
      endif
    elseif status == _HEADER_MULTI_MIME_HEADER
      if r =~ '^Content-type:'
        let enc = s:parse_content_type(r)
      elseif r == ''
        let status = _HEADER_MULTI_MIME_BODY
      elseif r =~ '^Content-Transfer-Encoding:'
        let cte = s:parse_content_transfer_encoding(r)
      endif
    elseif status == _HEADER_MULTI_MIME_BODY
      if r =~ '^--'
        if cte == s:CTE_7BIT
          call extend(list, split(iconv(b64txt, enc, &enc), nr2char(10)))
        elseif cte == s:CTE_BASE64
          call extend(list, split(iconv(gmail#util#decodeBase64(b64txt), enc, &enc), nr2char(10)))
        elseif cte == s:CTE_PRINTABLE
          call extend(list, split(iconv(gmail#util#decodeQuotedPrintable(b64txt), enc, &enc), nr2char(10)))
        endif
        if r == multipart_mark
          let status = _BODY
        else
          let status = _HEADER_MULTI_MIME_HEADER
        endif
        let b64txt = ''
      else
        if cte == s:CTE_BASE64
          let b64txt .= r
        else
          let b64txt .= r . "\n"
        endif
      endif
    endif
  endfor

  if b64txt != '' && cte == s:CTE_BASE64
    call extend(list, split(iconv(gmail#util#decodeBase64(b64txt), enc, &enc), nr2char(10)))
  endif

  let g:gmail_encoding = enc
  return list
endfunction

" SEARCH

function! gmail#imap#search(key)
  let res = s:request("? SEARCH " . a:key, g:gmail_timeout_for_search)
  if s:is_response_error(res)
    call s:common_error('fetch search', res)
    return []
  endif
  let items = split(res[0], ' ')
  return items[ 2 : -1 ]
endfunction

function! gmail#imap#get_header()
  return s:gmail_headers
endfunction

" STATUS

function! gmail#imap#status_unseen(mailbox)
  return gmail#imap#status('UNSEEN', a:mailbox)
endfunction

function! gmail#imap#status_recent(mailbox)
  return gmail#imap#status('RECENT', a:mailbox)
endfunction

function! gmail#imap#status(stat, mailbox)
  let res = s:request('? STATUS "' .a:mailbox . '" (' . a:stat . ')', g:gmail_timeout)
  if s:is_response_error(res)
    call s:common_error('fetch status', res)
    return -1
  endif
  let parts = split(res[0], ' ')
  return parts[4][0 : -2 ]
endfunction

" STORE

function! gmail#imap#store_draft(id, sign)
  call s:request_store(a:id, '"\Draft', a:sign)
endfunction
function! gmail#imap#store_answered(id, sign)
  call s:request_store(a:id, '\Answered', a:sign)
endfunction
function! gmail#imap#store_flagged(id, sign)
  call s:request_store(a:id, '\Flagged', a:sign)
endfunction
function! gmail#imap#store_deleted(id, sign)
  call s:request_store(a:id, '\Deleted', a:sign)
endfunction
function! gmail#imap#store_recent(id, sign)
  call s:request_store(a:id, '\Recent', a:sign)
endfunction
function! gmail#imap#store_seen(id, sign)
  call s:request_store(a:id, '\Seen', a:sign)
endfunction

function! s:request_store(id, flag, sign)
  let sign = '+'
  if a:sign == 0
    let sign = '-'
  endif

  if type(a:id) == type([])
    let ids = join(a:id, ',')
  else
    let ids = a:id
  endif

  if type(a:flag) == type([])
    let flags = '(' . join(a:flag, ' ') . ')'
  else
    let flags = '(' . a:flag . ')'
  endif

  let res = s:request('? STORE ' . ids . ' ' . sign . 'FLAGS ' . flags, g:gmail_timeout)
  if s:is_response_error(res)
    call s:common_error('fetch store', res)
    return
  endif
endfunction

" NOOP

function! gmail#imap#noop()
  return s:common_request('NOOP', 100)
endfunction

" EXPUNGE

function! gmail#imap#expunge()
  return s:common_request('EXPUNGE', g:gmail_timeout)
endfunction

" INTERNAL

function! s:common_request(cmd, timeout)
  let res = s:request('? ' . a:cmd, g:gmail_timeout)
  if s:is_response_error(res)
    call s:common_error(a:cmd, res)
  endif
  return res
endfunction

function! s:request(cmd, timeout)
  let cmd = a:cmd . "\r\n"
  if s:gmail_login_now == 0
    call gmail#util#message(a:cmd)
  endif

  try
    call s:sub.stdin.write(cmd)
  catch /.*/
    if s:relogin() == 0
      return []
    endif
    call s:sub.stdin.write(cmd)
  endtry

  let ret = gmail#util#response(s:sub, '^? ', a:timeout)
  if empty(ret)
    if s:gmail_login_now == 0
      if s:relogin() == 0
        return []
      endif
      let ret = s:request(a:cmd, a:timeout)
      return ret
    endif
  endif
  return ret
endfunction

function! s:is_response_error(res)
  if empty(a:res) || a:res[-1] !~ '? OK'
    return 1
  endif
endfunction

function! s:parse_content_type(line)
  let st = stridx(a:line, 'charset=')
  if st == -1
    return g:gmail_default_encoding
  endif
  let st = st+8
  if a:line[st] == '"'
    let st += 1
  endif
  let ed = match(a:line, '[\";]', st)
  if ed == -1
    let ed = strlen(a:line)
  endif
  let enc = a:line[ st : ed-1 ]
  return enc
endfunction

function! s:parse_content_transfer_encoding(line)
  if a:line =~ '.*7bit'
    return s:CTE_7BIT
  elseif a:line =~ '.*base64'
    return s:CTE_BASE64
  elseif a:line =~ '.*quoted-printable'
    return s:CTE_PRINTABLE
  endif
  return s:CTE_7BIT
endfunction

function! s:common_error(cmd, res)
  call gmail#util#error('imap ' . a:cmd . ' error. (' . join(a:res, ',') . ')')
endfunction

