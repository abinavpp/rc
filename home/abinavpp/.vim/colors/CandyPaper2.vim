" A fork of CandyPaper by dfxyz that has been modified to my personal taste.

hi clear
if exists('syntax_on')
    syntax reset
endif

let g:colors_name = "CandyPaper2"

" _xxx colors are beyond the 256 color spectrum.
let s:yellow = "#ffdf00"
let s:cheddar = "#d75f00"
let s:red = "#d70000"
let s:darkred = "#5f0000"
let s:pink = "#d75faf"
let s:orange = "#d78700"

let s:lightgreen = "#5fffaf"
let s:green = "#00d75f"
let s:darkgreen = "#00875f"
let s:darkergreen = "#005f00"
let s:_darkestgreen = "#002000"
let s:teal = "#008080"

let s:aqua = "#00d7ff"
let s:darkblue = "#000080"
let s:blue = "#0087d7"
let s:violet = "#af5fd7"
let s:purple = "#800080"
let s:darkpurple = "#5f005f"

let s:white = "#ffffff"
let s:lightergrey = "#e4e4e4"
let s:lightgrey = "#949494"
let s:darkgrey = "#8a8a8a"
let s:darkergrey = "#303030"
let s:darkestgrey = "#262626"
let s:lightblack = "#121212"
let s:black = "#000000"

if g:color_theme == 'light'
  let s:pink = "#d700af"
  let s:orange = "#d75f00"

  let s:green = "#00af00"

  let s:aqua = "#0087ff"
  let s:blue = "#0000d7"
  let s:violet = "#af00d7"

  let s:darkgrey = "#626262"
  let s:lightgrey = "#c6c6c6"
endif

" Returns an approximate grey index for the given grey level.
function! s:grey_number(x)
  if a:x < 14
    return 0
  else
    let l:n = (a:x - 8) / 10
    let l:m = (a:x - 8) % 10
    if l:m < 5
      return l:n
    else
      return l:n + 1
    endi
  endif
endfunction

" Returns the actual grey level represented by the grey index.
function! s:grey_level(n)
  if a:n == 0
    return 0
  else
    return 8 + (a:n * 10)
  endif
endfunction

" Returns the palette index for the given grey index.
function! s:grey_color(n)
  if a:n == 0
    return 16
  elseif a:n == 25
    return 231
  else
    return 231 + a:n
  endif
endfunction

" Returns an approximate color index for the given color level.
function! s:rgb_number(x)
  if a:x < 75
    return 0
  else
    let l:n = (a:x - 55) / 40
    let l:m = (a:x - 55) % 40
    if l:m < 20
      return l:n
    else
      return l:n + 1
    endif
  endif
endfunction

" Returns the actual color level for the given color index.
function! s:rgb_level(n)
  if a:n == 0
    return 0
  else
    return 55 + (a:n * 40)
  endif
endfunction

" Returns the palette index for the given RGB color indices.
function! s:rgb_color(x, y, z)
  return 16 + (a:x * 36) + (a:y * 6) + a:z
endfunction

" Returns the palette index to approximate the given RGB color levels.
function! s:color(r, g, b)
  let l:gx = s:grey_number(a:r)
  let l:gy = s:grey_number(a:g)
  let l:gz = s:grey_number(a:b)

  let l:x = s:rgb_number(a:r)
  let l:y = s:rgb_number(a:g)
  let l:z = s:rgb_number(a:b)

  if l:gx == l:gy && l:gy == l:gz
    let l:dgr = s:grey_level(l:gx) - a:r
    let l:dgg = s:grey_level(l:gy) - a:g
    let l:dgb = s:grey_level(l:gz) - a:b
    let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
    let l:dr = s:rgb_level(l:gx) - a:r
    let l:dg = s:rgb_level(l:gy) - a:g
    let l:db = s:rgb_level(l:gz) - a:b
    let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
    if l:dgrey < l:drgb
      return s:grey_color(l:gx)
    else
      return s:rgb_color(l:x, l:y, l:z)
    endif
  else
    return s:rgb_color(l:x, l:y, l:z)
  endif
endfunction

" Returns the palette index to approximate the '#rrggbb' hex string.
function! s:rgb(rgb)
  if a:rgb == "NONE"
    return "NONE"
  endif

  if a:rgb == "fg"
    return "fg"
  endif

  if a:rgb == "bg"
    return "bg"
  endif

  let l:r = ("0x" . strpart(a:rgb, 1, 2)) + 0
  let l:g = ("0x" . strpart(a:rgb, 3, 2)) + 0
  let l:b = ("0x" . strpart(a:rgb, 5, 2)) + 0

  return s:color(l:r, l:g, l:b)
endfunction

