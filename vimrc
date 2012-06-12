set nocompatible               " be iMproved

filetype off                   " required!

"<Leader> key is ,
let mapleader=","

" Vundle init
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

"{{{ Vundle Bundles!
Bundle 'gmarik/vundle'

" My Bundles here:
"
" repos on github
Bundle 'tpope/vim-fugitive'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'scrooloose/nerdtree.git'
Bundle 'wincent/Command-T.git'
Bundle 'joonty/vim-phpqa.git'
Bundle 'joonty/vim-sauce.git'
Bundle 'joonty/vim-xdebug.git'
"Bundle 'joonty/vim-debugger.git'
Bundle 'joonty/vim-phpunitqf.git'
Bundle 'joonty/vim-taggatron.git'
Bundle 'tpope/vim-fugitive.git'
Bundle 'greyblake/vim-preview.git'
Bundle 'sjl/gundo.vim.git'
Bundle 'fholgado/minibufexpl.vim.git'
Bundle 'shawncplus/phpcomplete.vim.git'
Bundle 'ervandew/supertab.git'
Bundle 'msanders/snipmate.vim.git'
" vim-scripts repos
Bundle 'taglist.vim'
Bundle 'L9'
Bundle 'FuzzyFinder'
"}}}

filetype plugin indent on     " required! 
syntax enable
colorscheme jc
runtime macros/matchit.vim
let g:EasyMotion_leader_key = '<Space>'

"{{{ Functions

"{{{ Open URL in browser

function! Browser ()
    let line = getline (".")
    let line = matchstr (line, "http[^   ]*")
    exec "!google-chrome ".line
endfunction

"}}}
"{{{ Close quickfix with main window close 
au BufEnter * call MyLastWindow()
function! MyLastWindow()
    " if the window is quickfix go on
    if &buftype=="quickfix"
        " if this window is last on screen quit without warning
        if winbufnr(2) == -1
            quit!
        endif
    endif
endfunction
"}}}
"{{{ Diff current unsaved file
function! s:DiffWithSaved()
    let filetype=&ft
    diffthis
    vnew | r # | normal! 1Gdd
    diffthis
    exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
"}}}
"{{{ Clean close
command! Bw call CleanClose(1,0)
command! Bq call CleanClose(0,0)
command! -bang Bw call CleanClose(1,1)
command! -bang Bq call CleanClose(0,1)

function! CleanClose(tosave,bang)
    if a:bang == 1
        let bng = "!"
    else
        let bng = ""
    endif
    if (a:tosave == 1)
        w!
    endif
    let todelbufNr = bufnr("%")
    let newbufNr = bufnr("#")
    if ((newbufNr != -1) && (newbufNr != todelbufNr) && buflisted(newbufNr))
        exe "b".newbufNr
    else
        exe "bnext".bng
    endif

    if (bufnr("%") == todelbufNr)
        new
    endif
    exe "bd".bng.todelbufNr
endfunction
"}}}
"{{{ Run command and put output in scratch
command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
function! s:RunShellCommand(cmdline)
    let isfirst = 1
    let words = []
    for word in split(a:cmdline)
        if isfirst
            let isfirst = 0  " don't change first word (shell command)
        else
            if word[0] =~ '\v[%#<]'
                let word = expand(word)
            endif
            let word = shellescape(word, 1)
        endif
        call add(words, word)
    endfor
    let expanded_cmdline = join(words)
    botright new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    call setline(1, 'You entered:  ' . a:cmdline)
    call setline(2, 'Expanded to:  ' . expanded_cmdline)
    call append(line('$'), substitute(getline(2), '.', '=', 'g'))
    silent execute '$read !'. expanded_cmdline
    1
endfunction
"}}}
"{{{ CakePHP unit test callback for PHPUnitQf
function! CakePHPTestCallback(args)
    " Trim white space
    let l:args = substitute(a:args, '^\s*\(.\{-}\)\s*$', '\1', '')

    " If no arguments are passed to :Test
    if len(l:args) is 0
        let l:file = expand('%')
        if l:file =~ "^.*app/Test/Case.*"
            " If the current file is a unit test
            let l:args = substitute(l:file,'^.*app/Test/Case/\(.\{-}\)Test\.php$','\1','')
        else
            " Otherwise try and run the test for this file
            let l:args = substitute(l:file,'^.*app/\(.\{-}\)\.php$','\1','')
        endif
    endif
    return l:args
