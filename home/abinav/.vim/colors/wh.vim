" Theme:        CandyPaper
" Author:       DF_XYZ
" License:      MIT

set background=dark
hi clear
if exists('syntax_on')
    syntax reset
endif
let g:colors_name = "wh"

" Palette:
let s:yellow      = "#ffff00" " Incsearch
let s:cheddar     = "#d75f00" " Tabline
let s:red         = "#d70000" " Number/Error
let s:darkred     = "#5f0000" " DiffDelete
let s:pink        = "#d700af" " Include/Exception
let s:orange      = "#d75f00" " String/Identifier

let s:green       = "#00af00" " Type
let s:leafgreen   = "#005f00" " DiffAdd
let s:darkgreen   = "#00875f" " Nontext/Matchparen
let s:teal        = "#005f5f" " Selection/Inactive

let s:aqua        = "#0087ff" " Keyword/Macro cond
let s:blue        = "#0000d7" " Operator/Delimiter/Const
let s:purple      = "#af00d7" " Repeat/Conditional
let s:violet      = "#870087" " Difftext

let s:white       = "#ffffff"
let s:black       = "#000000"
let s:lightgrey   = "#949494"	" Window div etc
let s:darkgrey    = "#626262" " Comment
let s:darkergrey  = "#3a3a3a"
let s:darkestgrey = "#1a1a1a"


" Basic:
let s:foreground   = s:black
let s:background   = s:white


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

" UI Highlighting
call <SID>X("Normal", "", "", "none")
call <SID>X("NonText", s:darkgreen, "", "none")
call <SID>X("SpecialKey", s:darkgreen, "", "none")
call <SID>X("Search", s:yellow, s:teal, "none")
call <SID>X("IncSearch", s:black, s:yellow, "none")
call <SID>X("LineNr", s:darkgrey, "", "none")
call <SID>X("TabLine", s:black, s:teal, "none")
call <SID>X("TabLineFill", "", s:teal, "none")
call <SID>X("TabLineSel", s:white, s:cheddar, "none")
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
call <SID>X("Folded", s:white, s:purple, "none")
" call <SID>X("FoldColumn", "", s:background, "none")
call <SID>X("Cursor", s:black, s:pink, "none")
call <SID>X("CursorIM", s:black, s:aqua, "none")
call <SID>X("CursorLine", "", "", "none")
call <SID>X("CursorLineNR", s:yellow, "", "none")
call <SID>X("CursorColumn", "", "", "none")
call <SID>X("ColorColumn", "", s:red, "none")
call <SID>X("DiffText", s:violet, s:darkestgrey, "underline")
call <SID>X("DiffAdd", s:foreground, s:leafgreen, "none")
call <SID>X("DiffDelete", s:darkred, s:darkred, "none")
call <SID>X("DiffChange", "", s:darkestgrey, "none")
call <SID>X("SignColumn", "", s:background, "none")
call <SID>X("PMenu", s:white, s:black, "none")
call <SID>X("PMenuSel", s:white, s:teal, "none")
call <SID>X("PMenuSBar", "", s:teal, "none")
call <SID>X("PMenuThumb", s:black, "", "none")
call <SID>X("lspReference", s:white, s:darkergrey, "none")

" Standard Group Highlighting:
call <SID>X("Boolean", s:blue, "", "none")
call <SID>X("Character", s:orange, "", "none")
call <SID>X("Comment", s:darkgrey, "", "none")
call <SID>X("Conditional", s:purple, "", "none")
call <SID>X("Constant", s:red, "", "none")
call <SID>X("Debug", s:red, "", "none")
call <SID>X("Define", s:aqua, "", "none")
call <SID>X("Delimiter",s:blue, "", "none")
call <SID>X("Error", s:red, s:background, "none")
call <SID>X("Exception", s:pink, "", "none")
call <SID>X("Float", s:red, "", "none")
call <SID>X("Function", s:foreground, "", "none")
call <SID>X("Global", s:aqua, "", "none")
call <SID>X("Identifier", s:orange, "", "none")
call <SID>X("Include", s:pink, "", "none")
call <SID>X("Keyword", s:aqua, "", "none")
call <SID>X("Label", s:aqua, "", "none")
call <SID>X("Macro", s:aqua, "", "none")
call <SID>X("Number", s:red, "", "none")
call <SID>X("Operator", s:blue, "", "none")
call <SID>X("PreProc", s:aqua, "", "none")
call <SID>X("Repeat", s:purple, "", "none")
call <SID>X("Special", s:blue, "", "none")
call <SID>X("Statement", s:green, "", "none")
call <SID>X("String", s:orange, "", "none")
call <SID>X("Tag", s:blue, "", "none")
call <SID>X("Todo", s:darkgreen, s:background, "none")
call <SID>X("Title", s:darkgrey, "", "none")
call <SID>X("Type", s:green, "", "none")
call <SID>X("Typedef", s:green, "", "none")
call <SID>X("PreCondit", s:blue, "", "none")
call <SID>X("SpecialChar", s:foreground, "", "none")
call <SID>X("StorageClass", s:orange, "", "none")
call <SID>X("Structure", s:aqua, "", "none")
call <SID>X("SpecialComment", s:darkgrey, "", "none")
call <SID>X("SpellBad", s:red, s:background, "underline")

