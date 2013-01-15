" File: syntax/gmail.vim
" Last Modified: 2012.08.10
" Author: yuratomo (twitter @yusetomo)

if version < 700
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"source $VIMRUNTIME/syntax/html.vim
syn keyword gmailSearch     search
syn keyword gmailWeek       Wed Mon Mon Fri Thu Wed Tue Tue Sun
syn keyword gmailMonth      Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
syn match   gmailTime       "\d\d:\d\d:\d\d"
syn match   gmailUnseen0    "(0)"
syn match   gmailUnseenNone "(-)"
syn match   gmailUnseen     "(\d*)"
syn match   gmailUnseenMail "^ \*.*$"
syn match   gmailQuote      "^>[^>]\{0,1}.*$"
syn match   gmailQuote      "^>$"
syn match   gmailQuote2     "^>>[^>]\{0,1}.*$"
syn match   gmailQuote2     "^>>$"
syn match   gmailQuote3     "^>>>[^>]\{0,1}.*$"
syn match   gmailQuote3     "^>>>$"
syn match   gmailQuote4     "^>>>>[^>]\{0,1}.*$"
syn match   gmailQuote4     "^>>>>$"
syn match   gmailQuote5     "^>>>>>[^>]\{0,1}.*$"
syn match   gmailQuote5     "^>>>>>$"
syn match   gmailLabel      "^\(From:\|To:\|Subject:\|Cc:\|Bcc:\)"
syn match   gmailButton     "\[more\]"
syn match   gmailButton     "\[update\]"
syn match   gmailButton     "\[unread\]"
syn match   gmailButton     "\[read\]"
syn match   gmailButton     "\[delete\]"
syn match   gmailButton     "\[next\]"
syn match   gmailButton     "\[prev\]"
syn match   gmailButton     "\[send\]"
syn match   gmailButton     "\[reply\]"
syn match   gmailButton     "\[reply_all\]"
syn match   gmailButton     "\[forward\]"
syn match   gmailButton     "\[easy_html_view\]"
syn match   gmailFrom       "(From)"
syn match   gmailTo         "(To)"
syn match   gmailUrl        contained "\vhttps?://[[:alnum:]][-[:alnum:]]*[[:alnum:]]?(\.[[:alnum:]][-[:alnum:]]*[[:alnum:]]?)*\.[[:alpha:]][-[:alnum:]]*[[:alpha:]]?(:\d+)?(/[^[:space:]]*)?$"
syn match   gmailUrl        "http[s]\=://\S*"
syn match   gmailBracket1   /�u\_.\{-0,30}�v/
syn match   gmailBracket2   /�w\_.\{-0,30}�x/
syn match   gmailBracket3   /�y\_.\{-0,30}�z/

hi default link gmailButton     Function
hi default link gmailFrom       Statement
hi default link gmailTo         Statement
hi default link gmailLabel      StatusLine
hi default link gmailSearch     Title
hi default link gmailWeek       Boolean
hi default link gmailMonth      Boolean
hi default link gmailTime       Number
hi default link gmailUnseen     Label
hi default link gmailUnseen0    Ignore
hi default link gmailUnseenNone Ignore
hi default link gmailQuote      Comment
hi default link gmailQuote2     Statement
hi default link gmailQuote3     Question
hi default link gmailQuote4     Function
hi default link gmailQuote5     Label
hi default link gmailSelect     PmenuSel
hi default link gmailHorizontal Underlined
hi default link gmailUrl        Comment
hi default link gmailBracket1   Macro
hi default link gmailBracket2   Macro
hi default link gmailBracket3   Macro

hi gmailBold    gui=bold
hi default link gmailUnseenMail String

let b:current_syntax = 'gmail'
