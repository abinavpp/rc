" variables
" ---------
let mapleader=" "

let sys = substitute(system('uname -r'), '\n\+$', '', '')

let s:trailing_space_flag = 0



" functions
" ---------
function! Chomp(string)
	return substitute(a:string, '\n\+$', '', '')
endfunction

function! Trailing_space_match()
	if s:trailing_space_flag == 0
		let s:trailing_space_flag = 1
		match trailing_space /\s\+\%#\@<!$/
	else
		let s:trailing_space_flag = 0
		match none
	endif
endfunction

function! Map_all(keys, nrhs, irhs, crhs)
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
 
nnoremap <Leader>b :call CopyAsBreakpoint()<cr>



" mappings
" --------
" visual
vmap <C-_> gc
vnoremap <C-x> d
vnoremap <C-c> y
vnoremap d "_d
vnoremap / y/<C-R>"<CR>

" command line alias
cnoremap hl vert help
cnoremap cdb lcd %:p:h

" follow the leader
nnoremap <Leader>f :set filetype
nnoremap <Leader>l :set list!<CR>
nnoremap <Leader>s :set spell!<CR>
nnoremap <Leader>w :set wrap!<CR>
nnoremap <Leader>t :call Trailing_space_match()<CR>
nnoremap <Leader>r :so $MYVIMRC<CR>

" basic, etc
call Map_all('<A-z>', '<C-z>', '<C-o><C-z>', '<C-z>')
call Map_all('<C-z>', 'u', '<C-o>u', '')
inoremap <C-r> <C-o><C-r>
" don't do anything
nnoremap <C-o> <esc>
nnoremap <C-]> g<C-]>
vnoremap <C-]> g<C-]>
nnoremap <A-]> <C-w>g<C-]><C-w>T
vnoremap <A-]> <C-w>g<C-]><C-w>T
" double escape forces command mode from <C-o> mode
nnoremap gg <esc><esc>mxggi
inoremap <F5> <C-o>:call Save()<CR>
nnoremap <C-h> :noh<CR>
" nnoremap <C-y> <S-k><CR>
nnoremap / <esc><esc>/
nnoremap t <C-t>

"cut copy select
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
call Map_all('<C-i>', '<up>', '<up>', '<up>')
call Map_all('<C-k>', '<down>', '<down>', '<down>')
call Map_all('<C-j>', '<left>', '<left>', '<left>')
call Map_all('<C-l>', '<right>', '<right>', '<right>')

" alternate cursor movement
call Map_all('<A-i>', '{', '<C-o>{', '')
call Map_all('<A-k>', '}', '<C-o>}', '')
call Map_all('<A-j>', 'b', '<C-o>b', '<S-left>')
call Map_all('<A-l>', 'w', '<C-o>w', '<S-right>')

" controlled alternate cursor movement
call Map_all('<C-A-i>', '5k', '<C-o>5k', '')
call Map_all('<C-A-k>', '5j', '<C-o>5j', '')
call Map_all('<C-A-j>', '3b', '<C-o>3b', '')
call Map_all('<C-A-l>', '3w', '<C-o>3w', '')

" extra shift cursor binding 
call Map_all('<A-S-j>', '^', '<C-o>^', '')
call Map_all('<A-S-l>', '$', '<C-o>$', '<Home>')
call Map_all('<A-S-k>', 'YP', '<C-o>Y<C-o>p', '<End>')

" tab
call Map_all('<A-,>', ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call Map_all('<A-.>', ':tabnext<CR>', '<C-o>:tabnext<CR>', '')

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
" ---
set ttimeoutlen=50
set textwidth=75
set scrolloff=5
set backspace=2
set t_Co=256
set tabstop=4
set laststatus=2
set shiftwidth=4
set previewheight=1
set pastetoggle=<F2>

set clipboard=unnamed
set mouse=a
set completeopt+=menuone

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
" set showmatch
set autoread

set statusline =
set statusline +=\ %{mode()}		"mode
set statusline +=\ %{&ff}           "file format
set statusline +=%y               	"file type
set statusline +=[%{strlen(&fenc)?&fenc:'none'}] "file encoding
set statusline +=\ %<%F            	"full path, '<' truncates the path
set statusline +=%m              	"modified flag
set statusline +=\ %r               "readonly flag

set statusline +=%=0x%B           	"character under cursor
set statusline +=\ %l              	"current line
set statusline +=/%L            	"total lines
set statusline +=\ %v             	"virtual column number
set statusline +=\ %P				"percentage



" run
" ---
abbr mian main
abbr itn int
abbr tin int
abbr fucntion function

syntax on
filetype plugin indent on


" autocmds
" --------
autocmd insertenter * exe 'hi! StatusLine ctermbg=047'
autocmd insertleave * exe 'hi! StatusLine ctermbg=220'

autocmd filetype plaintex inoremap <F6> <C-o>:wa <bar> exec
			\'!pdftex -interaction nonstopmode '.shellescape('%') <CR>
autocmd filetype plaintex let b:delimitMate_quotes = "\" ' $"
autocmd filetype tex inoremap <F6> <C-o>:wa <bar> exec
			\'!pdflatex -interaction nonstopmode '.shellescape('%') <CR>
autocmd filetype tex let b:delimitMate_quotes = "\" ' $"
autocmd filetype tex set expandtab " for verbatim env


autocmd filetype html,css,php,javascript set shiftwidth=2
autocmd filetype sh inoremap <F6> <C-o>:wa <bar> exec 
			\'!./'.shellescape('%')<CR>
autocmd filetype perl inoremap <F6> <C-o>:wa <bar> 
			\exec '!perl '.shellescape('%')<CR>
autocmd filetype python inoremap <F6> <C-o>:wa <bar> 
			\exec '!python '.shellescape('%')<CR>
autocmd filetype ruby inoremap <F6> <C-o>:wa <bar> 
			\exec '!ruby '.shellescape('%')<CR>
autocmd filetype php inoremap <F6> <C-o>:wa <bar> 
			\exec '!php '.shellescape('%')<CR>
autocmd filetype cpp inoremap <F6> <C-o>:wa <bar> 
			\exec '!g++ ' . shellescape('%') . '&& time ./a.out'<CR>
			\| set softtabstop=2 | set shiftwidth=2 | set expandtab
autocmd filetype c,cpp inoremap <C-n> #include <><Left>