" C Highlighting
call <SID>X("cType", s:green, "", "none")
call <SID>X("cFormat", s:pink, "", "none")
call <SID>X("cStorageClass", s:orange, "", "none")
call <SID>X("cBoolean", s:blue, "", "none")
call <SID>X("cCharacter", s:orange, "", "none")
call <SID>X("cConstant", s:blue, "", "none")
call <SID>X("cConditional", s:purple, "", "none")
call <SID>X("cSpecial", s:pink, "", "none")
call <SID>X("cDefine", s:blue, "", "none")
call <SID>X("cNumber", s:red, "", "none")
call <SID>X("cPreCondit", s:aqua, "", "none")
call <SID>X("cRepeat", s:purple, "", "none")
call <SID>X("cLabel",s:blue, "", "none")
call <SID>X("cOperator",s:blue, "", "none")
call <SID>X("cOctalZero", s:purple, "", "none")

" CPP highlighting
call <SID>X("cppBoolean", s:orange, "", "none")
call <SID>X("cppExceptions", s:pink, "", "none")
call <SID>X("cppStatement", s:aqua, "", "none")
call <SID>X("cppStorageClass", s:orange, "", "none")
call <SID>X("cppAccess",s:aqua, "", "none")

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
call <SID>X("htmlBold", s:foreground, "", "none")
call <SID>X("htmlItalic", s:darkgrey, "", "none")
call <SID>X("htmlBoldItalic", s:orange, "", "none")
call <SID>X("htmlSpecialTagName", s:red, "", "none")

" Java Highlighting
call <SID>X("javaExternal", s:pink, "", "none")
call <SID>X("javaAnnotation", s:red, "", "none")
call <SID>X("javaTypedef", s:blue, "", "none")
call <SID>X("javaClassDecl", s:aqua, "", "none")
call <SID>X("javaScopeDecl", s:purple, "", "none")
call <SID>X("javaStorageClass", s:orange, "", "none")
call <SID>X("javaBoolean", s:orange, "", "none")

" JavaScript Highlighting
call <SID>X("javaScriptBraces", s:aqua, "", "none")
call <SID>X("javaScriptParens", s:aqua, "", "none")
call <SID>X("javaScriptIdentifier", s:orange, "", "none")
call <SID>X("javaScriptFunction", s:green, "", "none")
call <SID>X("javaScriptConditional", s:purple, "", "none")
call <SID>X("javaScriptRepeat", s:purple, "", "none")
call <SID>X("javaScriptBoolean", s:red, "", "none")
call <SID>X("javaScriptMember", s:orange, "", "none")

" Lua Highlighting
call <SID>X("luaFunc", s:foreground, "", "none")
call <SID>X("luaIn", s:aqua, "", "none")
call <SID>X("luaFunction", s:green, "", "none")
call <SID>X("luaStatement", s:aqua, "", "none")
call <SID>X("luaRepeat", s:aqua, "", "none")
call <SID>X("luaTable", s:blue, "", "none")
call <SID>X("luaConstant", s:blue, "", "none")
call <SID>X("luaElse", s:purple, "", "none")
call <SID>X("luaCond", s:purple, "", "none")

