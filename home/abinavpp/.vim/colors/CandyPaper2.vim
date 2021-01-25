" This theme is a fork of CandyPaper by dfxyz. It's heavily modified for my
" personal taste.

hi clear
if exists('syntax_on')
    syntax reset
endif

let g:colors_name = "CandyPaper2"

" Palette:
" _xxx colors are beyond the 256 spectrum, you need true-color terminal or gvim
" for them. Others are strictly the ones for 256 as specified by 256col.svg file
" in .vim/colors/
let s:yellow      = "#ffff00"
let s:cheddar     = "#d75f00"
let s:red         = "#d70000"
let s:darkred     = "#5f0000"
let s:pink        = "#d75faf"
let s:orange      = "#d78700"

let s:lightgreen    = "#5fffaf"
let s:green         = "#00d75f"
let s:darkgreen     = "#00875f"
let s:_darkestgreen = "#002000"
let s:teal          = "#005f5f"

let s:aqua        = "#00d7ff"
let s:blue        = "#0087d7"
let s:purple      = "#af5fd7"
let s:violet      = "#870087"

let s:white         = "#ffffff"
let s:lightergrey   = "#e4e4e4"
let s:lightgrey     = "#949494"
let s:darkgrey      = "#8a8a8a"
let s:darkergrey    = "#303030"
let s:darkestgrey   = "#262626"
let s:lightblack    = "#121212"
let s:black         = "#000000"

if g:color_theme == 'light'
  let s:pink        = "#d700af"
  let s:orange      = "#d75f00"

  let s:green       = "#00af00"

  let s:aqua        = "#0087ff"
  let s:blue        = "#0000d7"
  let s:purple      = "#af00d7"

  let s:darkgrey      = "#626262"
  let s:lightgrey     = "#c6c6c6"
endif

" Returns an approximate grey index for the given grey level
function <SID>grey_number(x)
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

" Returns the actual grey level represented by the grey index
function <SID>grey_level(n)
    if a:n == 0
        return 0
    else
        return 8 + (a:n * 10)
    endif
endfunction

" Returns the palette index for the given grey index
function <SID>grey_colour(n)
    if a:n == 0
        return 16
    elseif a:n == 25
        return 231
    else
        return 231 + a:n
    endif
endfunction

" Returns an approximate colour index for the given colour level
function <SID>rgb_number(x)
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

" Returns the actual colour level for the given colour index
function <SID>rgb_level(n)
    if a:n == 0
        return 0
    else
        return 55 + (a:n * 40)
    endif
endfunction

" Returns the palette index for the given R/G/B colour indices
function <SID>rgb_colour(x, y, z)
    return 16 + (a:x * 36) + (a:y * 6) + a:z
endfunction

" Returns the palette index to approximate the given R/G/B colour levels
function <SID>colour(r, g, b)
    " Get the closest grey
    let l:gx = <SID>grey_number(a:r)
    let l:gy = <SID>grey_number(a:g)
    let l:gz = <SID>grey_number(a:b)

    " Get the closest colour
    let l:x = <SID>rgb_number(a:r)
    let l:y = <SID>rgb_number(a:g)
    let l:z = <SID>rgb_number(a:b)

    if l:gx == l:gy && l:gy == l:gz
        " There are two possibilities
        let l:dgr = <SID>grey_level(l:gx) - a:r
        let l:dgg = <SID>grey_level(l:gy) - a:g
        let l:dgb = <SID>grey_level(l:gz) - a:b
        let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
        let l:dr = <SID>rgb_level(l:gx) - a:r
        let l:dg = <SID>rgb_level(l:gy) - a:g
        let l:db = <SID>rgb_level(l:gz) - a:b
        let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
        if l:dgrey < l:drgb
            " Use the grey
            return <SID>grey_colour(l:gx)
        else
            " Use the colour
            return <SID>rgb_colour(l:x, l:y, l:z)
        endif
    else
        " Only one possibility
        return <SID>rgb_colour(l:x, l:y, l:z)
    endif
endfunction

