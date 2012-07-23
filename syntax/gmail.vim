if version < 700
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

source $VIMRUNTIME/syntax/html.vim
syn keyword gmailPrevNext   prev next
syn keyword gmailSearch     search
syn keyword gmailWeek       Wed Mon Mon Fri Thu Wed Tue Tue Sun
syn keyword gmailMonth      Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
syn match   gmailTime       "\d\d:\d\d:\d\d"
syn match   gmailUnseen0    "(0)"
syn match   gmailUnseenNone "(-)"
syn match   gmailUnseen     "(\d*)"
syn match   gmailUnseenMail "^\*.*$"
syn match   gmailQuote      "^>[^>].*$"
syn match   gmailQuote2     "^>>[^>].*$"
syn match   gmailQuote3     "^>>>[^>].*$"
syn match   gmailQuote4     "^>>>>[^>].*$"
syn match   gmailQuote5     "^>>>>>[^>].*$"
syn match   gmailLabel      "^[^ Å@]\{2,10\}:"

hi default link gmailPrevNext   PmenuSel
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

hi gmailBold    gui=bold
"hi default link gmailUnseenMail gmailBold
hi default link gmailUnseenMail String

let b:current_syntax = 'gmail'
