"""""""""""""""""
" Script vars
"""""""""""""""""
let s:script_dir=expand('<sfile>:p:h:h').'/bin'

"""""""""""""""""
" Basic Stuff
"""""""""""""""""

set nonu
" set relativenumber
" set nu
set ai

" Allow tree navigation of dirs
let g:netrw_liststyle = 3

" Get quickfix window
" :cope

" Change screen size
nmap - <C-w>-
nmap + <C-w>+

" Search functions in a file (assuming they follow this format)
" cab fn ^_*\l\w\+(

" So 'ta' uses ctags first instead of cscope
set csto=1

" Use find across the project
" set path=$PWD/**
cab f find

" Indentation
au FileType python  set expandtab
au FileType python  set tabstop=4
au FileType python  set shiftwidth=4

au FileType yaml  set expandtab
au FileType yaml  set tabstop=4
au FileType yaml  set shiftwidth=4

" Across cscope results
nnoremap } :cnext<CR>
nnoremap { :cprev<CR>

" When multiple files are opened (vim file1.txt file2.c)
nnoremap ] :next<CR>
nnoremap [ :prev<CR>

" C code formatting
" function call args one below the other
" switch and case at same indentation
" function return types at beginning
" indent function definition args by one tab
set cino=t0,:0,(0,W8
 
"""""""""""""""""
" Nice to Have
"""""""""""""""""

" Scroll quicker
nmap <C-j> 10j
nmap <C-k> 10k

" Jump to main
nmap main /^main(<CR>zt:noh<CR>

" Function and struct headers (comments)
iab struct_hdr /**<CR>struct foo -<CR>@bar1:<CR>@bar2:<CR>/
iab function_hdr /**<CR>function() -<CR>@:<CR>@:<CR>/
nmap st O<Esc>istruct_hdr<Esc>
nmap fn O<Esc>ifunction_hdr<Esc>
nmap ss /\s\+$<CR>

" Fix common typos
au FileType text iab teh the

" Add comments for myself. Ideally have a way to check before pushing for a PR.
nmap <C-w>d O// TODO Gaurav: <Esc>A

"""""""""""""""""
" Rebuild tags
"""""""""""""""""

function CS_Reset(a, b)
    execute "cs reset"
    call popup_create('Tags and Cscope are ready!', {'border': [], 'padding': [1], 'time': 2000} )
endfunction

function Tagify()
    let l:dpath=getcwd()
    let l:cmd = "sh ".s:script_dir."/tagify.sh"

    let l:options = { 'hidden': '1', 'exit_cb': 'CS_Reset' }
    let l:buf =  term_start(l:cmd, l:options)
endfunction

command CS call Tagify()

"""""""""""""""""""""""""""""""""""""""""""""""
" Get function comment
"""""""""""""""""""""""""""""""""""""""""""""""

func GetFunctionArgNames()
	let qualifier = ['const', 'volatile', 'unsigned', 'signed', 'static']
	let basic_type = ['int' , 'char', 'float', 'double', 'long', 'uint', 'short', 'void', 'uint8_t', 'uint16_t', 'uint32_t', 'uint64_t', 'int8_t', 'int16_t', 'int32_t', 'int64_t', 'u8', 'u16', 'u32', 'u64', 's8', 's16', 's32', 's64', 'bool', 'size_t', 'ssize_t', 'off_t', '#define', 'uintptr_t', 'atomic_t', 'atomic64_t']
	let derived_type = ['struct', 'enum', 'union', 'class']

	let start_line = line('.')
	execute "normal! f(%"
	let end = line('.')
	let words = []
	for line in range(l:start_line, l:end)
		call cursor(l:line, 1)
		if l:line == l:start_line
			execute "normal! f("
			let l:startpos = col('.')
			let l:args = getline(line)[l:startpos:]
		else
			let l:args = getline(l:line)
		endif
		let l:words += split(l:args)
	endfor

	let arglist = []
	let skip = 0
	for w in l:words
		if l:skip == 1
			let l:skip = 0
			continue
		endif

		if (index(l:qualifier, l:w) >= 0)
			continue
		endif

		if (index(l:basic_type, l:w) >= 0)
			continue
		endif

		if (index(l:derived_type, l:w) >= 0)
			let l:skip = 1
			continue
		endif

		let l:w = substitute(l:w, "[;,*&()]", "", "g")
		let l:arglist += [l:w]
	endfor

    call cursor(l:start_line, 1)
	return l:arglist
endfunc

func GetFunctionComment()
	let l:funcname = expand("<cword>")
	let l:heading = "/**\n * ".l:funcname."() -\n"
	let l:spacer = " *\n"
	let l:end = " */\n"

	let l:arglist = GetFunctionArgNames()

	let l:args = ""
	for a in l:arglist
        if len(l:a) > 0
            let l:args = l:args." * @".l:a.":\n"
        endif
	endfor
	let l:comment = l:heading.l:spacer.l:args.l:end
	let @@=l:comment
endfunc

nnoremap FF :call GetFunctionComment()<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Get functions in current file
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use the following command to generate a tags file:
"   ctags --fields="nK" -R . > extags.txt
" This can be run separately, since vim always reads the file, it doesn't need to re-read it.
" includes line numbers).
" The --fields option is critical. It adds information regarding line number and type of the tag.

function! LineNumberCmp(leftArg, rightArg)
  let l:left = str2nr(a:leftArg['lnum'], 10)
  let l:right = str2nr(a:rightArg['lnum'], 10)

  if l:left == l:right
    return 0

  elseif l:left < l:right
    return -1
  else
    return 1
  endif
endfunction

func! FuncTagList(allowedTypes)
    let l:filename = @%
    let l:cmd = "grep -w ".l:filename." tags | awk '{print $1\":\"$(NF-1)\":\"$NF}'"
    let l:symbols = split(system(l:cmd))
    let l:pattern_list = []
    for s in l:symbols
	    let l:tuple = split(l:s, ':')
        if index(a:allowedTypes, l:tuple[1]) >= 0
	        let l:pattern_list += [{'filename': l:filename, 'text': l:tuple[0], 'lnum': l:tuple[3]}]
        endif
    endfor

    let l:pattern_list_sorted = sort(l:pattern_list, function("LineNumberCmp"))
    call setqflist([], ' ', {'idx': '0', 'title': 'Symbols in File', 'context': 'Using tags file'})
    call setqflist(l:pattern_list_sorted, 'r')
endfunc

command FN call FuncTagList(['function'])
command ST call FuncTagList(['struct'])
