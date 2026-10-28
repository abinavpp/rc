" Environment variables
" =====================
let $FZF_DEFAULT_COMMAND =
  \ 'fd --hidden -L --exclude ".cache/" --exclude ".git/"'

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
let g:color_theme = "dark"
let g:gdiff_depth = 0
let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 1.0 } }
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
  let l:s = l:c . " %{mode()} %<%F  %{get(w:, 'lsp_func', '')} %m %r"
  let l:s .= "%= %{v:servername} %y %v %l/%L"
  return l:s
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
  au TextChanged,InsertLeave <buffer> silent! call LspFunc()
  au CursorHold,CursorHoldI <buffer> call LspFuncUpdate(0)
  nnoremap <buffer><Leader>ld :LspDefinition<CR>
  nnoremap <buffer><Leader>ls :LspDeclaration<CR>
  nnoremap <buffer><Leader>lr :LspReference<CR>
  nnoremap <buffer><Leader>lR :LspRename<CR>
  nnoremap <buffer><Leader>li :LspHover<CR>
  nnoremap <buffer><Leader>le :LspNextError<CR>
  nnoremap <buffer><Leader>lE :LspNextDiagnostic<CR>
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

" The symbols in syms enclosing pos, as Class::method. vim-lsp turns off
" hierarchical symbols, so enclosing scopes arrive as siblings.
function! LspFuncFind(pos, syms)
  let l:hits = []
  for l:s in a:syms
    let l:r = has_key(l:s, 'range') ? l:s.range : l:s.location.range
    if a:pos.line < l:r.start.line || a:pos.line > l:r.end.line
      continue
    endif
    call add(l:hits, [l:r.end.line - l:r.start.line, l:s])
  endfor

  if empty(l:hits)
    return ''
  endif
  call sort(l:hits, {a, b -> b[0] - a[0]})
  let l:names = map(copy(l:hits), 'v:val[1].name')
  call add(l:names, LspFuncFind(a:pos, get(l:hits[-1][1], 'children', [])))
  return join(filter(l:names, 'v:val !~# "^$\\|^(anonymous namespace)$"'), '::')
endfunction

" Cache buf's symbols from a documentSymbol reply and refresh the statusline.
function! LspFuncStore(buf, data)
  let l:res = get(get(a:data, 'response', {}), 'result', v:null)
  if type(l:res) != v:t_list
    return
  endif

  call setbufvar(a:buf, 'lsp_syms', l:res)
  if bufnr() == a:buf
    call LspFuncUpdate(0)
  endif
endfunction

" Show the symbols enclosing the cursor in the statusline, or in a popup.
function! LspFuncUpdate(popup)
  let w:lsp_func = LspFuncFind(lsp#get_position(), get(b:, 'lsp_syms', []))
  redrawstatus
  if a:popup && !empty(w:lsp_func)
    call popup_atcursor(w:lsp_func,
      \ {'moved': 'any', 'border': [], 'padding': [0, 1, 0, 1]})
  endif
endfunction

" Request the buffer's symbols from its language server.
function! LspFunc()
  let l:servers = filter(lsp#get_allowed_servers(),
    \ 'lsp#capabilities#has_document_symbol_provider(v:val)')
  if empty(l:servers)
    echohl ErrorMsg | echo 'No document symbol provider' | echohl None
    return
  endif

  call lsp#send_request(l:servers[0], {
    \ 'method': 'textDocument/documentSymbol',
    \ 'params': {'textDocument': lsp#get_text_document_identifier()},
    \ 'on_notification': function('LspFuncStore', [bufnr()]),
    \ })
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

