" plugins
" =======
call plug#begin('~/.vim/plugged')
Plug 'https://github.com/Raimondi/delimitMate.git'
Plug 'https://github.com/scrooloose/nerdtree.git'
Plug 'https://github.com/vim-syntastic/syntastic.git'
Plug 'https://github.com/tpope/vim-commentary.git'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'https://github.com/tpope/vim-surround.git'
Plug 'https://github.com/tpope/vim-eunuch.git'
Plug 'https://github.com/yegappan/greplace.git'
Plug 'https://github.com/google/vim-searchindex.git'
Plug 'https://github.com/gioele/vim-autoswap.git'
Plug 'https://github.com/majutsushi/tagbar.git'
Plug 'https://github.com/prabirshrestha/vim-lsp.git'
Plug 'https://github.com/prabirshrestha/async.vim'
call plug#end()

" variables
" =========
let mapleader = " "

let delimitMate_expand_cr = 1
au filetype plaintex,tex let b:delimitMate_quotes = "\" ' $"
" this is defaulted to comment, below will enable delimitMate
" within comments
let delimitMate_excluded_regions = ""

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

" pre-vimrc
" =========
if filereadable($HOME . "/.pre-vimrc")
  source $HOME/.pre-vimrc
endif

" functions
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
  return

  let l:ft = &filetype
  if ft == "c"
    let l:header = l:buf[:-2] . 'h'
  else
    let l:header = l:buf[:-4] . 'h'
  endif
  exe 'vsp ' . l:header
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

function! CSUpd()
  for l:line in readfile($HOME . "/.t_col", '', 2)
    if line =~ 'wh'
      let g:color_theme = 'light'
    else
      let g:color_theme = 'dark'
    endif
  endfor
  colo CandyPaper2
endfunction

function! NTToggle()
  if ! g:NERDTree.IsOpen()
    NERDTreeCWD
  else
    NERDTreeClose
  endif
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
  " writable or non-existent file
  if filewritable(bufname('%')) || empty(glob(bufname('%')))
    exe 'w'
  else
    exe 'w !sudo tee > /dev/null %'
  endif
endfunction

func! CopyToClipboard(str)
  if has('xterm_clipboard')
    let @* = a:str
  else
    " TODO: why the following fails in Ubuntu 18.04.
    " call system("xsel", a:str)
    exe 'silent !echo -n "' . a:str . '" | xsel'
    exe 'redraw!'
  endif
endfunc

func! FoldIfDef()
  set foldmarker=#if,#endif
  set foldmethod=marker
endfunc

function! SpellToggle()
  set spell!
  if &spell == 1
    echo "Spell-check on"
  else
    echo "Spell-check off"
  endif
endfunction

" commands
" ========
command! Cl :call CleanMe()
command! Gnu :call Gnu()
command! Fif :call FoldIfDef()
command! Cdb :lcd %:p:h
command! Cds :call Cds()
command! Gd :Gdiff <bar> :wincmd l <bar> :wincmd H
command! GD :Gdiff <bar> :wincmd l <bar> :wincmd H
command! Csi :call CSInv()
au filetype c,cpp,cuda command! CPair :call CPair()

" mappings
" ========
" To understand the alt keybinding headache in vim, see:
" https://groups.google.com/forum/#!topic/vim_dev/zmRiqhFfOu8
" https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim
"
" Stick to xterm! Moolenaar does I guess. Nevertheless, try to minimize
" dependency on alt key-bindings

" visual
" ------
vmap <C-_> gc
vnoremap <C-x> d
vnoremap <C-c> y
vnoremap d "_d

" leader
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

" lsp
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

" basic, plugins etc.
" -------------------
nnoremap / <esc><esc>/

" don't do anything
nnoremap <C-o> <esc>

nnoremap <C-p> :FZF<CR>
nnoremap <C-n> :on<CR>
nnoremap <C-x> :q<CR>
imap <C-_> <esc>gcci
nnoremap <C-]> g<C-]>
inoremap <C-z> <C-o>u
inoremap <C-r> <C-o><C-r>
" sometimes C-] is not enough (TODO why?)
nnoremap <C-]> g<C-]>
nnoremap <A-]> <Esc>:tab tjump <C-r><C-w><CR>

