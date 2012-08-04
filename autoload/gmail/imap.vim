let s:gmail_mailbox_idx = 0
let s:gmail_body_separator = ''
let s:gmail_body_menu  = '[reply] [reply_all] [forward] [easy_html_view]'
let s:gmail_allow_headers = [ 'From', 'To', 'Cc', 'Bcc', 'Subject' ]
let s:gmail_headers = {'Cc':[]}

function! gmail#imap#login()
  if !exists('g:gmail_user_name')
    let g:gmail_user_name = input('input mail address:', '@gmail.com')
  endif
  if !exists('g:gmail_user_pass')
    let g:gmail_user_pass = input('input password:')
  endif

  let cmd = [g:gmail_command, 's_client', '-connect', g:gmail_imap, '-quiet']
  let s:sub = vimproc#popen3(cmd)
  let ret = gmail#util#response(s:sub, '^* OK', g:gmail_timeout_for_body)
  if empty(ret)
    call gmail#util#message('imap connect error.')
    return 0
  endif

  let s:gmail_login_now = 1
  let ret = s:request("? LOGIN " . g:gmail_user_name . " " . g:gmail_user_pass, g:gmail_timeout)
  let s:gmail_login_now = 0
  if empty(ret)
    call gmail#util#message('imap login error.')
    return 0
  endif

  return 1
endfunction

function! s:relogin()
  let mode = gmail#win#mode()
  call gmail#imap#exit()
  if gmail#imap#login() == 0
    call gmail#util#message('imap login error.')
    return 0
  endif
  call gmail#imap#select(s:gmail_mailbox_idx)
  call gmail#win#open(mode)
  return 1
endfunction

function! s:logout()
  let res = s:request("? LOGOUT", g:gmail_timeout)
  call gmail#win#setline(1, res)
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

"
" mailbox
"
function! gmail#imap#get_mailbox()
  return s:gmail_mailbox
endfunction