endfunction
"}}}
" {{{ Sass compile
let g:sass_output_file = ""
let g:sass_path_maps = {}
command! Sass call SassCompile()
autocmd BufWritePost *.scss call SassCompile()
function! SassCompile()
    let curfile = expand('%:p')
    let inlist = 0
    for fpath in keys(g:sass_path_maps)
        if fpath == curfile
            let g:sass_output_file = g:sass_path_maps[fpath]
            let inlist = 1
            break
        endif
    endfor
    if g:sass_output_file == ""
        let g:sass_output_file = input("Please specify an output CSS file: ",g:sass_output_file,"file")
    endif
    let l:op = system("sass --no-cache --style compressed ".@%." ".g:sass_output_file)
    if l:op != ""
        echohl Error | echo "Error compiling sass file" | echohl None
        let &efm="Syntax error: %m %#on line %l of %f%.%#"
        cgete [l:op]
        cope
    endif
    if inlist == 0
        let choice = confirm("Would you like to keep using this output path for this sass file?","&Yes\n&No")
        if choice == 1
            let g:sass_path_maps[curfile] = g:sass_output_file
        endif
    endif
    let g:sass_output_file = ""
endfunction
"}}}
"{{{ Function to use spaces instead of tabs
command! -nargs=+ Spaces call s:use_spaces(<q-args>)
function! s:use_spaces(swidth)
    let l:cwidth = a:swidth
    let &tabstop=l:cwidth
    let &shiftwidth=l:cwidth
    let &softtabstop=l:cwidth
    set expandtab
endfunction
"}}}
"{{{ Function to use tabs instead of spaces
command! Tabs call s:use_tabs()
function! s:use_tabs()
    let &tabstop=4
    let &shiftwidth=4
    let &softtabstop=0
    set noexpandtab
endfunction
"}}}
"{{{ Get a dictionary of expected windows and their numbers
function! GetKnownWindows()
    let l:wins=[] 
    let l:ret = {}
    windo call add(l:wins, [winnr(), bufname('%')]) 
    for list in l:wins
       if list[1] =~ "^.*__Tag_List__$"
           let l:ret['taglist'] = list[0]
       elseif list[1] == "-MiniBufExplorer-"
           let l:ret['minibuf'] = list[0]
       elseif list[1] =~ "NERD_tree_.*"
           let l:ret['nerdtree'] = list[0]
       else
           if !has_key(l:ret,'other')
               let l:ret['other'] = list[0]
           endif
       endif
    endfor
    return l:ret
endfunction
" }}}
" {{{ Reset window arrangement (to the way I like it) if things mess up
function! SetWindows()
	" Always run this, as it refreshes with current dir
	exec 'NERDTree'
    exec 'silent res 500'
    let l:windows = GetKnownWindows()
    if !has_key(l:windows,'other')
        new
    endif
    if !has_key(l:windows,'nerdtree')
        exec 'silent 1wincmd H'
        let l:windows = GetKnownWindows()
    endif
    if !has_key(l:windows,'taglist')
        exec 'TlistToggle'
        exec 'silent 1wincmd L'
        let l:windows = GetKnownWindows()
    endif

    if has_key(l:windows,'minibuf')
        exec 'silent '.l:windows['minibuf'].'wincmd W'
        exec 'silent '.l:windows['minibuf'].'wincmd K'
        exec 'silent res 2'
        let l:windows = GetKnownWindows()
    endif

    exec 'silent '.l:windows['nerdtree'].'wincmd W'
    exec 'silent '.l:windows['nerdtree'].'wincmd H'
    exec 'silent 500winc < | 30winc >'
    exec 'normal gg'
    let l:windows = GetKnownWindows()

    exec 'silent '.l:windows['taglist'].'wincmd W'
    exec 'silent '.l:windows['taglist'].'wincmd L'
    exec 'silent 500winc < | 30winc >'

    let l:windows = GetKnownWindows()

    exec 'silent '.l:windows['other'].'wincmd W'
    exec 'silent res 500'

endfunction
"}}}
"{{{ Wipeout buffers not used
function! Wipeout()
  " list of *all* buffer numbers
  let l:buffers = range(1, bufnr('$'))

  " what tab page are we in?
  let l:currentTab = tabpagenr()
  try
    " go through all tab pages
    let l:tab = 0
    while l:tab < tabpagenr('$')
      let l:tab += 1

      " go through all windows
      let l:win = 0
      while l:win < winnr('$')
        let l:win += 1
        " whatever buffer is in this window in this tab, remove it from
        " l:buffers list
        let l:thisbuf = winbufnr(l:win)
        call remove(l:buffers, index(l:buffers, l:thisbuf))
      endwhile
    endwhile

    " if there are any buffers left, delete them
    if len(l:buffers)
      execute 'bwipeout' join(l:buffers)
    endif
  finally
    " go back to our original tab page
    execute 'tabnext' l:currentTab
  endtry
