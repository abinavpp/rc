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
  let l:s = l:c . " %{mode()} %<%F  %{exists('g:loaded_tagbar') ?"
  let l:s .= "tagbar#currenttag('%s', '', '%f') : ''} %m %r"
  let l:s .= "%= %{v:servername} %y %v %l/%L"
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

" Names of the symbols in syms enclosing pos, outermost first.
function! LspFuncFind(pos, syms)
  let l:best = {}
  let l:span = 0
  for l:s in a:syms
    let l:r = has_key(l:s, 'range') ? l:s.range : l:s.location.range
    if a:pos.line < l:r.start.line || a:pos.line > l:r.end.line
      continue
    endif
    if empty(l:best) || l:r.end.line - l:r.start.line < l:span
      let l:best = l:s
      let l:span = l:r.end.line - l:r.start.line
    endif
  endfor

  if empty(l:best)
    return []
  endif
  return [l:best.name] + LspFuncFind(a:pos, get(l:best, 'children', []))
endfunction

" Popup the symbol chain enclosing pos from a documentSymbol response.
function! LspFuncShow(pos, data)
  let l:res = get(get(a:data, 'response', {}), 'result', v:null)
  if type(l:res) != v:t_list
    return
  endif

  let l:chain = LspFuncFind(a:pos, l:res)
  if empty(l:chain)
    return
  endif
  call popup_atcursor(join(l:chain, ' > '),
    \ {'moved': 'any', 'border': [], 'padding': [0, 1, 0, 1]})
endfunction

" Show the function under the cursor as a symbol chain, e.g. Class > method.
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
    \ 'on_notification': function('LspFuncShow', [lsp#get_position()]),
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

function! GdiffClose()
  for l:w in reverse(range(1, winnr('$')))
    if bufname(winbufnr(l:w)) =~# '^fugitive://'
      exe l:w . 'wincmd c'
    endif
  endfor
  diffoff!

  if exists('t:gdiff_spec')
    unlet t:gdiff_spec
  endif
endfunction

" Toggle a diff pane against rev a ('' = index); another rev replaces the open
" one. The cursor stays put.
function! Gdiff(a)
  " Unresolvable rev: fugitive opens it as a literal path instead of failing.
  if a:a != "" && FugitiveExecute(['rev-parse', '--verify', '--quiet', a:a]).exit_status
    echohl ErrorMsg | echo 'No such rev: ' . a:a | echohl None
    return
  endif

  " Not &diff: a reloaded buffer can keep the flag without a diff pane.
  if exists('t:gdiff_spec')
    let l:cur = t:gdiff_spec
    call GdiffClose()
    if l:cur ==# a:a
      return
    endif
  endif

  let l:win = win_getid()
  exe 'Gdiffsplit ' . a:a
  if a:a == ""
    wincmd r
  endif
  call win_gotoid(l:win)

  let t:gdiff_spec = a:a
endfunction

" Go to the next (step 1) or previous (step -1) entry, wrapping at the ends.
" If a diff is open, it follows to the new file.
function! ReviewGo(step)
  " Closing the diff returns the cursor to the window that owns the list.
  if exists('t:gdiff_spec')
    let l:spec = t:gdiff_spec
    call GdiffClose()
  endif

  let l:len = len(getloclist(0))
  if l:len
    let l:idx = getloclist(0, {'idx': 0}).idx
    exe 'll ' . ((l:idx - 1 + a:step + l:len) % l:len + 1)
  endif

  if exists('l:spec')
    call Gdiff(l:spec)
  endif
  call ReviewEcho()
endfunction

" Re-echo the current entry's "(n of N): text" line after a redraw wiped it.
function! ReviewEcho()
  let l:items = getloclist(0)
  if empty(l:items) | return | endif

  redraw
  let l:cur = getloclist(0, {'idx': 0}).idx
  echo printf('(%d of %d): %s', l:cur, len(l:items), l:items[l:cur - 1].text)
endfunction

function! GdiffNum()
  let l:n = nr2char(getchar())
  if l:n !~ '[1-9]'
    return
  endif

  call Gdiff('@~' . l:n)
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

function! FileCheck(range, line1, line2)
  let l:comment_prefix = split(&commentstring, '%s')[0]
  let l:cmd = 's/^/' . escape(comment_prefix, '/') . 'CHECK-NEXT: /g'

  " TODO: Verify (Copied from the Glog function).
  if a:range == 0
    execute '0' . l:cmd . '!'
  elseif a:range == 1
    execute a:line1 . l:cmd
  else
    execute a:line1 . ',' . a:line2 . l:cmd
  endif
endfunction

" A FileChangedShell autocmd suppresses the 'autoread' reload, so ask for it
" back explicitly. 'conflict' means the buffer is dirty too: mine wins.
function! DiskChanged()
  if v:fcs_reason ==# 'changed'
    let v:fcs_choice = 'reload'
    return
  endif
  let v:fcs_choice = ''
  if v:fcs_reason ==# 'conflict'
    echohl WarningMsg
    echomsg 'disk changed, buffer dirty, kept mine: ' . expand('<afile>')
    echohl None
  endif
endfunction

" Watch the dirs, not the files: inotify keys on the inode, so a
" temp-file-plus-rename writer leaves a file watch on a dead inode. Respawn
" when the dir set changes or the watcher died - a dead watcher has to degrade
" to ReloadTick's poll, not silently stop reloading.
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
    \ '--format', '%w%f'] + l:dirs, {'out_cb': 'ReloadPush'})