" Toggle a diff pane against rev a; another rev replaces the open one. The
" cursor stays put.
function! Gdiff(a)
  " Unresolvable rev: fugitive opens it as a literal path instead of failing.
  if FugitiveExecute(['rev-parse', '--verify', '--quiet', a:a]).exit_status
    echohl ErrorMsg | echo 'No such rev: ' . a:a | echohl None
    return
  endif

  " Not &diff: a reloaded buffer can keep the flag without a diff pane.
  if exists('t:gdiff_spec')
    for l:w in reverse(range(1, winnr('$')))
      if bufname(winbufnr(l:w)) =~# '^fugitive://'
        exe l:w . 'wincmd c'
      endif
    endfor
    diffoff!
    let l:cur = t:gdiff_spec
    unlet t:gdiff_spec
    if l:cur ==# a:a
      return
    endif
  endif

  let l:win = win_getid()
  exe 'Gdiffsplit ' . a:a
  call win_gotoid(l:win)

  let t:gdiff_spec = a:a
endfunction

" Set the depth <Leader>e diffs against: 0 for HEAD, N for HEAD~N.
function! GdiffNum()
  let l:n = nr2char(getchar())
  if l:n !~ '[0-9]'
    return
  endif

  let g:gdiff_depth = str2nr(l:n)
  echo 'Diff depth: ' . l:n
endfunction

" Diff against the nearest ancestor that is a local branch tip, within 10
" commits; past that, against where the branch leaves main.
function! GdiffBranchPoint()
  let l:tips = FugitiveExecute(['for-each-ref', '--format=%(objectname)',
    \ 'refs/heads']).stdout
  for l:sha in FugitiveExecute(['rev-list', '--first-parent', '--skip=1',
    \ '--max-count=10', 'HEAD']).stdout
    if index(l:tips, l:sha) >= 0
      call Gdiff(l:sha)
      return
    endif
  endfor
  call Gdiff(FugitiveExecute(['merge-base', 'HEAD', 'main']).stdout[0])
  echo 'No branch point within 10 commits, falling back to comparing with main'
endfunction

