" File: autoload/gmail/smtp.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)

let s:gmail_sendmail_normalize_target = [ 'To', 'Cc', 'Bcc' ]
let s:gmail_sendmail_headers = [ 'To:', 'Cc:', 'Bcc:', 'Subject:' ]

function! gmail#smtp#open(to, cc, subject)
  call gmail#win#open(g:GMAIL_MODE_CREATE)
  call gmail#win#clear()
  call gmail#win#setline(1, [ '[send]', "To: " . s:normalize_mail(a:to)])
  if !empty(a:cc)
    call gmail#win#setline(3, map(a:cc, '"Cc: " . v:val'))
  else
    call gmail#win#setline(3, "Cc: ")
  endif
  call gmail#win#setline(line('$')+1, [ "Bcc: ", "Subject: " . a:subject, "", g:gmail_signature ])
  setl modifiable
endfunction

function! gmail#smtp#send()
  let messages = getline(2, line('$'))
  let to = []
  let header = []
  for msg in messages
    if msg =~ "^To:"
      call add(to, substitute(msg, '^To:\s\?', '', ''))
    elseif msg =~ "^Cc:"
      call add(to, substitute(msg, '^Cc:\s\?', '', ''))
    elseif msg =~ "^Bcc:"
      call add(to, substitute(msg, '^Bcc:\s\?', '', ''))
    else
      break
    endif
  endfor
  if empty(to)
    call gmail#util#message('Specify the rcpt to')
  else
    call s:sendmail(header, to, messages)
  endif
endfunction

function! s:sendmail(header, to, messages)
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
  call extend(contents, a:header)
  if bidx > 0
    for header in a:messages[ 0 : bidx-1 ]
      let header = substitute(header, ':\s*', ':', '')
      let lidx = stridx(header, ':')
      let label = header[ 0 : lidx ]
      let value = header[ lidx+1 : ]
      if index(s:gmail_sendmail_normalize_target, label) != -1
        let value = s:normalize_mail(value)
      endif
      if empty(value)
        let encoded_msg = label
      else
        let encoded_msg = label . gmail#util#encodeMime(value)
      endif
      call add(contents, encoded_msg)
    endfor
  endif
  call add(contents, "")
  call extend(contents, split(iconv(join(a:messages[ bidx : ], "\n"), &enc, g:gmail_default_encoding), "\n"))
  call add(contents, "")

  let commands =
    \[
    \  "EHLO LOCALHOST\r\n",
    \  "AUTH PLAIN\r\n",
    \  AUTH,
    \  "MAIL FROM:<" . g:gmail_user_name . ">\r\n",
    \ ]
  for t in a:to
    call add(commands, "RCPT TO:<" . s:normalize_mail(t) . ">\r\n")
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
      call gmail#util#error('write error')
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
    call gmail#util#error('send mail error!!')
  endif

endfunction

function! s:normalize_mail(t)
  let t = substitute(a:t, '.*<', '', '')
  let t = substitute(t,   '>.*', '', '')
  return  substitute(t,   ' ', '', 'g')
endfunction