endfunction

" Reloading under insert/cmdline is left to the InsertLeave/CmdlineLeave
" checktime below.
function! ReloadPush(ch, msg)
  if mode() =~# '^[icR]' | return | endif
  silent! checktime
endfunction

function! ReloadTick(t)
  call ReloadWatch()
  if mode() =~# '^[icR]' | return | endif
  silent! checktime
endfunction

" Load a titled location list of change sites and underline the changed lines.
" qffile: file:line:col:text per line. linesfile: JSON {abs path: [line, ...]}.
function! ReviewLoad(title, qffile, linesfile)
  " Reloading the same title keeps the current entry.
  let prev = {}
  if getloclist(0, {'title': 1}).title ==# a:title
    let idx = getloclist(0, {'idx': 0}).idx
    let items = getloclist(0)
    if idx > 0 && idx <= len(items) | let prev = items[idx - 1] | endif
  endif

  if exists('t:gdiff_spec')
    let spec = t:gdiff_spec
    call GdiffClose()
  endif
  " setloclist() from the list's own window overwrites it instead of pushing.
  lclose

  let g:review_lines = json_decode(join(readfile(a:linesfile), ''))
  hi ReviewChange cterm=underline gui=underline
  aug ReviewMatch | au! | au BufWinEnter * call ReviewMark() | aug END
  for w in range(1, winnr('$'))
    call win_execute(win_getid(w), 'call ReviewMark()')
  endfor
  " Location list, not quickfix: Enter opens in the list's own window, not one
  " vim picks by layout (the diff pane).
  call setloclist(0, [], ' ', {'title': a:title, 'efm': '%f:%l:%c:%m',
    \ 'lines': readfile(a:qffile)})
  " File-info message + (1 of N) line -> hit-enter prompt.
  let sm = &shortmess
  set shortmess+=F
  lopen
  exe 'll ' . max([ReviewSameEntry(prev), 1])
  if exists('l:spec')
    call Gdiff(spec)
  endif
  call ReviewEcho()
  let &shortmess = sm
endfunction

" Index of the entry nearest prev's line: same file and text first, then same
" file; 0 if none.
function! ReviewSameEntry(prev)
  if empty(a:prev) | return 0 | endif
  for same_text in [1, 0]
    let best = 0 | let dist = -1
    for [i, e] in items(getloclist(0))
      if e.bufnr != a:prev.bufnr || (same_text && e.text !=# a:prev.text)
        continue
      endif
      let d = abs(e.lnum - a:prev.lnum)
      if dist < 0 || d < dist | let best = i + 1 | let dist = d | endif
    endfor
    if best | return best | endif
  endfor
  return 0
endfunction

" Underline the current window's changed lines, replacing its old marks.
function! ReviewMark()
  for id in get(w:, 'review_ids', []) | silent! call matchdelete(id) | endfor
  let w:review_ids = []
  let lines = get(g:review_lines, expand('%:p'), [])
  " matchaddpos() takes at most eight positions per call.
  for i in range(0, len(lines) - 1, 8)
    call add(w:review_ids, matchaddpos('ReviewChange', lines[i : i + 7]))
  endfor
endfunction

" Commands
" ========
com! Tidy :sil! exe '%s/\v\ +$//g' <bar> :sil! exe '%s/\v[^\x00-\x7F]+//g'
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
com! Csi :call CSInv()
com! Dcl :call DelCommentLines()
com! Df :call ToggleDiff()
com! Sv :so $MYVIMRC
com! -nargs=1 St :call SetTab("<args>")
com! -nargs=1 S :call Style("<args>")
com! Cl :%bd|e#|bd#
com! -range Fc :call FileCheck(<range>, <line1>, <line2>)

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
nnoremap <silent><Leader>e :call Gdiff('')<CR>
nnoremap <silent><Leader>r :call Gdiff('@~1')<CR>
nnoremap <silent><Leader>t :call GdiffNum()<CR>
nnoremap <silent>[q :call ReviewGo(1)<CR>
nnoremap <silent>]q :call ReviewGo(-1)<CR>
nnoremap <silent><Leader>q :lopen<CR>
nnoremap <Leader>ld :exe 'tag' expand('<cword>')<CR>
nnoremap <Leader>le :SyntasticCheck<CR>
nnoremap <Leader>lt :TagbarToggle<CR>
nnoremap <Leader>lc :call LspFunc()<CR>
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
set modelines=1
set clipboard^=unnamed,unnamedplus mouse=a termguicolors background=dark
au FileType llvm setlocal commentstring=;\ %s | set textwidth=0
au FileType mlir setlocal commentstring=//\ %s
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
" Force vim-lsp to resync the buffer on :e (workaround for stale didOpen).
au BufReadPre * if &buftype ==# '' && expand('<afile>') !~# '^fugitive://'
  \ | silent! doautocmd <nomodeline> BufDelete | endif
au FileChangedShell * call DiskChanged()
au FocusGained,BufEnter,InsertLeave,CmdlineLeave * silent! checktime
au BufReadPost,BufNewFile * call ReloadWatch()
if !exists('s:reload_tick')
  let s:reload_tick = timer_start(5000, 'ReloadTick', {'repeat': -1})
endif
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
