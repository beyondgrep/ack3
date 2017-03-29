" Barfly syntax file
if exists("b:current_syntax")
    finish
endif

" The "done" detection could be better here... any X in the string will
" highlight when we define it this way:
syn keyword barflyKeyword BEGIN END YES NO YESLINES
syn match barflyComment /^#.*$/ contains=hwdTodo

"
" highlighting defs
"
hi def link barflyComment      Comment
hi def link barflyKeyword      Special

let b:current_syntax = "barfly"
