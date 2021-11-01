" Environment variables
" =====================
let $PATH = $RESET_PATH
let $LIBRARY_PATH = $RESET_LIBRARY_PATH
let $LD_LIBRARY_PATH = $RESET_LD_LIBRARY_PATH

" Plugins
" =======
if filereadable($HOME . "/.vim/autoload/plug.vim")
  call plug#begin('~/.vim/plugged')
  Plug 'https://github.com/Raimondi/delimitMate'
  Plug 'https://github.com/scrooloose/nerdtree'
  Plug 'https://github.com/vim-syntastic/syntastic'
  Plug 'https://github.com/tpope/vim-commentary'
  Plug 'https://github.com/tpope/vim-fugitive'
  Plug 'https://github.com/tpope/vim-surround'
  Plug 'https://github.com/tpope/vim-eunuch'
  Plug 'https://github.com/yegappan/greplace'
  Plug 'https://github.com/google/vim-searchindex'
  Plug 'https://github.com/gioele/vim-autoswap'
  Plug 'https://github.com/majutsushi/tagbar'
  Plug 'https://github.com/prabirshrestha/vim-lsp'
  Plug 'https://github.com/prabirshrestha/async.vim'
  Plug 'https://github.com/junegunn/fzf', { 'do': { -> fzf#install() } }
  call plug#end()
endif

" Variables
" =========
let mapleader = " "

let delimitMate_expand_cr = 1
au! filetype plaintex,tex let b:delimitMate_quotes = "\" ' $"
" Enable delimitMate within comments.
let delimitMate_excluded_regions = ""

let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 1.0,
      \ 'relative': v:true, 'yoffset': 1.0 } }

let NERDTreeShowHidden = 1

let g:syntastic_c_compiler = "clang"
let g:syntastic_cpp_compiler = "clang++"
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_mode_map = {
  \ "mode": "active",
  \ "passive_filetypes": ["c", "cpp", "cuda", "tex"] }
let g:syntastic_c_compiler_options = '-Wparentheses'

let g:lsp_signature_help_enabled = 1
let g:lsp_preview_keep_focus = 0
let g:lsp_document_highlight_delay = 0
let g:lsp_document_code_action_signs_enabled = 0
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_echo_delay = 0
let g:lsp_diagnostics_highlights_enabled = 0
let g:lsp_diagnostics_signs_enabled = 0

let g:tagbar_left = 1

let fortran_free_source = 1
let fortran_have_tabs = 1
let fortran_more_precise = 1
let fortran_do_enddo = 1

let s:trailing_space_state = 1
let g:color_theme = "dark"

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

function! MapAll(lhs, n_rhs, i_rhs, c_rhs)
  execute 'nnoremap' a:lhs a:n_rhs
  execute 'vnoremap' a:lhs a:n_rhs
  execute 'inoremap' a:lhs a:i_rhs

  if a:c_rhs != ""
    execute 'cnoremap' a:lhs a:c_rhs
  endif
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

function! Paste(prefix)
  let l:paste_mode = 'p'
  if col(".") == 1
    let l:paste_mode = 'P'
  endif

  " `[v`]= indents the paste. The last `] moves the cursor to the end of the
  " paste.
  call feedkeys(a:prefix . "\<Esc>" . l:paste_mode . "`[v`]=`]i\<Right>")
endfunction

" Commands
" ========
com! Cl :call CleanMe()
com! -nargs=1 R :call FindAMDGPUReg("<args>")
  \ <bar> :call feedkeys("\<Esc>\<Esc>n")
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
au! filetype c,cpp,cuda com! Cp :call CPair()

" Mappings
" ========
" To understand the alt keybinding issue, see:
" - https://groups.google.com/forum/#!topic/vim_dev/zmRiqhFfOu8
" - https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim

" Leader
" ------
nnoremap <Leader>f :set filetype
nnoremap <Leader>l :set list!<CR>
nnoremap <Leader>s :call SpellToggle()<CR>
nnoremap <Leader>w :set wrap!<CR>
nnoremap <Leader>t :call TrailingSpaceMatch()<CR>
nnoremap <Leader>m :SyntasticToggleMode<CR>
nnoremap <Leader>r :SyntasticReset<CR><Esc> pc!<CR>i<Right>
nnoremap <Leader>b :call CopyToClipboard(expand('%:p') . ':' . line('.'))<CR>
nnoremap <Leader>n :call CopyToClipboard(expand('%:p'))<CR>
nnoremap <Leader>v :so $MYVIMRC<CR>
nnoremap <Leader>x :set textwidth=

