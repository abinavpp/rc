" Derived from https://github.com/mattdf/vim-yul/blob/master/syntax/yul.vim

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn keyword yulKeyword object code let leave for while if case switch default break continue
syn region yulLineComment start=+\/\/+ end=+$+ contains=yulCommentTodo,@Spell
syn region yulLineComment start=+^\s*\/\/+ skip=+\n\s*\/\/+ end=+$+ contains=yulCommentTodo,@Spell fold
syn region yulComment start="/\*"  end="\*/" contains=yulCommentTodo,@Spell fold

hi def link yulKeyword Keyword
hi def link yulCommentTodo Comment
hi def link yulLineComment Comment
hi def link yulComment Comment

let b:current_syntax = "yul"