" Makefile Highlighting
call <SID>X("makeIdent", s:aqua, "", "none")
call <SID>X("makeSpecTarget", s:orange, "", "none")
call <SID>X("makeTarget", s:pink, "", "none")
call <SID>X("makeStatement", s:blue, "", "none")
call <SID>X("makeCommands", s:foreground, "", "none")
call <SID>X("makeSpecial", s:red, "", "none")

" Markdown Highlighting
call <SID>X("markdownH1", s:green, "", "none")
call <SID>X("markdownBlockquote", s:green, "", "none")
call <SID>X("markdownCodeBlock", s:purple, "", "none")
call <SID>X("markdownLink", s:aqua, "", "none")
call <SID>X("mkdCode", s:foreground, s:lightgrey, "none")
call <SID>X("mkdLink", s:aqua, "", "none")
call <SID>X("mkdURL", s:darkgrey, "", "none")
call <SID>X("mkdString", s:foreground, "", "none")
call <SID>X("mkdBlockQuote", s:foreground, s:lightgrey, "none")
call <SID>X("mkdLinkTitle", s:green, "", "none")
call <SID>X("mkdDelimiter", s:blue, "", "none")
call <SID>X("mkdRule", s:green, "", "none")

" Perl Highlighting
call <SID>X("perlFiledescRead", s:blue, "", "none")
call <SID>X("perlMatchStartEnd", s:green, "", "none")
call <SID>X("perlStatementFlow", s:green, "", "none")
call <SID>X("perlStatementFiledesc", s:red, "", "none")
call <SID>X("perlStatementStorage", s:green, "", "none")
call <SID>X("perlFunction", s:green, "", "none")
call <SID>X("perlMethod", s:foreground, "", "none")
call <SID>X("perlVarPlain", s:orange, "", "none")
call <SID>X("perlSharpBang", s:darkgrey, "", "none")
call <SID>X("perlStatementInclude", s:blue, "", "none")
call <SID>X("perlStatementScalar", s:purple, "", "none")
call <SID>X("perlSubName", s:blue, "", "none")
call <SID>X("perlSpecialString", s:orange, "", "none")

" PHP Highlighting
call <SID>X("phpIdentifier", s:foreground, "", "none")
call <SID>X("phpVarSelector", s:green, "", "none")
call <SID>X("phpKeyword", s:aqua, "", "none")
call <SID>X("phpStatement", s:green, "", "none")
call <SID>X("phpAssignByRef", s:blue, "", "none")
call <SID>X("phpComparison", s:blue, "", "none")
call <SID>X("phpBackslashSequences", s:orange, "", "none")
call <SID>X("phpMemberSelector", s:aqua, "", "none")
call <SID>X("phpStorageClass", s:purple, "", "none")
call <SID>X("phpDefine", s:orange, "", "none")

" Python Highlighting
call <SID>X("pythonExceptions", s:pink, "", "none")
call <SID>X("pythonException", s:purple, "", "none")
call <SID>X("pythonInclude", s:pink, "", "none")
call <SID>X("pythonStatement", s:green, "", "none")
call <SID>X("pythonConditional", s:purple, "", "none")
call <SID>X("pythonRepeat", s:purple, "", "none")
call <SID>X("pythonFunction", s:blue, "", "none")
call <SID>X("pythonOperator", s:purple, "", "none")
call <SID>X("pythonBuiltin", s:foreground, "", "none")
call <SID>X("pythonDecorator", s:red, "", "none")
call <SID>X("pythonString", s:orange, "", "none")
call <SID>X("pythonEscape", s:orange, "", "none")

" Ruby Highlighting
call <SID>X("rubyModule", s:orange, "", "none")
call <SID>X("rubyClass", s:green, "", "none")
call <SID>X("rubyPseudoVariable", s:darkgrey, "", "none")
call <SID>X("rubyKeyword", s:green, "", "none")
call <SID>X("rubyInstanceVariable", s:purple, "", "none")
call <SID>X("rubyFunction", s:foreground, "", "none")
call <SID>X("rubyDefine", s:green, "", "none")
call <SID>X("rubySymbol", s:blue, "", "none")
call <SID>X("rubyConstant", s:aqua, "", "none")
call <SID>X("rubyAccess", s:orange, "", "none")
call <SID>X("rubyAttribute", s:blue, "", "none")
call <SID>X("rubyInclude", s:pink, "", "none")
call <SID>X("rubyLocalVariableOrMethod", s:red, "", "none")
call <SID>X("rubyCurlyBlock", s:foreground, "", "none")
call <SID>X("rubyCurlyBlockDelimiter", s:blue, "", "none")
call <SID>X("rubyArrayDelimiter", s:blue, "", "none")
call <SID>X("rubyStringDelimiter", s:orange, "", "none")
call <SID>X("rubyInterpolationDelimiter", s:red, "", "none")
call <SID>X("rubyConditional", s:purple, "", "none")
call <SID>X("rubyRepeat", s:purple, "", "none")
call <SID>X("rubyControl", s:purple, "", "none")
call <SID>X("rubyException", s:purple, "", "none")
call <SID>X("rubyExceptional", s:purple, "", "none")
call <SID>X("rubyBoolean", s:blue, "", "none")