" Lsp
" ---
nmap <C-\>d :LspDefinition<CR>i
nmap <C-\><S-d> :tab split<CR>:LspDefinition<CR>i
nmap <C-\>s :LspDeclaration<CR>i
nmap <C-\>r :LspReference<CR>i
nmap <C-\><S-R> :LspRename<CR>
nmap <C-\>i :LspHover<CR>i
nmap <C-\>e :LspNextError<CR>
nmap <C-\>l :LspNextReference<CR><Right>i
nmap <C-\><S-l> :LspPreviousReference<CR><Right>i
nmap <C-\>p :LspPeekDefinition<CR>i
nmap <C-\>P :LspPeekDeclaration<CR>i
nmap <C-\>f :LspWorkspaceSymbol<CR>

" Misc
" ----
vmap <C-_> gc
vnoremap <C-x> d
vnoremap <C-c> y
vnoremap d "_d

" Double escape forces command mode from <C-o> mode.
nnoremap / <Esc><Esc>/
nnoremap <C-o> <Esc>

nnoremap <C-p> :FZF<CR>
nnoremap <C-n> :on<CR>
nnoremap <C-x> :q<CR>
imap <C-_> <Esc>gcci
nnoremap <C-]> g<C-]>
inoremap <C-z> <C-o>u
inoremap <C-r> <C-o><C-r>
nnoremap <C-]> g<C-]>

