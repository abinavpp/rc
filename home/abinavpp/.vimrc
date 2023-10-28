" Environment variables
" =====================
let $PATH = $RESET_PATH
let $LIBRARY_PATH = $RESET_LIBRARY_PATH
let $LD_LIBRARY_PATH = $RESET_LD_LIBRARY_PATH

" Plugins
" =======
if filereadable($HOME . "/.vim/autoload/plug.vim")
  call plug#begin('~/.vim/plugged')
  Plug 'https://github.com/vim-syntastic/syntastic'
  Plug 'https://github.com/tpope/vim-commentary'
  Plug 'https://github.com/tpope/vim-fugitive'
  Plug 'https://github.com/tpope/vim-surround'
  Plug 'https://github.com/google/vim-searchindex'
  Plug 'https://github.com/gioele/vim-autoswap'
  Plug 'https://github.com/majutsushi/tagbar'
  Plug 'https://github.com/prabirshrestha/vim-lsp'
  Plug 'https://github.com/junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'https://github.com/junegunn/fzf.vim'
  call plug#end()
endif

" Variables
" =========
let mapleader = 'm'
let fortran_free_source = 1
let fortran_have_tabs = 1
let fortran_more_precise = 1
let fortran_do_enddo = 1
let s:trailing_space_match_state = 1
let g:color_theme = "dark"
let g:tagbar_left = 1
let g:tagbar_show_linenumbers = 2
let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 1.0,
  \ 'relative': v:true, 'yoffset': 1.0 } }
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],
  \ 'passive_filetypes': [] }
let g:syntastic_auto_loc_list = 1
let g:lsp_signature_help_enabled = 1
let g:lsp_preview_keep_focus = 0
let g:lsp_document_highlight_delay = 0
let g:lsp_document_code_action_signs_enabled = 0
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_echo_delay = 0
let g:lsp_diagnostics_highlights_enabled = 0
let g:lsp_diagnostics_signs_enabled = 0
let g:lsp_diagnostics_virtual_text_enabled = 0

" .pre-vimrc
" ==========
if filereadable($HOME . "/.pre-vimrc")
  source $HOME/.pre-vimrc
endif

" Functions
" =========
function! StatusLine()
  let l:d = {'n': 'StatusLine', 'c': 'StatusLine', 't': 'StatusLine',
    \ 'v': 'SLv', 'V': 'SLv', "\<C-V>": 'SLvB', 'i': 'SLi'}
  let l:c = '%#SLu#'
  if has_key(l:d, mode())
    let l:c = '%#' . l:d[mode()] . '#'
  endif
  if g:statusline_winid != win_getid(winnr())
    let l:c = ''
  endif
  let l:s = l:c . " %{mode()} %<%F  %{exists('g:loaded_tagbar') ?"
  let l:s .= "tagbar#currenttag('%s', '', '%f') : ''} %m %r"
  let l:s .= "%=%{exists('g:loaded_fugitive') ? fugitive#statusline() : ''}"
  let l:s .= " %{&ff}%y [%{strlen(&fenc) ? &fenc : 'none'}] %v %l/%L"
  return l:s
endfunction

function! ToggleDiff()
  if &diff == 0
    exe 'windo difft'
  else
    exe 'windo diffo'
  endif

  exe 'wincmd p'
endfunction

function! DelCommentLines()
  let l:expr = substitute(&commentstring, '%s', '.*', '')
  exe 'g/^\ *' . l:expr .  '/d'
endfunction

function! TrailingSpaceMatch()
  if s:trailing_space_match_state == 0
    let s:trailing_space_match_state = 1
    match trailingSpace /\s\+\%#\@<!$/
    echo "Trailing-space-match on"
  else
    let s:trailing_space_match_state = 0
    match none
    echo "Trailing-space-match off"
  endif
endfunction

function! FindAMDGPUReg(r)
  let l:f = matchstr(a:r, '\v^[a-zA-Z]+')
  let l:n = matchstr(a:r, '\v[0-9]+$')

  let @/ = '\v<(' . a:r . '|' . l:f . '\[' . l:n . ':[0-9]+\]'
    \. '|' . l:f . '\[[0-9]+:' . l:n . '\])'
endfunction

function! Vp(p)
  let l:n = search(a:p, 'bn')
  echo l:n . ': ' . getline(l:n)
endfunction

