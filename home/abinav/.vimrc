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
let $BASH_ENV = "~/.bash_vim"
let sys = substitute(system('uname -r'), '\n\+$', '', '')

let delimitMate_expand_cr = 1

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
  \ "passive_filetypes": ["c", "cpp", "tex"] }
let g:syntastic_c_compiler_options = '-Wparentheses'

" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand('~/vim-lsp.log')
" let g:asyncomplete_log_file = expand('~/asyncomplete.log')
let g:lsp_signature_help_enabled = 1
let g:lsp_signs_enabled = 0
let g:lsp_highlights_enabled = 0 " for neovim
let g:lsp_textprop_enabled = 0
let g:lsp_highlight_references_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_peek_alignment = 'center'
let g:lsp_preview_keep_focus = 0

let g:tagbar_left = 1

let fortran_free_source = 1
let fortran_have_tabs = 1
" let fortran_more_precise = 1
let fortran_do_enddo = 1

" for functions in this file
let s:trailing_space_flag = 1
let g:qcomprun_cflags = "-lpthread -lm"
let g:color_theme = "dark"

if filereadable($HOME . "/vimrc.before")
  source $HOME/vimrc.before
endif

" functions
" =========
function! Chomp(string)
  return substitute(a:string, '\n\+$', '', '')
endfunction

function! CleanMe()
  silent! exec '%s/\v\ +$//g'
  silent! exec '%s/\v[^\x00-\x7F]+//g'
endfunction

function! TrailingSpaceMatch()
  if s:trailing_space_flag == 0
    let s:trailing_space_flag = 1
    match trailingSpace /\s\+\%#\@<!$/
  else
    let s:trailing_space_flag = 0
    match none
  endif
endfunction

function! QCompRun(cmdline)
  if filereadable("Makefile")
    exec '!make &&
          \ find . -maxdepth 1 -type f -perm /0100 -exec ' . a:cmdline . ' {} \;'
  else
    let l:ft = &filetype
    if ft == "c"
      let l:compiler = "gcc "
    elseif ft == "cpp"
      let l:compiler = "g++ "
    elseif ft == "fortran"
      let l:compiler = "gfortran "
    else
      return
    endif

    exec '!' . l:compiler . g:qcomprun_cflags . ' -g ' . shellescape('%') . ';' .
          \a:cmdline . " ./a.out"
  endif
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

function! CsInv()
  if g:color_theme == "light"
    let g:color_theme = 'dark'
  else
    let g:color_theme = 'light'
  endif
  colo CandyPaper2
endfunction

function! CsUpd()
  for l:line in readfile("/home/abinav/.t_col", '', 2)
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

function! MapAll(keys, nrhs, irhs, crhs)
  execute 'nnoremap' a:keys a:nrhs
  execute 'vnoremap' a:keys a:nrhs
  execute 'inoremap' a:keys a:irhs

  if a:crhs != ""
    execute 'cnoremap' a:keys a:crhs
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

func! CopyAsBreakpoint()
  let s:pos=expand('%:p') . ':' . line('.')
  call system("xclip", s:pos)
endfunc

" Commands
" ========
command! Cl :call CleanMe()
command! Cdb :lcd %:p:h
command! Gd :Gdiff <bar> :wincmd l <bar> :wincmd H

" mappings
" ========
" visual
vmap <C-_> gc
vnoremap <C-x> d
vnoremap <C-c> y
vnoremap d "_d
vnoremap / y/<C-R>"<CR>

" follow the leader
nnoremap <Leader>f :set filetype
nnoremap <Leader>l :set list!<CR>
nnoremap <Leader>s :set spell!<CR>
nnoremap <Leader>w :set wrap!<CR>
nnoremap <Leader>t :call TrailingSpaceMatch()<CR>
nnoremap <Leader>n :call NTToggle()<CR>
nnoremap <Leader>m :SyntasticToggleMode<CR>
nnoremap <Leader>r :SyntasticReset<CR><Esc> pc!<CR>i<Right>
nnoremap <Leader>p :FZF
nnoremap <Leader>b :call CopyAsBreakpoint()<cr>
nnoremap <Leader>c :call CsInv()<CR>
nnoremap <Leader>v :so $MYVIMRC<CR>
nnoremap <Leader>x :set textwidth=

