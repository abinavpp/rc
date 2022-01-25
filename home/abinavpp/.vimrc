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
  call plug#end()
endif

" Variables
" =========
let mapleader = 'm'
let fortran_free_source = 1
let fortran_have_tabs = 1
let fortran_more_precise = 1
let fortran_do_enddo = 1
let s:trailing_space_state = 1
let g:color_theme = "dark"
let g:tagbar_left = 1
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

" .pre-vimrc
" ==========
if filereadable($HOME . "/.pre-vimrc")
  source $HOME/.pre-vimrc
endif

" Functions
" =========
function! CleanMe()
  silent! exec '%s/\v\ +$//g'
  silent! exec '%s/\v[^\x00-\x7F]+//g'
endfunction

function! DiffToggle()
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
  if s:trailing_space_state == 0
    let s:trailing_space_state = 1
    match trailingSpace /\s\+\%#\@<!$/
    echo "Trailing-space-match on"
  else
    let s:trailing_space_state = 0
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

function! Gnu()
  set tabstop=8
  match none
endfunction

function! CPair()
  let l:buf = bufname('%')
  let l:pair = system('srcerer ' . l:buf)
  if l:pair != ""
    exec 'vsp ' . l:pair
  endif
endfunction

function! Cds()
  let l:root = system('srcerer')
  if l:root != ""
    exec 'cd ' . l:root
  endif
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
  nnoremap <buffer><Leader>lD :tab split<CR>:LspDefinition<CR>
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

function! FoldIfDef()
  set foldmarker=#if,#endif
  set foldmethod=marker
endfunction

function! SpellToggle()
  set spell!
  if &spell == 1
    echo "Spell-check on"
  else
    echo "Spell-check off"
  endif
endfunction

function! Glg(range, line1, line2)
  if a:range == 0
    execute '0Gllog!'
  elseif a:range == 1
    execute a:line1 . 'Gllog!'
  else
    execute a:line1 . ',' . a:line2 . 'Gllog!'
  endif
endfunction

" Commands
" ========
com! Cl :call CleanMe()
com! -nargs=1 R :call FindAMDGPUReg("<args>")
  \ <bar> :call feedkeys("\<Esc>\<Esc>n")
com! Vs :call Vp('\*\*\* IR Dump ')
com! Vl :call Vp('\v^\p+:$')
com! Vd :call Vp(expand("<cword>") . '.*=')
com! Gnu :call Gnu()
com! Fif :call FoldIfDef()
com! Cdb :lcd %:p:h
com! Cds :call Cds()
com! Gbl :Git blame
com! -range Glg call Glg(<range>, <line1>, <line2>)
com! Gr :Gedit
com! Gd :Gdiffsplit <bar> :wincmd l <bar> :wincmd H
com! GD :Gdiffsplit <bar> :wincmd l <bar> :wincmd H
com! Csi :call CSInv()
com! Dcl :call DelCommentLines()
com! Df :call DiffToggle()
com! Wr :set wrap!
com! Li :set list!
au! FileType c,cpp,cuda com! Cp :call CPair()

" Mappings
" ========
" To understand the alt keybinding issue, see:
" - https://groups.google.com/forum/#!topic/vim_dev/zmRiqhFfOu8
" - https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim

nnoremap zz :call Save()<CR>
nnoremap ZZ :q<CR>
nnoremap U <C-r>
nnoremap V :normal 0v$<CR>
nnoremap <Leader>d "_d
vnoremap <Leader>d "_d
nnoremap x "_x
nnoremap X "_X
nnoremap c "_c
nnoremap C "_C
inoremap <C-p> <C-x>
nnoremap <silent><expr> n (v:searchforward ? 'n' : 'N') . ":SearchIndex<CR>"
nnoremap <silent><expr> N (v:searchforward ? 'N' : 'n') . ":SearchIndex<CR>"
call Map("\ej", "}")
call Map("\ek", "{")
call Map("\eh", "^")
call Map("\el", "$")
nnoremap <Leader>w <C-w>
nnoremap <Leader>sf :set filetype
nnoremap <Leader>ss :call SpellToggle()<CR>
nnoremap <Leader>t :call TrailingSpaceMatch()<CR>
nnoremap <Leader>b :call CopyToClipboard(expand('%:p') . ':' . line('.'))<CR>
nnoremap <Leader>n :call CopyToClipboard(expand('%:p'))<CR>
nnoremap <Leader>v :so $MYVIMRC<CR>
nnoremap <Leader>x :set textwidth=
nnoremap <Leader>vs `[v`]
nnoremap <Leader>h :noh<CR>
nnoremap <Leader>f :FZF<CR>
nnoremap <Leader>ld :exe 'tag' expand('<cword>')<CR>
nnoremap <Leader>lD :tab sp<CR>:exe 'tag' expand('<cword>')<CR>
nnoremap <Leader>le :SyntasticCheck<CR>
nnoremap <Leader>lt :TagbarToggle<CR>
nnoremap <Leader>lb <C-t>

