" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#fzf#pages() abort "{{{1
  if !exists('*fzf#run')
    call wiki#log#warn('fzf must be installed for this to work')
    return
  endif

  let l:root = wiki#get_root() . s:slash
  let l:extension = len(g:wiki_filetypes) == 1
        \ ? g:wiki_filetypes[0]
        \ : '{' . join(g:wiki_filetypes, ',') . '}'
  let l:pages = globpath(l:root, '**/*.' . l:extension, v:false, v:true)
  call map(l:pages, {_, x -> x . '#####'
        \ .'/' . fnamemodify(
        \   substitute(x, escape(l:root, '\'), '', ''),
        \   ':r')
        \})

  let l:fzf_opts = join([
        \ '-d"#####" --with-nth=-1 --print-query --prompt "WikiPages> "',
        \ '--expect=' . get(g:, 'wiki_fzf_pages_force_create_key', 'alt-enter'),
        \ g:wiki_fzf_pages_opts,
        \])

  call fzf#run(fzf#wrap({
        \ 'source': l:pages,
        \ 'sink*': funcref('s:accept_page'),
        \ 'options': l:fzf_opts
        \}))
endfunction

let s:slash = exists('+shellslash') && !&shellslash ? '\' : '/'

" }}}1
function! wiki#fzf#tags() abort "{{{1
  if !exists('*fzf#run')
    call wiki#log#warn('fzf must be installed for this to work')
    return
  endif

  " Preprosess tags
  let l:tags = wiki#tags#get_all()
  let l:results = []
  for [l:key, l:val] in items(l:tags)
    for [l:file, l:lnum] in l:val
      let l:results += [l:key . ': ' . l:file . ':' . l:lnum]
    endfor
  endfor

  " Feed tags to FZF
  call fzf#run(fzf#wrap({
        \ 'source': l:results,
        \ 'sink*': funcref('s:accept_tag'),
        \ 'options': '--expect=ctrl-l --prompt "WikiTags> " '
        \}))
endfunction

" }}}1
function! wiki#fzf#toc() abort "{{{1
  if !exists('*fzf#run')
    call wiki#log#warn('fzf must be installed for this to work')
    return
  endif

  let l:toc = wiki#toc#gather_entries()
  let l:lines = []
  for l:entry in l:toc
    let l:indent = repeat('.', l:entry.level - 1)
    let l:line = l:entry.lnum . '|' . l:indent . l:entry.header
    call add(l:lines, l:line)
  endfor

  call fzf#run(fzf#wrap({
        \ 'source': reverse(l:lines),
        \ 'sink': funcref('s:accept_toc_entry'),
        \ 'options': join([
        \       '--prompt "WikiToc> "',
        \       '--delimiter "\\|"',
        \       '--with-nth "2.."'
        \ ], ' ')
        \}))
endfunction

"}}}1

function! s:accept_page(lines) abort "{{{1
  " a:lines is a list with two or three elements. Two if there were no matches,
  " and three if there is one or more matching names. The first element is the
  " search query; the second is either an empty string or the alternative key
  " specified by g:wiki_fzf_pages_force_create_key (e.g. 'alt-enter') if this
  " was pressed; the third element contains the selected item.
  if len(a:lines) < 2 | return | endif

  if len(a:lines) == 2 || !empty(a:lines[1])
    call wiki#page#open(a:lines[0])
    sleep 1
  else
    let l:file = split(a:lines[2], '#####')[0]
    execute 'edit ' . l:file
  endif
endfunction

" }}}1
function! s:accept_tag(input) abort "{{{1
  let l:key = a:input[0]
  let [l:tag, l:file, l:lnum] = split(a:input[1], ':')

  if l:key =~# 'ctrl-l'
    let l:locations = copy(wiki#tags#get_all()[l:tag])
    call map(l:locations, '{
          \ ''filename'': v:val[0],
          \ ''lnum'': v:val[1],
          \ ''text'': ''Tag: '' . l:tag,
          \}')
    call setloclist(0, l:locations, 'r')
    lfirst
    lopen
    wincmd w
  else
    execute 'edit ' . l:file
    execute l:lnum
  endif
endfunction

" }}}1
function! s:accept_toc_entry(line) abort "{{{1
  let l:lnum = split(a:line, '|')[0]
  execute l:lnum
endfunction
"}}}1

function! wiki#fzf#rg_text(fullscreen, pattern, dir) "{{{1
    if !exists('*fzf#run')
        call wiki#log#warn('fzf must be installed for this to work')
        return
    endif

    call fzf#vim#grep(
    \   'rg --column --line-number --smart-case --no-heading --color=always ' . shellescape(a:pattern) . ' ' . fnameescape(a:dir), 1,
    \   a:fullscreen ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
    \           : fzf#vim#with_preview({'down': '40%', 'options': '--delimiter : --nth 4.. -e'}, 'right:50%', '?'),
    \   a:fullscreen)
endfunction
"}}}1

" Search all text that match pattern in files within dir
function! wiki#fzf#rg_text_files(fullscreen, pattern, dir) "{{{1
    if !exists('*fzf#run')
        call wiki#log#warn('fzf must be installed for this to work')
        return
    endif

    call fzf#vim#grep(
    \   'rg --column --line-number --smart-case --no-heading --color=always ' . shellescape(a:pattern) . ' ' . fnameescape(a:dir), 1,
    \   a:fullscreen ? fzf#vim#with_preview('up:60%')
    \           : fzf#vim#with_preview({'down': '40%'}, 'right:50%', '?'),
    \   a:fullscreen)
endfunction
"}}}1

" Search for files in dir that match pattern
function! wiki#fzf#rg_files(fullscreen, dir) "{{{1
    if !exists('*fzf#run')
        call wiki#log#warn('fzf must be installed for this to work')
        return
    endif

    call fzf#vim#files(a:dir, fzf#vim#with_preview({
               \ 'source': join([
                    \ 'rg',
                    \ '--follow',
                    \ '--smart-case',
                    \ '--line-number',
                    \ '--color never',
                    \ '--no-messages',
                    \ '--files',
                    \ a:dir]),
               \ 'down': '40%',
               \ 'options': ['--layout=reverse', '--inline-info']
               \ }), a:fullscreen)
endfunction
"}}}1

function! s:insert_link_file(lines) abort "{{{1
    if a:lines == [] || a:lines == [''] || a:lines == ['', '']
        call feedkeys('a', 'n')
        return
    endif
    let filename = split(a:lines[1], "\\.md")[0]
    let link = "[" . filename . "](" . a:lines[1] . ")"
    let @* = link
    silent! let @* = link
    silent! let @+ = link
    call feedkeys('pa', 'n')
endfunction
"}}}1

function! wiki#fzf#insert_link(fullscreen) abort "{{{1
    if !exists('*fzf#run')
        call wiki#log#warn('fzf must be installed for this to work')
        return
    endif

    call fzf#vim#files(vimwiki#vars#get_wikilocal('path'), 
    \ {
            \ 'sink*': function('s:insert_link_file'),
            \ 'source': join([
                 \ 'rg',
                 \ '--files',
                 \ '--follow',
                 \ '--smart-case',
                 \ '--line-number',
                 \ '--color never',
                 \ '--no-messages',
                 \ '*'.vimwiki#vars#get_wikilocal('ext'),
                 \ ]),
            \ 'down': '40%',
            \ 'options': [
                \ '--layout=reverse', '--inline-info',
                  \ '--preview=' . 'cat {}']
            \ }, a:fullscreen)
endfunction
"}}}1