function! gmail#imap#update_mailbox(mode, clear)
  if a:clear
    unlet s:gmail_mailbox
  endif
  call gmail#win#open(g:GMAIL_MODE_MAILBOX)
  call gmail#win#clear()
  if !exists('s:gmail_mailbox')
    let idx = 1
    let s:gmail_mailbox = []
    let s:gmail_maibox_line = []
    let results = s:request('? LIST "" "*"', g:gmail_timeout)
    for line in results[ 0 : -2 ]
      let s = strridx(line, '"', len(line)-2)
      call add(s:gmail_mailbox, { 'name' : line[ s+1 : -2 ] } )
      if a:mode == 1
        let stat = s:request('? STATUS "' . s:gmail_mailbox[idx-1].name . '" (UNSEEN)', g:gmail_timeout)
        if len(stat) > 1
          let stats = split(stat[0], ' ')
          let unseen = '(' . stats[4]
        else
          let unseen = ''
        endif
      else 
        let unseen = '(-)'
      endif
      call add(s:gmail_maibox_line, gmail#util#decodeUtf7(s:gmail_mailbox[idx-1].name . unseen))
      call gmail#win#setline(idx, s:gmail_maibox_line[idx-1])
      redraw
      let idx += 1
    endfor
  else
    call gmail#win#setline(1, s:gmail_maibox_line)
  endif
endfunction

function! gmail#imap#select(mb)
  call s:request("? SELECT " . s:gmail_mailbox[a:mb].name, g:gmail_timeout)
  let s:gmail_mailbox_idx = a:mb
  call gmail#win#hilightLine('gmailSelect', a:mb+1)

  let res = s:request("? SEARCH UNSEEN", g:gmail_timeout_for_unseen)
  if len(res) == 0
    call gmail#util#message('imap search unseen error(' . a:mb . ')')
    return
  endif
  let uitems = split(res[0], ' ')
  let s:gmail_unseens = uitems[ 2 : -1 ]
  let unseen = '(' . len(s:gmail_unseens) . ')'
  let s:gmail_maibox_line[a:mb] = gmail#util#decodeUtf7(s:gmail_mailbox[a:mb].name . unseen)

  call gmail#win#setline(a:mb+1, s:gmail_maibox_line[a:mb])
  redraw
endfunction

"
" list
"
function! s:clear_list()
  if exists('s:gmail_list')
    unlet s:gmail_list
  endif
  if exists('s:gmail_uids')
    unlet s:gmail_uids
  endif
endfunction

function! gmail#imap#next_list()
  call gmail#imap#update_list(s:gmail_page+1, 0)
endfunction

function! gmail#imap#update_list(page, clear)
  if a:clear
    call s:clear_list()
  endif

  call gmail#win#open(g:GMAIL_MODE_LIST)
  call clearmatches()
  call gmail#win#clear()

  if !exists('s:gmail_page')
    let s:gmail_page = -1
  endif

  if !exists('s:gmail_list') || s:gmail_page != a:page

    if !exists('s:gmail_uids')
      let res = s:request("? SEARCH " . g:gmail_search_key, g:gmail_timeout)
      if empty(res)
        call gmail#util#message('imap search error.')
        return
      endif
      let items = split(res[0], ' ')
      let s:gmail_uids = items[ 2 : -1 ]
    endif
    if !exists('s:gmail_uids') || len(s:gmail_uids) <= 0
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

    let res = s:request("? FETCH " . fs . ":" . fe . " (FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT DATE FROM )])", g:gmail_timeout)
    if empty(res)
      call gmail#util#message('imap fetch error.')
      return
    endif

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
        let mail .= gmail#util#decodeMime(r)
      else
        let parts = split(r, ':')
        if len(parts) > 1
          let mail .= parts[1] . ' '
        endif
      endif
    endfor

    call add(s:gmail_list, '[next]  search:' . g:gmail_search_key)
  endif

  call gmail#win#setline(1, s:gmail_list)
  redraw

  if a:page > 0
    call cursor(line('$'), 0)
  endif

  let s:gmail_page = a:page
endfunction

"
" body
"
function! gmail#imap#body(id)
  call gmail#win#open(g:GMAIL_MODE_BODY)
  call gmail#win#clear()
  let res = s:request("? FETCH " . a:id . " RFC822", g:gmail_timeout)
  let list = []
  let [ _HEADER, _HEADER_MULTI_MIME_HEADER, _HEADER_MULTI_MIME_BODY, _BODY ] = range(4)
  let status = _HEADER
  let enc = g:gmail_default_encoding
  let b64txt = ''
  let output_now = 0
  let s:gmail_headers = {}
  let s:gmail_headers.Cc = []
  for r in res[1:-4]
    "call add(list, r) "debug
    if status == _HEADER
      if r == ''
        call add(list, s:gmail_body_separator)
        let status = _BODY
      elseif r =~ '^Content-type:\s\?'
        let enc = s:parse_content_type(r)
        call gmail#util#message('encoding is ' . enc)
      else
        let coron = stridx(r, ':')
        let key = r[ 0 : coron-1 ]
        if index(s:gmail_allow_headers, key) != -1 || ( coron == -1 && output_now == 1 )
          if r =~ '=?.*?='
            let st = stridx(r, '=?')
            let encoded_value = r[0:st-1] . gmail#util#decodeMime(r[st+1:])
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
      else
        call add(list, iconv(r, enc, &enc))
      endif
    elseif status == _HEADER_MULTI_MIME_HEADER
      if r =~ '^Content-type:'
        let enc = s:parse_content_type(r)
      elseif r == ''
        let status = _HEADER_MULTI_MIME_BODY
      endif
    elseif status == _HEADER_MULTI_MIME_BODY
      if r =~ '^--'
        call extend(list, split(iconv(gmail#util#decodeBase64(b64txt), enc, &enc), nr2char(10)))
        let status = _BODY
      else
        let b64txt .= r . "\n"
      endif
    endif
  endfor
  call gmail#win#setline(1, s:gmail_body_menu)
  call gmail#win#setline(2, list)
  let g:gmail_encoding = enc
endfunction

function! gmail#imap#get_header()
  return s:gmail_headers
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

"
" common
"
function! s:request(cmd, timeout)
  let cmd = a:cmd . "\r\n"

  if s:gmail_login_now == 0
    call gmail#util#message(a:cmd)
  endif

  try
    call s:sub.stdin.write(cmd)
  catch /.*/
    if s:gmail_login_now == 0
      if s:relogin() == 0
        return []
      endif
      call s:sub.stdin.write(cmd)
    endif
  endtry

  let ret = gmail#util#response(s:sub, '^? ', a:timeout)
  if empty(ret)
    if s:gmail_login_now == 0
      let s:gmail_login_now = 1
      if s:relogin() == 0
        return []
      endif
      let ret = s:request(a:cmd, a:timeout)
      let s:gmail_login_now = 0
      return ret
    endif
  endif
  return ret
endfunction