function! CSInv()
  if g:color_theme == "light"
    let g:color_theme = 'dark'
  else
    let g:color_theme = 'light'
  endif
  colo CandyPaper2
endfunction

function! Map(lhs, rhs)
  execute 'nnoremap' a:lhs a:rhs
  execute 'vnoremap' a:lhs a:rhs
endfunction

function! MapLsp()
  nnoremap <buffer><Leader>ld :LspDefinition<CR>
  nnoremap <buffer><Leader>ls :LspDeclaration<CR>
  nnoremap <buffer><Leader>lr :LspReference<CR>
  nnoremap <buffer><Leader>lR :LspRename<CR>
  nnoremap <buffer><Leader>li :LspHover<CR>
  nnoremap <buffer><Leader>le :LspNextError<CR>
  nnoremap <buffer><Leader>ll :LspNextReference<CR>
  nnoremap <buffer><Leader>lL :LspPreviousReference<CR>
  nnoremap <buffer><Leader>lp :LspPeekDefinition<CR>
  nnoremap <buffer><Leader>lP :LspPeekDeclaration<CR>
  nnoremap <buffer><Leader>lf :LspWorkspaceSymbol<CR>
  nnoremap <buffer><Leader>la :LspCodeAction<CR>
endfunction

function! Lsp(cmd, fts)
  if ! executable(a:cmd[0])
    return
  endif

  exe "au User lsp_setup call lsp#register_server({'name':'" . a:cmd[0] . "',"
    \ "'cmd':{server_info->['" . join(a:cmd, "','") . "']},"
    \ "'allowlist':['" . join(a:fts, "','") . "']})"
  exe 'au FileType ' . join(a:fts, ',') . ' call MapLsp()'
  exe 'au FileType ' . join(a:fts, ',') . ' setlocal omnifunc=lsp#complete'
endfunction

function! Save()
  if filewritable(bufname('%')) || empty(glob(bufname('%')))
    exe 'w'
  else
    exe 'w !sudo tee > /dev/null %'
  endif
endfunction

function! CopyToClipboard(str)
  if has('xterm_clipboard')
    let @* = a:str
    let @+ = a:str
  else
    exe 'silent !echo -n "' . a:str . '" | xsel'
    exe 'redraw!'
  endif
endfunction

function! ToggleSet(s)
  exe 'set ' . a:s . '! | set ' . a:s . '?'
endfunction

function! Gdiff(a)
  if a:a == ""
    exe 'Gdiffsplit | wincmd l | wincmd H'
  else
    exe 'Gdiffsplit ' . a:a . ' | wincmd h'
  endif
endfunction

function! Glog(range, line1, line2)
  if a:range == 0
    execute '0Gllog!'
  elseif a:range == 1
    execute a:line1 . 'Gllog!'
  else
    execute a:line1 . ',' . a:line2 . 'Gllog!'
  endif
endfunction

function! SetTab(l)
  exe 'setlocal tabstop=' . a:l . ' shiftwidth=' . a:l . ' softtabstop=' . a:l
endfunction

" TODO: Infer this from clang-format
function! Style(s)
  if a:s == "d"
    exe 'setlocal textwidth=80 expandtab'
    call SetTab(2)
  elseif a:s == "s"
    exe 'setlocal textwidth=120 noexpandtab'
    call SetTab(4)
  endif
endfunction

" Commands
" ========
com! Cl :sil! exe '%s/\v\ +$//g' <bar> :sil! exe '%s/\v[^\x00-\x7F]+//g'
com! -nargs=1 R :call FindAMDGPUReg("<args>")
  \ <bar> :call feedkeys("\<Esc>\<Esc>n")
com! Vs :call Vp('\*\*\* IR Dump ')
com! Vl :call Vp('\v^\p+:$')
com! Vd :call Vp(expand("<cword>") . '.*=')
com! Fif :set foldmarker=#if,#endif foldmethod=marker
com! Cdb :lcd %:p:h
com! Gbl :Git blame
com! -range Glg call Glog(<range>, <line1>, <line2>)
com! Gr :Gedit
com! -nargs=? Gd :call Gdiff("<args>")
com! -nargs=? GD :call Gdiff("<args>")
com! Gd1 :call Gdiff("@~1")
com! Gd2 :call Gdiff("@~2")
com! Csi :call CSInv()
com! Dcl :call DelCommentLines()
com! Df :call ToggleDiff()
com! Sv :so $MYVIMRC
com! -nargs=1 St :call SetTab("<args>")
com! -nargs=1 S :call Style("<args>")