" Returns the palette index to approximate the '#rrggbb' hex string
function <SID>rgb(rgb)
    let l:r = ("0x" . strpart(a:rgb, 1, 2)) + 0
    let l:g = ("0x" . strpart(a:rgb, 3, 2)) + 0
    let l:b = ("0x" . strpart(a:rgb, 5, 2)) + 0

    return <SID>colour(l:r, l:g, l:b)
endfunction

" Sets the highlighting for the given group
function <SID>X(group, fg, bg, attr)
    exec "hi clear " . a:group
    if a:fg != ""
        exec "hi " . a:group . " guifg=" . a:fg . " ctermfg=" . <SID>rgb(a:fg)
    endif
    if a:bg != ""
        exec "hi " . a:group . " guibg=" . a:bg . " ctermbg=" . <SID>rgb(a:bg)
    endif
    if a:attr != ""
        exec "hi " . a:group . " gui=" . a:attr . " cterm=" . a:attr
    endif
endfunction

function <SID>X2(group, fg, bg, attr, attrcol)
  call <SID>X(a:group, a:fg, a:bg, a:attr)
  if a:attrcol != ""
    exec "hi " . a:group . " guisp=" . a:attrcol
  endif
endfunction

" UI Highlighting
call <SID>X("Normal", "", "", "none")
call <SID>X("NonText", s:darkgreen, "", "none")
call <SID>X("SpecialKey", s:darkgreen, "", "none")
call <SID>X("Search", s:yellow, s:teal, "none")
call <SID>X("IncSearch", s:black, s:yellow, "none")
call <SID>X("LineNr", s:darkgrey, "", "none")
call <SID>X("TabLine", s:black, s:teal, "none")
call <SID>X("TabLineFill", "", s:teal, "none")
call <SID>X("TabLineSel", "", s:cheddar, "none")
call <SID>X("StatusLine", s:black, s:cheddar, "none")
call <SID>X("StatusLineNC", s:black, s:teal, "none")
call <SID>X("VertSplit", s:black, s:teal, "none")
call <SID>X("Visual", "", s:teal, "none")
call <SID>X("Directory", s:aqua, "", "none")
call <SID>X("ModeMsg", s:orange, "", "none")
call <SID>X("MoreMsg", s:orange, "", "none")
call <SID>X("Question", s:orange, "", "none")
call <SID>X("WarningMsg", s:green, "", "none")
call <SID>X("MatchParen", s:black, s:darkgreen, "none")
call <SID>X("Folded", "", s:purple, "none")
call <SID>X("FoldColumn", "", "", "none")
call <SID>X("Cursor", s:black, s:pink, "none")
call <SID>X("CursorIM", s:black, s:aqua, "none")
call <SID>X("CursorColumn", "", "", "none")
call <SID>X("ColorColumn", "", s:red, "none")
if g:color_theme == "dark"
  call <SID>X("CursorLine", "", s:lightblack, "none")
  call <SID>X("CursorLineNR", s:yellow, "", "none")

  call <SID>X("DiffAdd", "", s:_darkestgreen, "none")
  call <SID>X("DiffDelete", s:darkred, "", "none")
  call <SID>X("DiffChange", "", s:darkestgrey, "none")
  call <SID>X2("DiffText", "", s:darkestgrey, "underline", s:violet)
else
  call <SID>X("CursorLine", "", s:lightergrey, "none")
  call <SID>X("CursorLineNR", s:cheddar, "", "none")

  call <SID>X("DiffAdd", "", s:lightgreen, "none")
  call <SID>X("DiffDelete", s:red, "", "none")
  call <SID>X("DiffChange", "", s:lightgrey, "none")
  call <SID>X2("DiffText", "", s:lightgrey, "underline", s:violet)
endif
call <SID>X("SignColumn", "", "", "none")
call <SID>X("PMenu", "", "", "none")
call <SID>X("PMenuSel", "", s:teal, "none")
call <SID>X("PMenuSBar", "", s:teal, "none")
call <SID>X("PMenuThumb", "", "", "none")
call <SID>X("lspReference", "", s:darkergrey, "none")

