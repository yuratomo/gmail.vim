if version < 700
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword gmailPrevNext   prev next
syn keyword gmailSearch     search
syn match   gmailUnseen0    "(0)"
syn match   gmailUnseenNone "(-)"
syn match   gmailUnseen     "(\d\*)"
syn match   gmailUnseenMail "^\*.*$"

hi default link gmailPrevNext   PmenuSel
hi default link gmailSearch     Title
hi default link gmailUnseen     Label
hi default link gmailUnseen0    Ignore
hi default link gmailUnseenNone Ignore
hi default link gmailCurrent    PmenuSel
hi default link gmailUnseenMail String

let b:current_syntax = 'gmail'