" FIXME! This is a workaround. The problem:
" for (...)<CR>
"   |
"
" for (...)
" {|
"
" I.e. braces always shift left in a new line in C, C++, Java etc. files. This
" might be a vim default behaviour for C-style source.
"
" FIXME! This is for GNU indent style, but adding under our Gnu() function
" doesn't work due to delimitMate.
"
" Note that the d is just a random character.
inoremap { d{<Left><bs><Right>}<Left>
" Similarly for # in C/C++
inoremap # d#<Left><bs><Right>

nnoremap gg <Esc><Esc>mxgg
nnoremap zz :call Save()<CR>
nnoremap hh :noh<CR>
nnoremap tt :TagbarToggle<CR>
nnoremap dt :windo difft<CR><Esc>:wincmd p<CR>
nnoremap dT :windo diffo<CR><Esc>:wincmd p<CR>

" Cut, copy, select
" -----------------
inoremap <C-p> <C-x>
inoremap <C-w> <C-o>viw
inoremap <C-c> <Esc>^"*y$i
inoremap <C-x> <Esc>^"*d$"_ddi
inoremap <C-e> <Esc>"_ddi
inoremap <C-d> <C-o>"_diw
inoremap <C-v> <C-o>:call Paste('')<CR>

" Cut, copy in append mode
" ------------------------
nnoremap <C-a><C-c> "Ayy
nnoremap <C-a><C-v> :call Paste('"Ap')
nnoremap <C-a><C-r> :call setreg('a', "")<CR>

" <FX>
" ----
au! filetype plaintex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdftex -interaction nonstopmode '.shellescape('%') <CR>
au! filetype tex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdflatex -interaction nonstopmode '.shellescape('%') <CR>

" Cursor movement
" ---------------
call MapAll('<C-i>', '<Up>', '<Up>', '<Up>')
" <C-i> mimics <Tab>. <C-@> mimics ctrl + space.
inoremap <C-@> <Tab>
" The following 2 statements allow tab completion in command mode.
set wildcharm=<Tab>
cnoremap <C-@> <Tab>
call MapAll('<C-k>', '<Down>', '<Down>', '<Down>')
call MapAll('<C-j>', '<Left>', '<Left>', '<Left>')
call MapAll('<C-l>', '<Right>', '<Right>', '<Right>')

call MapAll('<A-i>', '{', '<C-o>{', '')
call MapAll("\ei", '{', '<C-o>{', '')
call MapAll('<A-k>', '}', '<C-o>}', '')
call MapAll("\ek", '}', '<C-o>}', '')
call MapAll('<A-j>', 'b', '<C-o>b', '<S-left>')
call MapAll("\ej", 'b', '<C-o>b', '<S-left>')
call MapAll('<A-l>', 'w', '<C-o>w', '<S-right>')
call MapAll("\el", 'w', '<C-o>w', '<S-right>')

call MapAll('<C-A-i>', '5k', '<C-o>5k', '')
call MapAll("\e<C-i>", '5k', '<C-o>5k', '')
call MapAll('<C-A-k>', '5j', '<C-o>5j', '')
call MapAll("\e<C-k>", '5j', '<C-o>5j', '')
call MapAll('<C-A-j>', '3b', '<C-o>3b', '')
call MapAll("\e<C-j>", '3b', '<C-o>3b', '')
call MapAll('<C-A-l>', '3w', '<C-o>3w', '')
call MapAll("\e<C-l>", '3w', '<C-o>3w', '')

call MapAll('<A-S-j>', '^', '<C-o>^', '')
call MapAll("\eJ", '^', '<C-o>^', '')
call MapAll('<A-S-l>', '$', '<C-o>$', '<Home>')
call MapAll("\eL", '$', '<C-o>$', '<Home>')
call MapAll('<A-S-k>', 'YP', '<C-o>Y<C-o>p', '<End>')
call MapAll("\eK", 'YP', '<C-o>Y<C-o>p', '<End>')

" Tab
" ---
call MapAll('<A-,>', ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll("\e,", ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll('<A-.>', ':tabnext<CR>', '<C-o>:tabnext<CR>', '')
call MapAll("\e.", ':tabnext<CR>', '<C-o>:tabnext<CR>', '')

" Split
" -----
nnoremap <C-w><C-j> <C-w>h
nnoremap <C-w><C-l> <C-w>l
nnoremap <C-w><C-k> <C-w>j
nnoremap <C-w><C-i> <C-w>k
nnoremap <C-w>J <C-w>H
nnoremap <C-w>L <C-w>L
nnoremap <C-w>I <C-w>K
nnoremap <C-w>K <C-w>J

" Set
" ===
set t_Co=256
set notitle
set termguicolors " For highlight guixx in xterm.
set background=dark
set ruler
set noshowmode
set nowrap
set number

set ttimeoutlen=50
set scrolloff=5
set backspace=2

set tabstop=2
set shiftwidth=2
set softtabstop=2
set smartindent
set smarttab
set expandtab
set textwidth=80

set laststatus=2
set pastetoggle=<F2>
set completeopt=noselect,menuone,preview
set autoread
set diffopt+=vertical
set clipboard=unnamed
set mouse=a
set hlsearch
set incsearch
set splitright
set ignorecase
set smartcase
set rtp+=~/.fzf
set directory=~/.cache/vim/swap//

" Use %#BoldStatusLine#foobar%#StatusLine to add bold texts to our statusline.
set statusline =
set statusline +=\ %{mode()}
" Set statusline +=\ %{expand('%:p:h:t')}/%t " Short path
set statusline +=\ %<%F " Full path; '<' truncates the path.
set statusline +=\ \ %{exists('g:loaded_tagbar')?
      \tagbar#currenttag('%s','','%f'):''}
set statusline +=%m " Modified flag
set statusline +=\ %r " Readonly flag

set statusline +=%=
set statusline +=%{exists('g:loaded_fugitive')?fugitive#statusline():''}
set statusline +=\ %{&ff} " File format
set statusline +=%y " File type
set statusline +=[%{strlen(&fenc)?&fenc:'none'}] " File encoding
set statusline +=\ %v " Column number
set statusline +=\ %l " Current line
set statusline +=/%L " Total lines

au! BufRead,BufNewFile *.cl set filetype=c
au! BufRead,BufNewFile *.hip set filetype=cpp
au! BufRead,BufNewFile *.s set filetype=xasm
au! BufRead,BufNewFile *.{ll,mir} set filetype=llvm
au! BufRead,BufNewFile *.mlir set filetype=mlir
au! BufRead,BufNewFile lit.*cfg set filetype=python
au! BufRead,BufNewFile *.td set filetype=tablegen
au! BufRead,BufNewFile *.{inc,def} set filetype=cpp
au! BufNewFile,BufRead *.c.* set filetype=rtl
au! BufRead,BufNewFile *.{gvy,Jenkinsfile} set filetype=groovy

au! FileType llvm setlocal commentstring=;\ %s
au! FileType mlir setlocal commentstring=//\ %s
au! FileType cpp setlocal commentstring=//\ %s | set comments^=:///

" Syntax
" ======
syntax on
filetype plugin indent on
colo CandyPaper2
hi link llvmKeyword Special

if executable('clangd')
  augroup lsp_clangd
    " Remove all lsp_clangd autocommands.
    au!

    au User lsp_setup call lsp#register_server({
      \ 'name': 'clangd',
      \ 'cmd': {server_info->['clangd']},
      \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cuda'],
      \ })
    au FileType c,cpp,objc,objcpp,cuda setlocal omnifunc=lsp#complete
  augroup end
endif

" Other autocmds
" ==============
au! vimenter * call setreg('a', "")
  \| highlight trailingSpace ctermbg=red guibg=red
  \| match trailingSpace /\s\+\%#\@<!$/
au! insertenter * exe 'hi! StatusLine ctermbg=047 guibg=#00ff5f'
  \. ' ctermfg=016 guifg=#000000'
au! insertleave * exe 'hi! StatusLine ctermbg=220 guibg=#ffdf00'
  \. ' ctermfg=016 guifg=#000000'

au! CompleteDone * if pumvisible() == 0 | pclose | endif

" .post-vimrc
" ===========
if filereadable($HOME . "/.post-vimrc")
  source $HOME/.post-vimrc
endif