" FIXME! This is a workaround! The problem:
" for (...)<CR>
"   |
"
" for (...)
" {|
"
" ie. braces always shift left in a new line in c/c++/java etc. files. This is
" some weird vim default non-sense for c-style source. I disabled all the
" plugins and verified.
" FIXME! This is for GNU indent style, but adding under our Gnu() function
" doesn't work due to delimitMate.
" Yes, the d is just a random character.
inoremap { d{<left><bs><right>}<left>
" Similarly for # in c/c++
inoremap # d#<left><bs><right>

" double escape forces command mode from <C-o> mode
nnoremap gg <esc><esc>mxgg
nnoremap zz :call Save()<CR>
nnoremap hh :noh<CR>
nnoremap tt :TagbarToggle<CR>
nnoremap dt :difft<CR>

" cut/copy/select
" ----------------
inoremap <C-p> <C-x>
inoremap <C-w> <C-o>viw
inoremap <C-c> <esc>^"*y$i
inoremap <C-x> <esc>^"*d$"_ddi
inoremap <C-e> <esc>"_ddi
inoremap <C-d> <C-o>"_diw
" NOTE:
" - The <esc>`^ stops the cursor from going back in normal mode.
" - 'P' prepends the paste.
" FIXME: pasting at ^ pastes after ^, using 'P' fixes this, but then it wrecks
" pasting at $. Fix this "b/w rock and hard place" situation.
"
" `[v`]= indents the paste. The last `] moves cursor to end of paste.
inoremap <C-v> <esc>p`[v`]=`]i<right>

" cut/copy append mode (only for lines)
" -------------------------------------
nnoremap <C-a><C-c> "Ayy
nnoremap <C-a><C-v> "Ap<esc>`[v`]=`]i<right>
nnoremap <C-a><C-r> :call setreg('a', "")<CR>

" <FX> cmds
" ---------
au filetype plaintex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdftex -interaction nonstopmode '.shellescape('%') <CR>
au filetype tex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdflatex -interaction nonstopmode '.shellescape('%') <CR>

" controlled cursor movement
" --------------------------
call MapAll('<C-i>', '<up>', '<up>', '<up>')
call MapAll('<C-k>', '<down>', '<down>', '<down>')
call MapAll('<C-j>', '<left>', '<left>', '<left>')
call MapAll('<C-l>', '<right>', '<right>', '<right>')

" alternate cursor movement
" -------------------------
call MapAll('<A-i>', '{', '<C-o>{', '')
call MapAll("\ei", '{', '<C-o>{', '')
call MapAll('<A-k>', '}', '<C-o>}', '')
call MapAll("\ek", '}', '<C-o>}', '')
call MapAll('<A-j>', 'b', '<C-o>b', '<S-left>')
call MapAll("\ej", 'b', '<C-o>b', '<S-left>')
call MapAll('<A-l>', 'w', '<C-o>w', '<S-right>')
call MapAll("\el", 'w', '<C-o>w', '<S-right>')

" controlled alternate cursor movement
" ------------------------------------
call MapAll('<C-A-i>', '5k', '<C-o>5k', '')
call MapAll("\e<C-i>", '5k', '<C-o>5k', '')
call MapAll('<C-A-k>', '5j', '<C-o>5j', '')
call MapAll("\e<C-k>", '5j', '<C-o>5j', '')
call MapAll('<C-A-j>', '3b', '<C-o>3b', '')
call MapAll("\e<C-j>", '3b', '<C-o>3b', '')
call MapAll('<C-A-l>', '3w', '<C-o>3w', '')
call MapAll("\e<C-l>", '3w', '<C-o>3w', '')

" extra shift cursor binding
" --------------------------
call MapAll('<A-S-j>', '^', '<C-o>^', '')
call MapAll("\eJ", '^', '<C-o>^', '')
call MapAll('<A-S-l>', '$', '<C-o>$', '<Home>')
call MapAll("\eL", '$', '<C-o>$', '<Home>')
call MapAll('<A-S-k>', 'YP', '<C-o>Y<C-o>p', '<End>')
call MapAll("\eK", 'YP', '<C-o>Y<C-o>p', '<End>')