" Keep one inotifywait job on the dirs of the listed buffers. Dirs, not files:
" a write by rename leaves a file watch on a dead inode.
function! ReloadWatch()
  let l:d = {}
  for l:b in getbufinfo({'buflisted': 1})
    if l:b.name !=# '' && filereadable(l:b.name)
      let l:d[fnamemodify(l:b.name, ':p:h')] = 1
    endif
  endfor
  let l:dirs = sort(keys(l:d))
  let l:live = exists('g:reload_job') && job_status(g:reload_job) ==# 'run'
  if l:live && l:dirs == get(g:, 'reload_dirs', [])
    return
  endif
  if exists('g:reload_job')
    call job_stop(g:reload_job)
    unlet g:reload_job
  endif
  let g:reload_dirs = l:dirs
  if empty(l:dirs) || !has('job') || !executable('inotifywait')
    return
  endif
  let g:reload_job = job_start(['inotifywait', '-qm', '-e', 'close_write,moved_to',
    \ '--format', '%w%f'] + l:dirs,
    \ {'out_cb': {-> mode() =~# '^[icR]' ? 0 : execute('silent! checktime')}})
endfunction

" Jump from a +/- line of a review diff to that line of its file, pushed on the
" tag stack like LspDefinition.
function! ReviewJump()
  let l:line = getline('.')
  if l:line !~# '^[+-]' || l:line =~# '^\%(+++\|---\) ' | return | endif
  let l:target = fugitive#Cfile()
  call lsp#utils#tagstack#_update()
  silent exe 'edit ' . l:target
endfunction

" Commands
" ========
com! Tidy :sil! exe '%s/\v\ +$//g' <bar> :sil! exe '%s/\v[^\x00-\x7F]+//g'
com! Fif :set foldmarker=#if,#endif foldmethod=marker
com! Cdb :lcd %:p:h
com! Gbl :Git blame
com! -range Glg exe (<range> ? <line1> . ',' . <line2> : 0) . 'Gllog!'
com! Gr :Gedit
com! Csi :call CSInv()
com! Sv :so $MYVIMRC
com! Cl :%bd|e#|bd#

" Mappings
" ========
" FIXME: :q causes E173 if > 1 file in cmdline.
cabbrev q qa
call Map('<Leader>d', '"_d') | call Map('<Leader>D', '"_D')
call Map('x', '"_x') | call Map('X', '"_X')
call Map('c', '"_c') | call Map('C', '"_C')
" FIXME: vnoremap affects visual block. This breaks the 'I' to prepend in visual
" block
call Map('I', '^') | call Map('A', '$')
nnoremap <Leader>z :call Save()<CR>
nnoremap U <C-r>
nnoremap <Leader>vs `[v`]
nnoremap <Leader>h :call ToggleSet('hls')<CR>
nnoremap <silent><expr> n (v:searchforward ? 'n' : 'N') . ":SearchIndex<CR>"
nnoremap <silent><expr> N (v:searchforward ? 'N' : 'n') . ":SearchIndex<CR>"
nnoremap <Leader>b :call CopyToClipboard(expand('%:p:h:t') . '/'
  \ . expand('%:t') . ':' . line('.'))<CR>
nnoremap <Leader>n :call CopyToClipboard(expand('%:p'))<CR>
nnoremap <Leader>w <C-w>
nnoremap <Leader>a :Files<CR>
nnoremap <Leader>f :Buffers<CR>
nnoremap <Leader>x :bd<CR>
nnoremap <Leader>k ma
nnoremap <Leader>K `a
nnoremap <silent><Leader>e
  \ :call Gdiff(g:gdiff_depth ? '@~' . g:gdiff_depth : '@')<CR>
nnoremap <silent><Leader>r :call GdiffBranchPoint()<CR>
nnoremap <silent><Leader>t :call GdiffNum()<CR>
nnoremap <silent><Leader>q :lopen<CR>
nnoremap <Leader>ld :exe 'tag' expand('<cword>')<CR>
nnoremap <Leader>le :SyntasticCheck<CR>
nnoremap <Leader>lc :call LspFuncUpdate(1)<CR>
nnoremap <Leader>lb <C-t>
nnoremap <Leader>sf :set filetype
nnoremap <Leader>sl :call ToggleSet('list')<CR>
nnoremap <Leader>ss :call ToggleSet('spell')<CR>
nnoremap <Leader>sw :call ToggleSet('wrap')<CR>
nnoremap <Leader>si :call ToggleSet('smartindent')<CR>
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
set modelines=1 updatetime=300
set clipboard^=unnamed,unnamedplus mouse=a termguicolors background=dark
au FileType llvm setlocal commentstring=;\ %s | set textwidth=0
au FileType mlir setlocal commentstring=//\ %s
au FileType diff nnoremap <buffer><silent> <Leader>ld :call ReviewJump()<CR>
au FileType diff nnoremap <buffer><silent> [q :call search('^###', 'w')<CR>
au FileType diff nnoremap <buffer><silent> ]q :call search('^###', 'bw')<CR>
au FileType mlir,tablegen setlocal matchpairs+=<:>
au FileType cpp,tablegen setlocal commentstring=//\ %s | set comments^=:///
set laststatus=2 statusline=%!StatusLine()
filetype plugin indent on
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
au User lsp_buffer_enabled silent! call LspFunc()
" Force vim-lsp to resync the buffer on :e (workaround for stale didOpen).
au BufReadPre * if &buftype ==# '' && expand('<afile>') !~# '^fugitive://'
  \ | silent! doautocmd <nomodeline> BufDelete | endif
au FocusGained,BufEnter,InsertLeave,CmdlineLeave * silent! checktime
au BufReadPost,BufNewFile * call ReloadWatch()
syntax on
colo CandyPaper2

" LSP
" ===
call Lsp(['clangd'], ['c', 'cpp', 'objc', 'objcpp', 'cuda'])
call Lsp(['rust-analyzer'], ['rust'])
call Lsp(['mlir-lsp-server'], ['mlir'])
call Lsp(['pylsp'], ['python'])
call Lsp(['esbonio'], ['rst']) " FIXME: This doesn't work!
call Lsp(['marksman'], ['markdown'])
call Lsp(['typescript-language-server', '--stdio'], ['javascript',
  \ 'typescript'])

" .post-vimrc
" ===========
if filereadable($HOME . "/.post-vimrc")
  source $HOME/.post-vimrc
endif
