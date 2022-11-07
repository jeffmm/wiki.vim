" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:wiki_loaded') | finish | endif
let g:wiki_loaded = 1

" Initialize options
call wiki#init#option('wiki_cache_persistent', 1)
call wiki#init#option('wiki_cache_root',
      \ wiki#u#get_os() ==# 'win'
      \ ? fnamemodify(tempname(), ':h')
      \ : (empty($XDG_CACHE_HOME)
      \    ? $HOME . '/.cache'
      \    : $XDG_CACHE_HOME) . '/wiki.vim')
call wiki#init#option('wiki_export', {
      \ 'args' : '',
      \ 'from_format' : 'markdown',
      \ 'ext' : 'pdf',
      \ 'link_ext_replace': v:false,
      \ 'view' : v:false,
      \ 'output' : fnamemodify(tempname(), ':h'),
      \})
call wiki#init#option('wiki_filetypes', ['md'])
call wiki#init#option('wiki_fzf_pages_opts', '')
call wiki#init#option('wiki_global_load', 0)
call wiki#init#option('wiki_index_name', 'index')
call wiki#init#option('wiki_journal', {
      \ 'name' : 'journal',
      \ 'frequency' : 'monthly',
      \ 'date_format' : {
      \   'daily' : '%Y%m%d',
      \   'weekly' : '%Y_w%V',
      \   'monthly' : '%Y%m',
      \ },
      \})
call wiki#init#option('wiki_link_extension', '.md')
call wiki#init#option('wiki_link_target_type', 'md')
call wiki#init#option('wiki_link_toggle_on_follow', 1)
call wiki#init#option('wiki_link_toggles', {
      \ 'wiki': 'wiki#link#md#template',
      \ 'md': 'wiki#link#wiki#template',
      \ 'adoc_xref_bracket': 'wiki#link#adoc_xref_inline#template',
      \ 'adoc_xref_inline': 'wiki#link#adoc_xref_bracket#template',
      \ 'date': 'wiki#link#wiki#template',
      \ 'shortcite': 'wiki#link#md#template',
      \ 'url': 'wiki#link#md#template',
      \})
call wiki#init#option('wiki_map_create_page', '')
call wiki#init#option('wiki_map_link_create', '')
call wiki#init#option('wiki_mappings_use_defaults', 'all')
call wiki#init#option('wiki_month_names', [
      \ 'January', 'February', 'March', 'April', 'May', 'June', 'July',
      \ 'August', 'September', 'October', 'November', 'December'
      \])
call wiki#init#option('wiki_resolver', 'wiki#url#wiki#resolver')
call wiki#init#option('wiki_root', '')
call wiki#init#option('wiki_tag_list', { 'output' : 'loclist' })
call wiki#init#option('wiki_tag_search', { 'output' : 'loclist' })
call wiki#init#option('wiki_tag_parsers', [g:wiki#tags#default_parser])
call wiki#init#option('wiki_tag_scan_num_lines', 15)
call wiki#init#option('wiki_templates', [])
call wiki#init#option('wiki_template_title_month',
      \ '# Summary, %(year) %(month-name)')
call wiki#init#option('wiki_template_title_week',
      \ '# Summary, %(year) week %(week)')
call wiki#init#option('wiki_toc_title', 'Contents')
call wiki#init#option('wiki_viewer', {
      \ '_' : get({
      \   'linux' : 'xdg-open',
      \   'mac' : 'open',
      \ }, wiki#u#get_os(), ''),
      \})
call wiki#init#option('wiki_write_on_nav', 0)
call wiki#init#option('wiki_zotero_root', '~/.local/zotero')

" Initialize global commands
command! WikiEnable   call wiki#buffer#init()
command! WikiIndex    call wiki#goto_index()
command! WikiOpen     call wiki#page#open_ask()
command! WikiReload   call wiki#reload()
command! WikiJournal  call wiki#journal#make_note()
command! CtrlPWiki    call ctrlp#init(ctrlp#wiki#id())
" command! -bang WikiFzfPages call wiki#fzf#pages(<bang>0)
" command! -bang WikiFzfPages
        " \ call fzf#vim#files("~/.vim/wiki", fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

" command! -bang WikiFzfTags  call wiki#fzf#tags(<bang>0)
" command! -bang WikiFzfText  call wiki#fzf#text(<bang>0)

" Search note tags, which is any word surrounded by colons (vimwiki style tags)
command! -bang WikiSearchTags 
      \ call wiki#fzf#rg_text(<bang>0, ':[a-zA-Z0-9]+:', fnameescape(wiki#get_root_global()))
nnoremap <silent><script> <Plug>WikiSearchTags :WikiSearchTags<CR>

" Search for text in wiki files
command! -bang WikiSearchText 
      \ call wiki#fzf#rg_text(<bang>0, '[a-zA-Z0-9]+', fnameescape(wiki#get_root_global()))
nnoremap <silent><script> <Plug>WikiSearchText :WikiSearchText<CR>

" Search for filenames in wiki
command! -bang -nargs=? -complete=dir WikiSearchFiles 
      \ call wiki#fzf#rg_files(<bang>0, fnameescape(wiki#get_root_global()))
nnoremap <silent><script> <Plug>WikiSearchFiles :WikiSearchFiles<CR>

" Initialize mappings
nnoremap <silent> <plug>(wiki-index)     :WikiIndex<cr>
nnoremap <silent> <plug>(wiki-open)      :WikiOpen<cr>
nnoremap <silent> <plug>(wiki-journal)   :WikiJournal<cr>
nnoremap <silent> <plug>(wiki-reload)    :WikiReload<cr>
" nnoremap <silent> <plug>(wiki-fzf-pages) :WikiFzfPages<cr>
nnoremap <silent> <plug>(wiki-fzf-pages) :WikiSearchFiles<cr>
nnoremap <silent> <plug>(wiki-fzf-tags)  :WikiSearchTags<cr>
nnoremap <silent> <plug>(wiki-fzf-text)  :WikiSearchText<cr>

" Apply default mappings
let s:mappings = index(['all', 'global'], g:wiki_mappings_use_defaults) >= 0
      \ ? {
      \ '<plug>(wiki-index)' : '<leader>ww',
      \ '<plug>(wiki-open)' : '<leader>wn',
      \ '<plug>(wiki-journal)' : '<leader>wj',
      \ '<plug>(wiki-reload)' : '<leader>wx',
      \ '<plug>(wiki-fzf-pages)' : '<leader>wsf',
      \ '<plug>(wiki-fzf-tags)' : '<leader>wsT',
      \ '<plug>(wiki-fzf-text)' : '<leader>wst',
      \} : {}
call extend(s:mappings, get(g:, 'wiki_mappings_global', {}))
call wiki#init#apply_mappings_from_dict(s:mappings, '')

" Enable on desired filetypes
augroup wiki
  autocmd!
  for s:ft in g:wiki_filetypes
    execute 'autocmd BufRead,BufNewFile *.' . s:ft 'call s:autoload()'
  endfor
augroup END

function! s:autoload() abort
  if g:wiki_global_load
        \ || wiki#get_root_local() ==# wiki#get_root_global()
    WikiEnable
  endif
endfunction