" tab
" ---
call MapAll('<A-,>', ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll("\e,", ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll('<A-.>', ':tabnext<CR>', '<C-o>:tabnext<CR>', '')
call MapAll("\e.", ':tabnext<CR>', '<C-o>:tabnext<CR>', '')

" split
" -----
nnoremap <C-w><C-j> <C-w>h
nnoremap <C-w><C-l> <C-w>l
nnoremap <C-w><C-k> <C-w>j
nnoremap <C-w><C-i> <C-w>k
nnoremap <C-w>J <C-w>H
nnoremap <C-w>L <C-w>L
nnoremap <C-w>I <C-w>K
nnoremap <C-w>K <C-w>J

" The tab mess, arrrgghhh!
" ------------------------
" <C-i> = <Tab>, no rainbow without a little rain
" <C-@> means <C-space>
inoremap <C-@> <tab>
" For tab completion in command mode
" Need to set this to make the mapping work
set wildcharm=<tab>
cnoremap <C-@> <tab>

" set
" ===
set t_Co=256
set notitle
set termguicolors " for highlight guixx in xterm
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

" use %#BoldStatusLine#foobar%#StatusLine to add bold texts to our
" statusline
set statusline =
set statusline +=\ %{mode()}
" set statusline +=\ %{expand('%:p:h:t')}/%t " short path
set statusline +=\ %<%F " full path, '<' truncates the path
set statusline +=\ \ %{tagbar#currenttag('%s','','%f')}
set statusline +=%m " modified flag
set statusline +=\ %r " readonly flag

set statusline +=%=
silent! set statusline +=\ %{fugitive#statusline()} " current git branch
set statusline +=\ %{&ff} " file format
set statusline +=%y " file type
set statusline +=[%{strlen(&fenc)?&fenc:'none'}] " file encoding
set statusline +=\ %v " column number
set statusline +=\ %l " current line
set statusline +=/%L " total lines

au BufRead,BufNewFile *.hip set filetype=cpp
au BufRead,BufNewFile *.s set filetype=xasm
au BufRead,BufNewFile *.ll set filetype=llvm
au BufRead,BufNewFile *.mlir set filetype=mlir
au BufRead,BufNewFile lit.*cfg set filetype=python
au BufRead,BufNewFile *.td set filetype=tablegen
au BufRead,BufNewFile *.cpp.inc set filetype=cpp
au BufRead,BufNewFile *.h.inc set filetype=cpp
au BufRead,BufNewFile *.def set filetype=cpp
au BufNewFile,BufRead *.c.* set filetype=rtl

au FileType llvm setlocal commentstring=;\ %s
au FileType mlir setlocal commentstring=//\ %s
au FileType cpp setlocal commentstring=//\ %s
  \| set comments^=:///
" see https://stackoverflow.com/questions/27403413/vims-tab-length-is-different-for-py-files
" aug python
    " ftype/python.vim overwrites this
    " au FileType python setlocal ts=2 sts=2 sw=2
" aug end

" syntax
" ======
" The following is done by vim-plug, uncomment if using another
" plugin-manager that doesn't do so.
" syntax on
" filetype plugin indent on
call CSUpd()
hi link llvmKeyword Special

if executable('clangd')
  augroup lsp_clangd
    au!
    au User lsp_setup call lsp#register_server({
      \ 'name': 'clangd',
      \ 'cmd': {server_info->['clangd']},
      \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cuda'],
      \ })
    au FileType c,cpp,objc,objcpp,cuda setlocal omnifunc=lsp#complete
  augroup end
endif

" other autocmds
" ==============
autocmd vimenter * call CSUpd() | call setreg('a', "")
  \| highlight trailingSpace ctermbg=red guibg=red
  \| match trailingSpace /\s\+\%#\@<!$/
au insertenter * exe 'hi! StatusLine ctermbg=047 guibg=#00ff5f'
  \| exe 'hi! BoldStatusLine cterm=bold gui=bold '
  \. 'guifg=#000000 ctermbg=047 guibg=#00ff5f'
au insertleave * exe 'hi! StatusLine ctermbg=220 guibg=#ffdf00'
  \| exe 'hi! BoldStatusLine cterm=bold gui=bold '
  \. 'guifg=#000000 ctermbg=220 guibg=#ffdf00'
au TabEnter * NERDTreeClose
au TabLeave * if g:NERDTree.IsOpen() | wincmd p
au! CompleteDone * if pumvisible() == 0 | pclose | endif

" post-vimrc
" ==========
if filereadable($HOME . "/.post-vimrc")
  source $HOME/.post-vimrc
endif