function! s:all(grp, fg, bg, attr)
  exec "hi " . a:grp . " cterm=" . a:attr . " gui=" . a:attr
    \. " ctermfg=" . s:rgb(a:fg) . " guifg=" . a:fg
    \. " ctermbg=" . s:rgb(a:bg) . " guibg=" . a:bg
endfunction

function! s:col(grp, fg, bg)
  call s:all(a:grp, a:fg, a:bg, "NONE")
endfunction

function! s:fg(grp, col)
  call s:col(a:grp, a:col, "NONE")
endfunction

function! s:bg(grp, col)
  call s:col(a:grp, "NONE", a:col)
endfunction

call s:bg("Normal", "NONE")
call s:bg("Conceal", "NONE")
call s:bg("Visual", s:purple)
call s:col("MatchParen", s:black, s:darkgreen)
call s:bg("lspReference", s:darkergrey)
call s:fg("NonText", s:darkgreen)
call s:fg("SpecialKey", s:darkgreen)
call s:fg("Directory", s:aqua)
call s:fg("ModeMsg", s:orange)
call s:fg("MoreMsg", s:orange)
call s:fg("Question", s:orange)
call s:fg("WarningMsg", s:green)

call s:bg("Search", s:purple)
call s:bg("IncSearch", s:cheddar)

call s:col("StatusLine", s:white, s:darkpurple)
call s:col("StatusLineNC", s:white, s:darkestgrey)

call s:col("TabLine", s:white, s:darkestgrey)
call s:col("TabLineFill", s:white, s:darkestgrey)
call s:col("TabLineSel", s:white, s:darkpurple)

call s:bg("PMenu", "NONE")
call s:col("PMenuSel", s:white, s:darkpurple)
call s:bg("PMenuSBar", s:darkpurple)
call s:bg("PMenuThumb", "NONE")

call s:bg("Folded", s:violet)
call s:bg("FoldColumn", "NONE")

call s:bg("ColorColumn", s:red)
call s:bg("SignColumn", "NONE")
call s:fg("LineNr", s:darkgrey)
call s:bg("VertSplit", "NONE")

call s:col("Cursor", s:black, s:pink)
call s:col("CursorIM", s:black, s:aqua)
call s:bg("CursorColumn", "NONE")
if g:color_theme == "dark"
  call s:bg("CursorLine", s:lightblack)
  call s:fg("CursorLineNR", s:yellow)

  call s:bg("DiffAdd", s:_darkestgreen)
  call s:fg("DiffDelete", s:darkred)
  call s:bg("DiffChange", s:darkestgrey)
  call s:col("DiffText", "NONE", s:darkblue)
else
  call s:bg("CursorLine", s:lightergrey)
  call s:fg("CursorLineNR", s:cheddar)

  call s:bg("DiffAdd", s:lightgreen)
  call s:fg("DiffDelete", s:red)
  call s:bg("DiffChange", s:lightgrey)
  call s:col("DiffText", "NONE", s:blue)
endif

call s:all("SpellBad", s:red, "NONE", "underline")
call s:all("SpellCap", s:orange, "NONE", "underline")

call s:fg("Boolean", s:red)
call s:fg("Character", s:orange)
call s:fg("SpecialChar", s:pink)
call s:fg("Number", s:red)
call s:fg("Float", s:red)
call s:fg("String", s:orange)
call s:fg("Constant", s:red)

call s:fg("Type", s:green)
call s:fg("Structure", s:teal)
call s:fg("Global", s:teal)
call s:fg("StorageClass", s:teal)

call s:fg("Function", "NONE")
call s:fg("Identifier", "NONE")

call s:fg("Keyword", s:violet)
call s:fg("Conditional", s:violet)
call s:fg("Repeat", s:violet)
call s:fg("Statement", s:blue)
call s:fg("Operator", s:blue)
call s:fg("Typedef", s:blue)
call s:fg("Tag", s:blue)
call s:fg("Macro", s:blue)
call s:fg("Define", s:blue)
call s:fg("PreProc", s:blue)
call s:fg("PreCondit", s:blue)
call s:fg("Label", s:aqua)
call s:fg("Delimiter", s:aqua)
call s:fg("Exception", s:pink)
call s:fg("Include", s:pink)
call s:fg("Special", s:pink)
call s:fg("Debug", s:red)
call s:fg("Error", s:red)
call s:fg("Todo", s:violet)

call s:fg("Comment", s:darkgrey)
call s:fg("Title", s:darkgrey)
call s:fg("SpecialComment", s:darkgrey)

au VimEnter * highlight trailingSpace ctermbg=red guibg=red
  \| match trailingSpace /\s\+\%#\@<!$/
au InsertLeave * call s:col("StatusLine", s:white, s:darkpurple)
au InsertEnter * call s:col("StatusLine", s:white, s:darkergreen)