" Standard Group Highlighting:
call <SID>X("Boolean", s:red, "", "none")
call <SID>X("Character", s:orange, "", "none")
call <SID>X("Comment", s:darkgrey, "", "none")
call <SID>X("Conditional", s:purple, "", "none")
call <SID>X("Constant", s:red, "", "none")
call <SID>X("Debug", s:red, "", "none")
call <SID>X("Define", s:blue, "", "none")
call <SID>X("Delimiter", s:aqua, "", "none")
call <SID>X("Error", s:red, "", "none")
call <SID>X("Exception", s:pink, "", "none")
call <SID>X("Float", s:red, "", "none")
call <SID>X("Function", "", "", "none")
call <SID>X("Global", s:aqua, "", "none")
call <SID>X("Identifier", "", "", "none")
call <SID>X("Include", s:pink, "", "none")
call <SID>X("Keyword", s:blue, "", "none")
call <SID>X("Label", s:aqua, "", "none")
call <SID>X("Macro", s:blue, "", "none")
call <SID>X("Number", s:red, "", "none")
call <SID>X("Operator", s:blue, "", "none")
call <SID>X("PreProc", s:blue, "", "none")
call <SID>X("Repeat", s:purple, "", "none")
call <SID>X("Special", s:pink, "", "none")
call <SID>X("Statement", s:blue, "", "none")
call <SID>X("String", s:orange, "", "none")
call <SID>X("Tag", s:blue, "", "none")
call <SID>X("Todo", s:darkgreen, "", "none")
call <SID>X("Title", s:darkgrey, "", "none")
call <SID>X("Type", s:green, "", "none")
call <SID>X("Typedef", s:blue, "", "none")
call <SID>X("PreCondit", s:blue, "", "none")
call <SID>X("SpecialChar", "", "", "none")
call <SID>X("StorageClass", s:green, "", "none")
call <SID>X("Structure", s:aqua, "", "none")
call <SID>X("SpecialComment", s:darkgrey, "", "none")
call <SID>X("SpellBad", s:red, "", "underline")
call <SID>X("SpellCap", s:blue, "", "underline")

" C Highlighting
call <SID>X("cType", s:green, "", "none")
call <SID>X("cFormat", s:pink, "", "none")
call <SID>X("cStorageClass", s:green, "", "none")
call <SID>X("cCharacter", s:orange, "", "none")
call <SID>X("cConstant", s:blue, "", "none")
call <SID>X("cConditional", s:purple, "", "none")
call <SID>X("cSpecial", s:pink, "", "none")
call <SID>X("cDefine", s:blue, "", "none")
call <SID>X("cNumber", s:red, "", "none")
call <SID>X("cPreCondit", s:blue, "", "none")
call <SID>X("cRepeat", s:purple, "", "none")
call <SID>X("cLabel",s:aqua, "", "none")
call <SID>X("cOperator",s:blue, "", "none")
call <SID>X("cOctalZero", s:orange, "", "none")

" CPP highlighting
call <SID>X("cppExceptions", s:pink, "", "none")
call <SID>X("cppStatement", s:blue, "", "none")
call <SID>X("cppStorageClass", s:green, "", "none")
call <SID>X("cppAccess", s:aqua, "", "none")

" HTML Highlighting
call <SID>X("htmlTitle", s:blue, "", "none")
call <SID>X("htmlH1", s:blue, "", "none")
call <SID>X("htmlH2", s:blue, "", "none")
call <SID>X("htmlH3", s:purple, "", "none")
call <SID>X("htmlH4", s:red, "", "none")
call <SID>X("htmlTag", s:green, "", "none")
call <SID>X("htmlTagN", s:green, "", "none")
call <SID>X("htmlTagName", s:green, "", "none")
call <SID>X("htmlEndTag", s:green, "", "none")
call <SID>X("htmlArg", s:aqua, "", "none")
call <SID>X("htmlScriptTag", s:green, "", "none")
call <SID>X("htmlBold", "", "", "none")
call <SID>X("htmlItalic", s:darkgrey, "", "none")
call <SID>X("htmlBoldItalic", s:orange, "", "none")
call <SID>X("htmlSpecialTagName", s:red, "", "none")