endfunction
"}}}
"{{{ Find and replace in multiple files
command! -nargs=* -complete=file Fart call FindAndReplace(<f-args>)
function! FindAndReplace(...)
    if a:0 < 3
        echohl Error | echo "Three arguments required: 1. file pattern, 2. search expression and 3. replacement" | echohl None
        return
    endif
    if a:0 > 3
        echohl Error | echo "Too many arguments, three required: 1. file pattern, 2. search expression and 3. replacement" | echohl None
        return
    endif
    let l:pattern = a:1
    let l:search = a:2
    let l:replace = a:3
    echo "Replacing occurences of '".l:search."' with '".l:replace."' in files matching '".l:pattern."'"

    execute '!find . -name "'.l:pattern.'" -print | xargs -t sed -i "s/'.l:search.'/'.l:replace.'/g"'
endfunction

"}}}
"}}}

"{{{ Settings
set ttyscroll=0
set hidden
set history=1000
set ruler
set ignorecase
set smartcase
set title
set scrolloff=3
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set wildmenu
set wildmode=list:longest
set wrapscan
set clipboard=unnamed
set visualbell
set backspace=indent,eol,start
"Status line coolness
set laststatus=2
set statusline=branch:\ %{fugitive#statusline()}\ %F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]
set showcmd
" Search things
set hlsearch
set incsearch " ...dynamically as they are typed.
set listchars=tab:>-,trail:·,eol:$
" Folds
set foldmethod=marker
set wildmenu
set wildmode=list:longest,full
set mouse=a
set nohidden
set shortmess+=filmnrxoOt
set viewoptions=folds,options,cursor,unix,slash
set virtualedit=onemore

"Spaces, not tabs
set shiftwidth=4
set tabstop=4
set expandtab

"PHP
let php_sql_query=1
let php_htmlInStrings=1
"}}}

let g:NERDTreeMapHelp = "h"

" Set font for GUI (e.g. GVim)
if has("gui_running")
    set guifont=Anonymous\ Pro\ 13
endif

"{{{ PHPDoc
let g:pdv_cfg_Author = "Jon Cairns <jon@22blue.co.uk>"
let g:pdv_cfg_Copyright = "Copyright (c) 22 Blue ".strftime("%Y")
let g:pdv_cfg_License = ""
let g:pdv_cfg_Version = ""
let g:pdv_cfg_php4always = 0
"}}}

"{{{ Mini Buffer settings
let g:miniBufExplMapWindowNavVim = 1 
let g:miniBufExplMapWindowNavArrows = 1 
let g:miniBufExplMapCTabSwitchBufs = 1 
let g:miniBufExplModSelTarget = 1 
"}}}

"{{{ Key Maps

"Escape insert with ww
inoremap ww <Esc>
inoremap <C-z> <C-x><C-u>
nnoremap JJJJ <Nop>

" Open Url on this line with the browser \w
map <Leader>b :call Browser ()<CR>

" Instead of 1 line, move 3 at a time
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" My handy window reset function
nnoremap <C-a> :call SetWindows()<CR>

" Show hidden characters (spaces, tabs, etc) 
nmap <silent> <leader>s :set nolist!<CR>
" PHPDoc commands
inoremap <C-d> <ESC>:call PhpDocSingle()<CR>i 
nnoremap <C-d> :call PhpDocSingle()<CR> 
vnoremap <C-d> :call PhpDocRange()<CR> 
" Ultra-amazing history viewer
nnoremap \ :GundoToggle<CR>
"}}}

"{{{ Commands
" Common mistypings
command! Q q
command! -bang Q q<bang>
command! Qall qall
command! -bang Qall qall<bang>
command! W w
command! -nargs=1 -complete=tag Tag tag <args>
" Save a file that requires sudoing even when
" you opened it as a normal user.
command! Sw w !sudo tee % > /dev/null
" Shortcut to NERDTree
command! -nargs=1 -complete=dir Tree NERDTree <args>
" Command to build ctags file
command! -nargs=+ -complete=dir Rtags !ctags -R --languages=+PHP --exclude=build <args> | set tags=tags
" Show difference between modified buffer and original file
command! DiffSaved call s:DiffWithSaved()

"}}}

" PHPQA stuff
" Turn autorun off, and turn it back on in individual
" project settings
let g:phpqa_codecoverage_autorun = 0
let g:phpqa_messdetector_autorun = 0
let g:phpqa_codesniffer_autorun = 0

" Tab completion - local
let g:SuperTabDefaultCompletionType = "<c-x><c-p>"

" PHPUnit stuff
let g:phpunit_cmd = "caketest"
let g:phpunit_args = "--no-colors --stderr"

let g:snippets_dir = "~/.vim/snippets/"