" FIXME! This is a workaround. The problem:
" for (...)<CR>
"   |
"
" for (...)
" {|
"
" I.e. braces in a new line always align with the parent indentation. This might
" be a vim default behaviour for C-style source.
"
" FIXME! This is for GNU indent style, but adding under our Gnu() function
" doesn't work due to delimitMate.
"
" Note that the d is just a random character.
inoremap { d{<Left><BS><Right>
" Similarly:
inoremap # d#<Left><BS><Right>

" Set
" ===
set rtp+=~/.fzf directory=~/.cache/vim/swap//
set notitle ruler noshowmode nowrap number relativenumber
set hlsearch incsearch ignorecase smartcase completeopt=noselect,menuone,preview
set splitright diffopt+=vertical autoread ttimeoutlen=50
set tabstop=2 shiftwidth=2 softtabstop=2 smartindent smarttab expandtab
set textwidth=80 scrolloff=5 backspace=2
set clipboard^=unnamed,unnamedplus mouse=a termguicolors background=dark

set laststatus=2 statusline=
set statusline+=\ %{mode()}
set statusline+=\ %<%F " Full path; '<' truncates the path.
set statusline+=\ \ %{exists('g:loaded_tagbar')?
      \tagbar#currenttag('%s','','%f'):''}
set statusline+=%m " Modified flag
set statusline+=\ %r " Read-only flag
set statusline+=%=
set statusline+=%{exists('g:loaded_fugitive')?fugitive#statusline():''}
set statusline+=\ %{&ff} " File format
set statusline+=%y " File type
set statusline+=[%{strlen(&fenc)?&fenc:'none'}] " File encoding
set statusline+=\ %v " Column number
set statusline+=\ %l " Current line
set statusline+=/%L " Total lines

au! BufRead,BufNewFile *.cl set filetype=c
au! BufRead,BufNewFile *.hip set filetype=cpp
au! BufRead,BufNewFile *.s set filetype=xasm
au! BufRead,BufNewFile *.{ll,mir} set filetype=llvm
au! BufRead,BufNewFile *.mlir set filetype=mlir
au! BufRead,BufNewFile lit.*cfg set filetype=python
au! BufRead,BufNewFile *.td set filetype=tablegen
au! BufRead,BufNewFile *.{inc,def} set filetype=cpp
au! BufRead,BufNewFile *.c.* set filetype=rtl
au! BufRead,BufNewFile *.{gvy,Jenkinsfile} set filetype=groovy

au! FileType llvm setlocal commentstring=;\ %s | set textwidth=0
au! FileType mlir setlocal commentstring=//\ %s
au! FileType cpp setlocal commentstring=//\ %s | set comments^=:///

au! VimEnter * call setreg('a', "")
au! CompleteDone * if pumvisible() == 0 | pclose | endif

" Syntax and colors
" =================
call Lsp(['clangd'], ['c', 'cpp', 'objc', 'objcpp', 'cuda'])
call Lsp(['rust-analyzer'], ['rust'])
call Lsp(['pyls'], ['python'])
call Lsp(['typescript-language-server', '--stdio'], ['javascript',
  \ 'typescript'])

syntax on
filetype plugin indent on
colo CandyPaper2
hi link llvmKeyword Special

" .post-vimrc
" ===========
if filereadable($HOME . "/.post-vimrc")
  source $HOME/.post-vimrc
endif