" Java Highlighting
call <SID>X("javaExternal", s:pink, "", "none")
call <SID>X("javaAnnotation", s:pink, "", "none")
call <SID>X("javaTypedef", s:blue, "", "none")
call <SID>X("javaClassDecl", s:aqua, "", "none")
call <SID>X("javaScopeDecl", s:aqua, "", "none")
call <SID>X("javaStorageClass", s:green, "", "none")

" JavaScript Highlighting
call <SID>X("javaScriptBraces", s:aqua, "", "none")
call <SID>X("javaScriptParens", s:aqua, "", "none")
call <SID>X("javaScriptConditional", s:purple, "", "none")
call <SID>X("javaScriptRepeat", s:purple, "", "none")

" Makefile Highlighting
call <SID>X("makeIdent", s:green, "", "none")
call <SID>X("makeSpecTarget", s:orange, "", "none")
call <SID>X("makeTarget", s:aqua, "", "none")
call <SID>X("makeStatement", s:blue, "", "none")
call <SID>X("makeCommands", "", "", "none")
call <SID>X("makeSpecial", s:pink, "", "none")

" Markdown Highlighting
call <SID>X("markdownH1", s:green, "", "none")
call <SID>X("markdownBlockquote", s:green, "", "none")
call <SID>X("markdownCodeBlock", s:purple, "", "none")
call <SID>X("markdownLink", s:aqua, "", "none")
call <SID>X("mkdCode", "", s:lightgrey, "none")
call <SID>X("mkdLink", s:aqua, "", "none")
call <SID>X("mkdURL", s:darkgrey, "", "none")
call <SID>X("mkdString", "", "", "none")
call <SID>X("mkdBlockQuote", "", s:lightgrey, "none")
call <SID>X("mkdLinkTitle", s:green, "", "none")
call <SID>X("mkdDelimiter", s:blue, "", "none")
call <SID>X("mkdRule", s:green, "", "none")

" Perl Highlighting
call <SID>X("perlFiledescRead", s:blue, "", "none")
call <SID>X("perlMatchStartEnd", s:blue, "", "none")
call <SID>X("perlStatementFlow", s:purple, "", "none")
call <SID>X("perlStatementFiledesc", s:blue, "", "none")
call <SID>X("perlStatementStorage", s:green, "", "none")
call <SID>X("perlSharpBang", s:darkgrey, "", "none")
call <SID>X("perlStatementInclude", s:pink, "", "none")
call <SID>X("perlSpecialString", s:pink, "", "none")

" PHP Highlighting
call <SID>X("phpIdentifier", "", "", "none")
call <SID>X("phpVarSelector", s:green, "", "none")
call <SID>X("phpKeyword", s:blue, "", "none")
call <SID>X("phpStatement", s:blue, "", "none")
call <SID>X("phpAssignByRef", s:blue, "", "none")
call <SID>X("phpComparison", s:blue, "", "none")
call <SID>X("phpBackslashSequences", s:pink, "", "none")
call <SID>X("phpMemberSelector", s:aqua, "", "none")
call <SID>X("phpStorageClass", s:green, "", "none")
call <SID>X("phpDefine", s:blue, "", "none")

" Python Highlighting
call <SID>X("pythonExceptions", s:pink, "", "none")
call <SID>X("pythonException", s:pink, "", "none")
call <SID>X("pythonInclude", s:pink, "", "none")
call <SID>X("pythonStatement", s:green, "", "none")
call <SID>X("pythonConditional", s:purple, "", "none")
call <SID>X("pythonRepeat", s:purple, "", "none")
call <SID>X("pythonFunction", "", "", "none")
call <SID>X("pythonOperator", s:blue, "", "none")
call <SID>X("pythonBuiltin", s:blue, "", "none")
call <SID>X("pythonDecorator", s:red, "", "none")
call <SID>X("pythonString", s:orange, "", "none")
call <SID>X("pythonEscape", s:pink, "", "none")

