" variables
" ---------
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
let g:syntastic_ignore_files = ["tex"]
let g:syntastic_c_compiler_options = '-Wparentheses'

let g:tagbar_left = 1

let fortran_free_source = 1
let fortran_have_tabs = 1
let fortran_more_precise = 1
let fortran_do_enddo = 1

" for functions in this file
let s:trailing_space_flag = 0
let s:tags_file = ".vim_tags"
let g:qrun_cflags = "-lpthread -lm"

execute pathogen#infect()

if filereadable($HOME . "/vimrc.before")
    source $HOME/vimrc.before
endif

" functions
" ---------
function! Chomp(string)
	return substitute(a:string, '\n\+$', '', '')
endfunction

function! Cleanme()
    silent! exec '%s/\v\ +$//g'
    silent! exec '%s/\v[^\x00-\x7F]+//g'
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

function! Qrun_c(cmdline)
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

		exec '!' . l:compiler . g:qrun_cflags . ' -g ' . shellescape('%') . ';' .
			\a:cmdline . " ./a.out"
	endif
endfunction

function! C_pair()
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

function! Cs_inv()
	if g:colors_name == "wh"
		colo bl
	else
		colo wh
	endif
endfunction

function! Cs_upd()
	for l:line in readfile("/home/abinav/.t_col", '', 2)
		if line =~ 'wh'
			colo wh
		else
			colo bl
		endif
	endfor
endfunction

function! Nt_toggle()
	if ! g:NERDTree.IsOpen()
		NERDTreeCWD
	else
		NERDTreeClose
	endif
endfunction

" updates ctags for this buffer only
function! Tags_buf_upd()
	let l:buf = bufname("%")
	let l:bufd = ".vim_" . l:buf . ".d"
	let l:tagl = ".vim_taglist"

	" writes user def header files to l:bufd
	call system("gcc -E -MM -o " . l:bufd . " " .
				\l:buf)

	" parses l:bufd for ctags -L
	call system("awk '{for (i=2; i<=NF; i++) print $i}' " .
				\l:bufd . " > " . l:tagl)

	" to add protoypes +p, (see ctags --list-kinds=c)
	call system("ctags --c-kinds=+p --fields=+S -f " . s:tags_file .
				\" -L " . l:tagl)

	call system("rm " . l:bufd)
	call system("rm " . l:tagl)
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

command! Cl :call Cleanme()

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
cnoremap cds call Cds()

" follow the leader
nnoremap <Leader>f :set filetype
nnoremap <Leader>l :set list!<CR>
nnoremap <Leader>s :set spell!<CR>
nnoremap <Leader>w :set wrap!<CR>
nnoremap <Leader>t :call Trailing_space_match()<CR>
nnoremap <Leader>n :call Nt_toggle()<CR>
nnoremap <Leader>m :SyntasticToggleMode<CR>
nnoremap <Leader>r :SyntasticReset<CR><Esc> pc!<CR>i<Right>
nnoremap <Leader>p :FZF
nnoremap <Leader>b :call CopyAsBreakpoint()<cr>
nnoremap <Leader>c :call Cs_inv()<CR>
nnoremap <Leader>v :so $MYVIMRC<CR>
nnoremap <Leader>x :set textwidth=

" To understand the alt keybinding headache in vim, see:
" https://groups.google.com/forum/#!topic/vim_dev/zmRiqhFfOu8
" https://stackoverflow.com/questions/6778961/alt-key-shortcuts-not-working-on-gnome-terminal-with-vim
"
" Stick to xterm! Moolenaar does I guess. Nevertheless, try to minimize dependency on
" alt key-bindings


" basic, plugins etc
inoremap <C-z> <C-o>u
inoremap <C-r> <C-o><C-r>
" don't do anything
nnoremap <C-o> <esc>
" sometimes C-] is not enough (TODO why?)
nnoremap <C-]> g<C-]>
vnoremap <C-]> g<C-]>
nnoremap <A-]> <C-w><C-]><C-w>T
" exec "nnoremap \e] <C-w><C-]><C-w>T"
vnoremap <A-]> <Esc>:tab tjump <C-r><C-w><CR>
exec "vnoremap \e] <Esc>:tab tjump <C-r><C-w><CR>"
" double escape forces command mode from <C-o> mode
nnoremap gg <esc><esc>mxgg
nnoremap / <esc><esc>/
nnoremap <C-p> :FZF<CR>
imap <C-_> <esc>gcci

nnoremap zz :call Save()<CR>
nnoremap hh :noh<CR>
nnoremap tt :TagbarToggle<CR>

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
call Map_all('<C-i>', '<up>', '<up>', '<up>')
call Map_all('<C-k>', '<down>', '<down>', '<down>')
call Map_all('<C-j>', '<left>', '<left>', '<left>')
call Map_all('<C-l>', '<right>', '<right>', '<right>')

" alternate cursor movement
call Map_all('<A-i>', '{', '<C-o>{', '')
call Map_all("\ei", '{', '<C-o>{', '')
call Map_all('<A-k>', '}', '<C-o>}', '')
call Map_all("\ek", '}', '<C-o>}', '')
call Map_all('<A-j>', 'b', '<C-o>b', '<S-left>')
call Map_all("\ej", 'b', '<C-o>b', '<S-left>')
call Map_all('<A-l>', 'w', '<C-o>w', '<S-right>')
call Map_all("\el", 'w', '<C-o>w', '<S-right>')

" controlled alternate cursor movement
call Map_all('<C-A-i>', '5k', '<C-o>5k', '')
call Map_all("\e<C-i>", '5k', '<C-o>5k', '')
call Map_all('<C-A-k>', '5j', '<C-o>5j', '')
call Map_all("\e<C-k>", '5j', '<C-o>5j', '')
call Map_all('<C-A-j>', '3b', '<C-o>3b', '')
call Map_all("\e<C-j>", '3b', '<C-o>3b', '')
call Map_all('<C-A-l>', '3w', '<C-o>3w', '')
call Map_all("\e<C-l>", '3w', '<C-o>3w', '')