" Shell Highlighting
call <SID>X("shDerefVar", s:blue, "", "none")
call <SID>X("shDerefSimple", s:blue, "", "none")
call <SID>X("shFunction", s:orange, "", "none")
call <SID>X("shStatement", s:green, "", "none")
call <SID>X("shLoop", s:purple, "", "none")
call <SID>X("shQuote", s:orange, "", "none")
call <SID>X("shCaseEsac", s:blue, "", "none")
call <SID>X("shSnglCase", s:purple, "", "none")
call <SID>X("shFunctionOne", s:orange, "", "none")
call <SID>X("shCase", s:orange, "", "none")
call <SID>X("bashStatement", s:green, "", "none")

" SQL Highlighting
call <SID>X("sqlStatement", s:green, "", "none")
call <SID>X("sqlType", s:aqua, "", "none")
call <SID>X("sqlKeyword", s:green, "", "none")
call <SID>X("sqlOperator", s:blue, "", "none")
call <SID>X("sqlSpecial", s:blue, "", "none")
call <SID>X("mysqlVariable", s:orange, "", "none")
call <SID>X("mysqlType", s:aqua, "", "none")
call <SID>X("mysqlKeyword", s:green, "", "none")
call <SID>X("mysqlOperator", s:blue, "", "none")
call <SID>X("mysqlSpecial", s:blue, "", "none")

" TeX Highlighting
call <SID>X("texBoldStyle", s:pink, "", "none")
call <SID>X("texItalStyle", s:pink, "", "none")
call <SID>X("texBoldItalStyle", s:purple, "", "none")
call <SID>X("texItalBoldStyle", s:purple, "", "none")

" Vim Highlighting
call <SID>X("vimCommand", s:green, "", "none")
call <SID>X("vimVar", s:orange, "", "none")
call <SID>X("vimFuncKey", s:green, "", "none")
call <SID>X("vimFunction", s:aqua, "", "none")
call <SID>X("vimNotFunc", s:green, "", "none")
call <SID>X("vimMap", s:pink, "", "none")
call <SID>X("vimAutoEvent", s:blue, "", "none")
call <SID>X("vimMapModKey", s:blue, "", "none")
call <SID>X("vimFuncName", s:purple, "", "none")
call <SID>X("vimIsCommand", s:foreground, "", "none")
call <SID>X("vimFuncVar", s:blue, "", "none")
call <SID>X("vimLet", s:pink, "", "none")
call <SID>X("vimMapRhsExtend", s:foreground, "", "none")
call <SID>X("vimCommentTitle", s:darkgrey, "", "none")
call <SID>X("vimBracket", s:blue, "", "none")
call <SID>X("vimParenSep", s:blue, "", "none")
call <SID>X("vimSynType", s:orange, "", "none")
call <SID>X("vimNotation", s:blue, "", "none")
call <SID>X("vimOper", s:foreground, "", "none")
call <SID>X("vimOperParen", s:foreground, "", "none")

" XML Highlighting
call <SID>X("xmlTag", s:green, "", "none")
call <SID>X("xmlTagName", s:green, "", "none")
call <SID>X("xmlEndTag", s:green, "", "none")
call <SID>X("xmlAttrib", s:aqua, "", "none")

" Delete Functions
delfunction <SID>X
delfunction <SID>rgb
delfunction <SID>colour
delfunction <SID>rgb_colour
delfunction <SID>rgb_level
delfunction <SID>rgb_number
delfunction <SID>grey_colour
delfunction <SID>grey_level
delfunction <SID>grey_number