" Ruby Highlighting
call <SID>X("rubyModule", s:aqua, "", "none")
call <SID>X("rubyClass", s:aqua, "", "none")
call <SID>X("rubyConstant", s:blue, "", "none")
call <SID>X("rubyAccess", s:aqua, "", "none")
call <SID>X("rubyAttribute", s:blue, "", "none")
call <SID>X("rubyInclude", s:pink, "", "none")
call <SID>X("rubyConditional", s:purple, "", "none")
call <SID>X("rubyRepeat", s:purple, "", "none")
call <SID>X("rubyControl", s:purple, "", "none")
call <SID>X("rubyException", s:pink, "", "none")
call <SID>X("rubyExceptional", s:pink, "", "none")

" Shell Highlighting
call <SID>X("shDerefVar", s:blue, "", "none")
call <SID>X("shDerefSimple", s:blue, "", "none")
call <SID>X("shLoop", s:purple, "", "none")
call <SID>X("shQuote", s:orange, "", "none")
call <SID>X("shCaseEsac", s:blue, "", "none")
call <SID>X("shSnglCase", s:purple, "", "none")
call <SID>X("shStatement", s:green, "", "none")
call <SID>X("bashStatement", s:green, "", "none")

" SQL Highlighting
call <SID>X("sqlStatement", s:blue, "", "none")
call <SID>X("sqlType", s:green, "", "none")
call <SID>X("sqlKeyword", s:blue, "", "none")
call <SID>X("sqlOperator", s:blue, "", "none")
call <SID>X("sqlSpecial", s:pink, "", "none")
call <SID>X("mysqlVariable", "", "", "none")
call <SID>X("mysqlType", s:green, "", "none")
call <SID>X("mysqlKeyword", s:blue, "", "none")
call <SID>X("mysqlOperator", s:blue, "", "none")
call <SID>X("mysqlSpecial", s:pink, "", "none")

" TeX Highlighting
call <SID>X("texBoldStyle", s:pink, "", "none")
call <SID>X("texItalStyle", s:pink, "", "none")
call <SID>X("texBoldItalStyle", s:purple, "", "none")
call <SID>X("texItalBoldStyle", s:purple, "", "none")

" Vim Highlighting
call <SID>X("vimCommand", s:green, "", "none")
call <SID>X("vimVar", "", "", "none")
call <SID>X("vimFuncKey", s:green, "", "none")
call <SID>X("vimFunction", "", "", "none")
call <SID>X("vimNotFunc", s:green, "", "none")
call <SID>X("vimMap", s:pink, "", "none")
call <SID>X("vimAutoEvent", s:blue, "", "none")
call <SID>X("vimMapModKey", s:blue, "", "none")
call <SID>X("vimFuncName", s:blue, "", "none")
call <SID>X("vimIsCommand", "", "", "none")
call <SID>X("vimFuncVar", "", "", "none")
call <SID>X("vimLet", s:pink, "", "none")
call <SID>X("vimMapRhsExtend", "", "", "none")
call <SID>X("vimCommentTitle", s:darkgrey, "", "none")
call <SID>X("vimBracket", s:blue, "", "none")
call <SID>X("vimParenSep", s:blue, "", "none")
call <SID>X("vimSynType", s:orange, "", "none")
call <SID>X("vimNotation", s:blue, "", "none")
call <SID>X("vimOper", "", "", "none")
call <SID>X("vimOperParen", "", "", "none")

" XML Highlighting
call <SID>X("xmlTag", s:green, "", "none")
call <SID>X("xmlTagName", s:green, "", "none")
call <SID>X("xmlEndTag", s:green, "", "none")
call <SID>X("xmlAttrib", s:aqua, "", "none")

" Delete Functions
delfunction <SID>X
delfunction <SID>X2
delfunction <SID>rgb
delfunction <SID>colour
delfunction <SID>rgb_colour
delfunction <SID>rgb_level
delfunction <SID>rgb_number
delfunction <SID>grey_colour
delfunction <SID>grey_level
delfunction <SID>grey_number
