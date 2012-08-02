let s:gmail_mailbox_idx = 0
let s:gmail_body_separator = '                                                                  '
let s:gmail_body_menu  = '[reply] [reply_all] [forward]                                     '

function! gmail#imap#login()
  call gmail#win#open(g:GMAIL_MODE_MAILBOX)
  if !exists('g:gmail_user_name')
    let g:gmail_user_name = input('input mail address:', '@gmail.com')
  endif
  if !exists('g:gmail_user_pass')
    let g:gmail_user_pass = input('input password:')
  endif

  let cmd = [g:gmail_command, 's_client', '-connect', g:gmail_imap, '-quiet']
  let s:sub = vimproc#popen3(cmd)
  let ret = gmail#util#response(s:sub, '* OK', g:gmail_timeout)
  if empty(ret)
    return 0
  endif

  let s:gmail_login_now = 1
  let ret = s:request("? LOGIN " . g:gmail_user_name . " " . g:gmail_user_pass, g:gmail_timeout)
  let s:gmail_login_now = 0
  if empty(ret)
    return 0
  endif

  return 1
endfunction

function! s:relogin()
  let mode = gmail#win#mode()
  call gmail#imap#exit()
  if gmail#imap#login() == 0
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
    call gmail#util#message('select error(' . a:mb . ')')
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

  if !exists('s:gmail_page')
    let s:gmail_page = -1
  endif

  if !exists('s:gmail_list') || s:gmail_page != a:page

    if !exists('s:gmail_uids')
      let res = s:request("? SEARCH " . g:gmail_search_key, g:gmail_timeout)
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

  call gmail#win#clear()
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
  let res = s:request("? FETCH " . a:id . " (BODY[HEADER.FIELDS (FROM TO SUBJECT DATE)])", g:gmail_timeout)
  "let res = s:request("? FETCH " . a:id . " (FLAGS BODY.PEEK[HEADER.FIELDS (SUBJECT DATE FROM )])", g:gmail_timeout)
  let list = []
  let mail = ''
  for r in res[1:-4]
    let parts = split(r, ' ')
    if r == ")"
      call add(list, mail)
    elseif r =~ '=?.*?='
      let mail .= gmail#util#decodeMime(r)
    else
      call add(list, r)
    endif
  endfor
  call add(list, s:gmail_body_separator)
  call gmail#win#setline(1, s:gmail_body_menu)
  call gmail#win#setline(2, list)
  call gmail#win#hilightLine('gmailHorizontal', len(list)+1)
  let res = s:request("? FETCH " . a:id . " RFC822.TEXT", g:gmail_timeout)
  call gmail#win#setline(line('$')+1, map(res[1 : -3], "iconv(v:val, g:gmail_encoding, &enc)"))
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

  let ret = gmail#util#response(s:sub, '? ', a:timeout)
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
