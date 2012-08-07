"let g:gmail_encoding = ''

function! gmail#util#message(msg)
  echon 'gmail:' . a:msg
  redraw
endfunction

function! gmail#util#response(vp, end, timeout)
  let cnt = 0
  let res = ''
  let end = 0
  while !a:vp.stdout.eof
    let line = substitute(a:vp.stdout.read(), nr2char(10), '', 'g')
    if line != ''
      let res = res . line
      for line2 in split(line, "\r")
        if line2 =~ a:end
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
      if cnt >= a:timeout/10
        call gmail#util#message('request timeout!!')
        return []
      endif
    endif
  endwhile
  return split(res, "\r")
endfunction

function! gmail#util#decodeUtf7(str)
  let mod1 = substitute(a:str, '&', '+', '')
  let mod2 = substitute(mod1, '&-', '&', 'g')
  let mod3 = substitute(mod2, ',', '/', 'g')
  return iconv(mod3, 'UTF-7', &enc)
endfunction

function! gmail#util#encodeMime(str)
  return
    \ '=?' .
    \ g:gmail_default_encoding .
    \ '?B?' .
    \ s:encodeBase64Str(iconv(a:str, &enc, g:gmail_default_encoding)) . 
    \ '?='
endfunction

function! gmail#util#decodeMime(str)
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
  "let g:gmail_encoding = enc
  return iconv(gmail#util#decodeBase64(a:str[ start+1 : end-1 ]), enc, &enc)
endfunction

let s:standard_table = [
      \ "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
      \ "Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f",
      \ "g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v",
      \ "w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"]

function! s:encodeBase64Str(data)
  let b64 = s:b64encode(gmail#util#str2bytes(a:data), s:standard_table, '=')
  return join(b64, '')
endfunction

function! gmail#util#encodeBase64(bytes)
  let b64 = s:b64encode(a:bytes, s:standard_table, '=')
  return join(b64, '')
endfunction

function! gmail#util#decodeBase64(data)
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

function! gmail#util#str2bytes(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! gmail#util#decodeQuotedPrintable(data)
  return substitute(a:data, '=\(\x\x\|\n\)', '\=submatch(1)=="\n"?"":nr2char("0x".submatch(1))', 'g')
endfunction

function! gmail#util#neglect_htmltag()
  setl modifiable
  :%s/<.\{-\}>//ge
  :%s/^\s*//ge
  :%s/^\s*$//ge
  :%s/\n\n\n//ge
  :%s/&quot;/"/ge
  :%s/&laquo;/Å·/ge
  :%s/&raquo;/Å‚/ge
  :%s/&lt;/</ge
  :%s/&gt;/>/ge
  :%s/&amp;/\&/ge
  :%s/&yen;/\\/ge
  :%s/&cent;/Åë/ge
  :%s/&copy;/c/ge
  :%s/&apos;/'/ge
  :%s/&nbsp;/ /ge
  redraw
  setl nomodifiable
endfunction