" To understand the alt keybinding headache in vim, see:
" https://groups.google.com/forum/#!topic/vim_dev/zmRiqhFfOu8
" https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim
"
" Stick to xterm! Moolenaar does I guess. Nevertheless, try to minimize dependency on
" alt key-bindings

nmap <C-\>d :LspDefinition<CR>i
nmap <C-\><S-d> :tab split<CR>:LspDefinition<CR>i
nmap <C-\>s :LspDeclaration<CR>i
nmap <C-\>r :LspReference<CR>i
nmap <C-\><S-R> :LspRename<CR>
nmap <C-\>i :LspHover<CR>i
nmap <C-\>e :LspNextError<CR>i
nmap <C-\>l :LspNextReference<CR><Right>i
nmap <C-\><S-l> :LspPreviousReference<CR><Right>i
nmap <C-\>p :LspPeekDefinition<CR>i
nmap <C-\>P :LspPeekDeclaration<CR>i
nmap <C-\>f :LspWorkspaceSymbol<CR>

" basic, plugins etc
nnoremap / <esc><esc>/
nnoremap <C-o> <esc>
" don't do anything
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

" double escape forces command mode from <C-o> mode
nnoremap gg <esc><esc>mxgg
nnoremap zz :call Save()<CR>
nnoremap hh :noh<CR>
nnoremap tt :TagbarToggle<CR>
nnoremap dt :difft<CR>

" cut/copy/select
inoremap <C-p> <C-x>
inoremap <C-w> <C-o>viw
inoremap <C-c> <esc>^"*y$i
inoremap <C-x> <esc>^"*d$"_ddi
inoremap <C-e> <esc>"_ddi
inoremap <C-d> <esc>"_diwi
" `[ and `] => beg & end of selec, final `] moves cursor to end of paste
inoremap <C-v> <esc>p`[v`]=`]i<right>

"cut/copy append mode(only for lines)
nnoremap <C-a><C-c> "Ayy
nnoremap <C-a><C-v> "Ap<esc>`[v`]=`]i<right>
nnoremap <C-a><C-r> :call setreg('a', "")<CR>

" controlled cursor movement
call MapAll('<C-i>', '<up>', '<up>', '<up>')
call MapAll('<C-k>', '<down>', '<down>', '<down>')
call MapAll('<C-j>', '<left>', '<left>', '<left>')
call MapAll('<C-l>', '<right>', '<right>', '<right>')

" alternate cursor movement
call MapAll('<A-i>', '{', '<C-o>{', '')
call MapAll("\ei", '{', '<C-o>{', '')
call MapAll('<A-k>', '}', '<C-o>}', '')
call MapAll("\ek", '}', '<C-o>}', '')
call MapAll('<A-j>', 'b', '<C-o>b', '<S-left>')
call MapAll("\ej", 'b', '<C-o>b', '<S-left>')
call MapAll('<A-l>', 'w', '<C-o>w', '<S-right>')
call MapAll("\el", 'w', '<C-o>w', '<S-right>')

" controlled alternate cursor movement
call MapAll('<C-A-i>', '5k', '<C-o>5k', '')
call MapAll("\e<C-i>", '5k', '<C-o>5k', '')
call MapAll('<C-A-k>', '5j', '<C-o>5j', '')
call MapAll("\e<C-k>", '5j', '<C-o>5j', '')
call MapAll('<C-A-j>', '3b', '<C-o>3b', '')
call MapAll("\e<C-j>", '3b', '<C-o>3b', '')
call MapAll('<C-A-l>', '3w', '<C-o>3w', '')
call MapAll("\e<C-l>", '3w', '<C-o>3w', '')

" extra shift cursor binding
call MapAll('<A-S-j>', '^', '<C-o>^', '')
call MapAll("\eJ", '^', '<C-o>^', '')
call MapAll('<A-S-l>', '$', '<C-o>$', '<Home>')
call MapAll("\eL", '$', '<C-o>$', '<Home>')
call MapAll('<A-S-k>', 'YP', '<C-o>Y<C-o>p', '<End>')
call MapAll("\eK", 'YP', '<C-o>Y<C-o>p', '<End>')