" extra shift cursor binding
call Map_all('<A-S-j>', '^', '<C-o>^', '')
call Map_all("\eJ", '^', '<C-o>^', '')
call Map_all('<A-S-l>', '$', '<C-o>$', '<Home>')
call Map_all("\eL", '$', '<C-o>$', '<Home>')
call Map_all('<A-S-k>', 'YP', '<C-o>Y<C-o>p', '<End>')
call Map_all("\eK", 'YP', '<C-o>Y<C-o>p', '<End>')

" tab
call Map_all('<A-,>', ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call Map_all("\e,", ':tabprevious<CR>', '<C-o>:tabprevious<CR>', '')
call Map_all('<A-.>', ':tabnext<CR>', '<C-o>:tabnext<CR>', '')
call Map_all("\e.", ':tabnext<CR>', '<C-o>:tabnext<CR>', '')

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
set textwidth=80
set scrolloff=5
set backspace=2
set t_Co=256
set tabstop=2
set shiftwidth=2
set laststatus=2
set expandtab
set previewheight=1
set pastetoggle=<F2>
set completeopt-=preview

exe "set tags+=" . s:tags_file
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
set autoread
set rtp+=~/.fzf

set statusline =
set statusline +=\ %{mode()}		"mode
set statusline +=\ %{&ff}           "file format
set statusline +=%y               	"file type
set statusline +=[%{strlen(&fenc)?&fenc:'none'}] "file encoding
set statusline +=\ %<%F            	"full path, '<' truncates the path
set statusline +=%m              	"modified flag
set statusline +=\ %r               "readonly flag
silent! set statusline +=\ %{fugitive#statusline()}	"current git branch

set statusline +=%=0x%B           	"character under cursor
set statusline +=\ %l              	"current line
set statusline +=/%L            	"total lines
set statusline +=\ %v             	"virtual column number
set statusline +=\ %P				"percentage
silent! set statusline +=%{SyntasticStatuslineFlag()}



" run
" ---
abbr mian main
abbr itn int
abbr tin int
abbr fucntion function

syntax on
call Cs_upd()
filetype plugin indent on

" autocmds
" --------
let g:src_root = system('realpath `srcerer`')
let g:llvm_dev = system('realpath $LLVM_DEV/llvm')

if g:src_root == g:llvm_dev
	command! Mbb tabnew include/llvm/CodeGen/MachineBasicBlock.h
	command! Mf tabnew include/llvm/CodeGen/MachineFunction.h
	command! Mi tabnew include/llvm/CodeGen/MachineInstr.h
	command! Mo tabnew include/llvm/CodeGen/MachineOperand.h
	command! Mri tabnew include/llvm/CodeGen/MachineRegisterInfo.h

	command! Tri tabnew include/llvm/CodeGen/TargetRegisterInfo.h
	command! Trc tabnew include/llvm/CodeGen/TargetRegisterInfo.h

	command! Mcri tabnew include/llvm/MC/MCRegisterInfo.h
	command! Mcrc tabnew include/llvm/MC/MCRegisterInfo.h

	command! Rab tabnew lib/CodeGen/RegAllocBase.h
	command! Rag tabnew lib/CodeGen/RegAllocGreedy.cpp
	command! Lrm tabnew include/llvm/CodeGen/LiveRegMatrix.h
	command! Vrm tabnew include/llvm/CodeGen/VirtRegMap.h
endif

autocmd vimenter * call Cs_upd() | call setreg('a', "")
			\| highlight trailing_space ctermbg=red guibg=red
autocmd vimleave * call system("rm " . s:tags_file)
autocmd insertenter * exe 'hi! StatusLine ctermbg=047'
autocmd insertleave * exe 'hi! StatusLine ctermbg=220'
autocmd TabEnter * NERDTreeClose
autocmd TabLeave * if g:NERDTree.IsOpen() | wincmd p

autocmd filetype c,cpp,fortran inoremap <F4> <C-o>:call Tags_buf_upd()<CR>
			\| inoremap <F6> <C-o>:wa <bar> call Qrun_c('')<CR>
			\| inoremap <F7> <C-o>:wa <bar> call Qrun_c('gdb')<CR>
			\| inoremap <F8> <C-o>:wa <bar> call Qrun_c('valgrind')<CR>
			\| nnoremap qf :let g:qrun_cflags .= ''<Left>
            \| nnoremap <Leader>h :call C_pair()<CR>
			\| inoremap <C-n> #include <><Left>
			\| set softtabstop=2 | set shiftwidth=2

autocmd filetype plaintex inoremap <F6> <C-o>:wa <bar> exec
			\'!pdftex -interaction nonstopmode '.shellescape('%') <CR>
autocmd filetype tex inoremap <F6> <C-o>:wa <bar> exec
			\'!pdflatex -interaction nonstopmode '.shellescape('%') <CR>
autocmd filetype plaintex,tex let b:delimitMate_quotes = "\" ' $"

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

au BufRead,BufNewFile *.ll set filetype=llvm
au BufRead,BufNewFile lit.*cfg set filetype=python
au BufRead,BufNewFile *.td set filetype=tablegen
" see https://stackoverflow.com/questions/27403413/vims-tab-length-is-different-for-py-files
" aug python
    " ftype/python.vim overwrites this
    " au FileType python setlocal ts=2 sts=2 sw=2
" aug end

if filereadable($HOME . "/vimrc.after")
    source $HOME/vimrc.after
endif
