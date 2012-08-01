let s:gmail_sendmail_menu  = 'send                                                              '
let s:gmail_sendmail_headers = [ 'To:', 'Cc:', 'Bcc:', 'Subject:' ]

function! gmail#smtp#open()
  call gmail#win#open(g:GMAIL_MODE_CREATE)
  call gmail#win#setline(1, [ s:gmail_sendmail_menu, "To:", "Cc:", "Bcc:", "Subject:", "", g:gmail_signature ])
  call gmail#win#hilightLine('gmailHorizontal', 1)
  setl modifiable
endfunction

function! gmail#smtp#send()
  let messages = getline(2, line('$'))
  let to = []
  for msg in messages
    if msg =~ "^To:" || msg =~ "^Cc:"
      call add(to, msg[3:])
    elseif msg =~ "^Bcc:"
      call add(to, msg[4:])
    else
      break
    endif
  endfor
  if empty(to)
    call gmail#util#message('Specify the rcpt to')
  else
    call s:sendmail(to, messages)
  endif
endfunction

function! s:sendmail(to, messages)
  let cmd = [g:gmail_command, 's_client', '-connect', g:gmail_smtp, '-quiet']
  let sub = vimproc#popen3(cmd)
  let ret = gmail#util#response(sub, '^\d\d\d ', g:gmail_timeout)
  if empty(ret)
    call sub.kill(9)
    unlet sub
    return
  endif

  let bytes = [ 0 ]
  call extend(bytes, gmail#util#str2bytes(g:gmail_user_name))
  call add(bytes, 0)
  call extend(bytes, gmail#util#str2bytes(g:gmail_user_pass))
  let AUTH = gmail#util#encodeBase64(bytes) . "\r\n"

  let bidx = 0
  for msg in a:messages
    let lidx = stridx(msg, ':')
    if lidx != -1
      let label = msg[ 0 : lidx ]
      if index(s:gmail_sendmail_headers, label) == -1
        break
      endif
    else
      break
    endif
    let bidx += 1
  endfor

  let contents = [
           \  "MIME-Version: 1.0",
           \  "Content-type: text/plain; charset=" . g:gmail_default_encoding,
           \  "Content-Transfer-Encoding: 7bit",
           \ ]
  if bidx > 0
    for header in a:messages[ 0 : bidx-1 ]
      let lidx = stridx(header, ':')
      let label = header[ 0 : lidx ]
      let value = header[ lidx+1 : ]
      if empty(value)
        let encoded_msg = label
      else
        let encoded_msg = label . gmail#util#encodeMime(value)
      endif
      call add(contents, encoded_msg)
    endfor
  endif
  call add(contents, "")
  call extend(contents, map(a:messages[ bidx : ], "iconv(v:val, &enc, g:gmail_encoding)"))

  let commands =
    \[
    \  "EHLO LOCALHOST\r\n",
    \  "AUTH PLAIN\r\n",
    \  AUTH,
    \  "MAIL FROM:<" . g:gmail_user_name . ">\r\n",
    \ ]
  for t in a:to
    call add(commands, "RCPT TO:<" . t . ">\r\n")
  endfor
  call extend(commands,
    \[
    \  "DATA\r\n",
    \  join(contents, "\r\n") . "\r\n.\r\n",
    \  "QUIT \r\n",
    \])

  let err = 0
  for command in commands
    try
      call sub.stdin.write(command)
    catch /.*/
      call gmail#util#message('write error')
      let err = 1
      break
    endtry
    let ret = gmail#util#response(sub, '^\d\d\d ', g:gmail_timeout)
    call gmail#util#message(string(ret))
    if empty(ret)
      let err = 1
      break
    endif
  endfor

  call sub.kill(9)
  unlet sub

  if err == 0
    call gmail#util#message('send mail ok.')
    call gmail#win#open(g:GMAIL_MODE_BODY)
  else
    call gmail#util#message('send mail error!!')
  endif

endfunction