" tab
call MapAll('<A-,>', ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll("\e,", ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call MapAll('<A-.>', ':tabnext<CR>', '<C-o>:tabnext<CR>', '')
call MapAll("\e.", ':tabnext<CR>', '<C-o>:tabnext<CR>', '')

" split
nnoremap <C-w><C-j> <C-w>h
nnoremap <C-w><C-l> <C-w>l
nnoremap <C-w><C-k> <C-w>j
nnoremap <C-w><C-i> <C-w>k
nnoremap <C-w>J <C-w>H
nnoremap <C-w>L <C-w>L
nnoremap <C-w>I <C-w>K
nnoremap <C-w>K <C-w>J

" The tab mess, arrrgghhh!
"<C-i> = <Tab>, no rainbow without a little rain
"<C-@> means <C-space>
inoremap <C-@> <tab>
" For tab completion in command mode
" Need to set this to make the mapping work
set wildcharm=<tab>
cnoremap <C-@> <tab>

" set
" ===
abbr mian main
abbr itn int
abbr tin int
abbr fucntion function
abbr progrma program

set ttimeoutlen=50
set textwidth=80
set scrolloff=5
set backspace=2
set t_Co=256
set tabstop=2
set shiftwidth=2
set laststatus=2
set expandtab
set pastetoggle=<F2>
set completeopt=noselect,menuone,preview
set autoread
set diffopt+=vertical
set clipboard=unnamed
set mouse=a
set notitle
set nowrap
set number
set hlsearch
set incsearch
set ruler
set smartindent
set smarttab
set splitright
set ignorecase
set smartcase
set noshowmode
set rtp+=~/.fzf
set termguicolors " for highlight guixx in xterm
set background=dark

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

" The following is done by vim-plug, uncomment if using another
" plugin-manager that doesn't do so.
" syntax on
" filetype plugin indent on
call CsUpd()


" autocmds
" ========
autocmd vimenter * call CsUpd() | call setreg('a', "")
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

inoremap <F6> <C-o>:wa <bar> call QCompRun('')<CR>
inoremap <F7> <C-o>:wa <bar> call QCompRun('gdb')<CR>
inoremap <F8> <C-o>:wa <bar> call QCompRun('valgrind')<CR>
au filetype c,cpp nnoremap <Leader>h :call CPair()<CR>
  \| inoremap <C-n> #include <><Left>
  \| set softtabstop=2

au filetype plaintex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdftex -interaction nonstopmode '.shellescape('%') <CR>
au filetype tex inoremap <F6> <C-o>:wa <bar> exec
  \'!pdflatex -interaction nonstopmode '.shellescape('%') <CR>
au filetype plaintex,tex let b:delimitMate_quotes = "\" ' $"

au filetype sh inoremap <F6> <C-o>:wa <bar> exec
  \'!./'.shellescape('%')<CR>
au filetype perl inoremap <F6> <C-o>:wa <bar>
  \exec '!perl '.shellescape('%')<CR>
au filetype python inoremap <F6> <C-o>:wa <bar>
  \exec '!python '.shellescape('%')<CR>
au filetype ruby inoremap <F6> <C-o>:wa <bar>
  \exec '!ruby '.shellescape('%')<CR>
au filetype php inoremap <F6> <C-o>:wa <bar>
  \exec '!php '.shellescape('%')<CR>

if executable('clangd')
  augroup lsp_clangd
    au!
    au User lsp_setup call lsp#register_server({
      \ 'name': 'clangd',
      \ 'cmd': {server_info->['clangd']},
      \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
      \ })
    au FileType c setlocal omnifunc=lsp#complete
    au FileType cpp setlocal omnifunc=lsp#complete
    au FileType objc setlocal omnifunc=lsp#complete
    au FileType objcpp setlocal omnifunc=lsp#complete
  augroup end
endif

au BufRead,BufNewFile *.ll set filetype=llvm
au BufRead,BufNewFile *.mlir set filetype=mlir
au BufRead,BufNewFile lit.*cfg set filetype=python
au BufRead,BufNewFile *.td set filetype=tablegen
au BufRead,BufNewFile *.cpp.inc set filetype=cpp
au BufRead,BufNewFile *.h.inc set filetype=cpp

au FileType llvm setlocal commentstring=;\ %s
au FileType mlir setlocal commentstring=//\ %s
au FileType cpp setlocal commentstring=//\ %s
" see https://stackoverflow.com/questions/27403413/vims-tab-length-is-different-for-py-files
" aug python
    " ftype/python.vim overwrites this
    " au FileType python setlocal ts=2 sts=2 sw=2
" aug end

if filereadable($HOME . "/vimrc.after")
  source $HOME/vimrc.after
endif