" Mappings
" ========
call Map('<Leader>d', '"_d') | call Map('<Leader>D', '"_D')
call Map('x', '"_x') | call Map('X', '"_X')
call Map('c', '"_c') | call Map('C', '"_C')
call Map('I', '^') | call Map('A', '$')
nnoremap <Leader>z :call Save()<CR>
nnoremap U <C-r>
nnoremap <Leader>vs `[v`]
nnoremap <Leader>h :call ToggleSet('hls')<CR>
nnoremap <silent><expr> n (v:searchforward ? 'n' : 'N') . ":SearchIndex<CR>"
nnoremap <silent><expr> N (v:searchforward ? 'N' : 'n') . ":SearchIndex<CR>"
nnoremap <Leader>b :call CopyToClipboard(expand('%:p') . ':' . line('.'))<CR>
nnoremap <Leader>n :call CopyToClipboard(expand('%:p'))<CR>
nnoremap <Leader>w <C-w>
nnoremap <Leader>a :Files<CR>
nnoremap <Leader>f :Buffers<CR>
nnoremap <Leader>x :bd<CR>
nnoremap <Leader>ld :exe 'tag' expand('<cword>')<CR>
nnoremap <Leader>le :SyntasticCheck<CR>
nnoremap <Leader>lt :TagbarToggle<CR>
nnoremap <Leader>lb <C-t>
nnoremap <Leader>sf :set filetype
nnoremap <Leader>sl :call ToggleSet('list')<CR>
nnoremap <Leader>ss :call ToggleSet('spell')<CR>
nnoremap <Leader>sw :call ToggleSet('wrap')<CR>
nnoremap <Leader>si :call ToggleSet('smartindent')<CR>
nnoremap <Leader>st :call TrailingSpaceMatch()<CR>
nnoremap <Leader>sx :set textwidth=
inoremap <C-p> <C-x>
inoremap { d{<Left><BS><Right>
inoremap # d#<Left><BS><Right>
if has('python')
  nnoremap <Leader>c :%pyf /usr/share/clang/clang-format.py<CR>
  vnoremap <Leader>c :pyf /usr/share/clang/clang-format.py<CR>
elseif has('python3')
  nnoremap <Leader>c :%py3f /usr/share/clang/clang-format.py<CR>
  vnoremap <Leader>c :py3f /usr/share/clang/clang-format.py<CR>
endif

" Set
" ===
set directory=~/.cache/vim/swap//
set notitle ruler noshowmode nowrap number relativenumber
set incsearch ignorecase smartcase completeopt=noselect,menuone,preview
set splitright diffopt+=vertical autoread ttimeoutlen=50 hidden
set tabstop=2 shiftwidth=2 softtabstop=2 smartindent smarttab expandtab
set textwidth=80 scrolloff=5 backspace=2
set clipboard^=unnamed,unnamedplus mouse=a termguicolors background=dark
au FileType llvm setlocal commentstring=;\ %s | set textwidth=0
au FileType mlir setlocal commentstring=//\ %s
au FileType cpp,tablegen setlocal commentstring=//\ %s | set comments^=:///
set laststatus=2 statusline=%!StatusLine()
au BufEnter *.cl set filetype=c
au BufEnter *.{hip,inc,def} set filetype=cpp
au BufEnter *.{ll,mir} set filetype=llvm
au BufEnter *.mlir set filetype=mlir
au BufEnter lit.*cfg set filetype=python
au BufEnter *.td set filetype=tablegen
au BufEnter *.c.* set filetype=rtl
au BufEnter *.{gvy,Jenkinsfile} set filetype=groovy
au BufEnter *.yul set filetype=yul
au FileType python setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4

au CompleteDone * if pumvisible() == 0 | pclose | endif

" Syntax and colors
" =================
call Lsp(['clangd', '--header-insertion=iwyu'], ['c', 'cpp', 'objc', 'objcpp',
  \ 'cuda'])
call Lsp(['rust-analyzer'], ['rust'])
call Lsp(['pylsp'], ['python'])
call Lsp(['typescript-language-server', '--stdio'], ['javascript',
  \ 'typescript'])

syntax on
filetype plugin indent on
colo CandyPaper2

" .post-vimrc
" ===========
if filereadable($HOME . "/.post-vimrc")
  source $HOME/.post-vimrc
endif
