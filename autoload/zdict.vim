let s:last_queried_word = ''

function! s:get_word () " {{{
    let l:row = line('.')
    let l:col = col('.')
    let l:mode = mode()

    let l:old_z_reg = @z
    if l:mode == 'n'
        silent normal! "zyiw
    elseif l:mode == 'v' || l:mode == 'V' || l:mode == ""
        silent normal! "zy
    endif
    let l:word = @z
    let @z = l:old_z_reg

    call cursor(l:row, l:col)
    return l:word
endfunction " }}}

function! s:get_zdict_window_id () " {{{
    let l:tabnr = tabpagenr()
    for winnr in range(1, tabpagewinnr(l:tabnr, '$'))
        if gettabwinvar(tabnr, winnr, 'id') is 'zdict'
            return winnr
        endif
    endfor
    return 0
endfunction " }}}

function! s:initialize_window () " {{{
    let l:winnr = s:get_zdict_window_id()
    if l:winnr == 0
        vnew
        let w:id = 'zdict'
    else
        execute 'silent '. l:winnr .'wincmd w'
        silent 1,$delete _
    endif
    execute "silent normal! \<C-w>L"
    vertical resize 50
    setlocal ft=zdict
endfunction " }}}

function! s:query (word) " {{{
    let l:trimed_word = substitute(a:word, '\v[ \n\r]*$', '', '')
    let l:trimed_word = substitute(l:trimed_word, '\v[\n\r]', ' ', 'g')
    let l:statsline_word = substitute(l:trimed_word, '\v[ \n\r]', '\\ ', 'g')
    execute 'setlocal statusline=[zdict]\ '. l:statsline_word
    execute "silent r !zdict '". l:trimed_word ."'"
endfunction " }}}

function! s:post_query () " {{{
    call s:normalize_color_code()
    silent 1,1delete _
    execute "normal! \<C-w>\<C-w>"
endfunction " }}}

function! s:normalize_color_code () " {{{
    " Dark colors
    silent! %s/\v\[30m/⣐/g " black    (U+28D0)
    silent! %s/\v\[31m/⣑/g " red
    silent! %s/\v\[32m/⣒/g " green
    silent! %s/\v\[33m/⣓/g " yellow
    silent! %s/\v\[34m/⣔/g " navy
    silent! %s/\v\[35m/⣕/g " magenta
    silent! %s/\v\[36m/⣖/g " cyan
    silent! %s/\v\[37m/⣗/g " white    (U+28D7)

    " Light colors
    silent! %s/\v\[(1;30|30;1)m/⣀/g " U+28C0
    silent! %s/\v\[(1;31|31;1)m/⣁/g
    silent! %s/\v\[(1;32|32;1)m/⣂/g
    silent! %s/\v\[(1;33|33;1)m/⣃/g
    silent! %s/\v\[(1;34|34;1)m/⣄/g
    silent! %s/\v\[(1;35|35;1)m/⣅/g
    silent! %s/\v\[(1;36|36;1)m/⣆/g
    silent! %s/\v\[(1;37|37;1)m/⣇/g " U+28C7

    " End color escape sequence
    silent! %s/\v\[0?m/⣗/g

    " Optimization
    " remove empty color string
    silent! %s/\v\[..;\[;//g

    " remove redundent closing color code
    silent! %s/\v\[;([^]*)\[;/[;\1/g

    " remove useless closing color code on line start
    silent! %s/\v^([^]*)\[;/\1/g
endfunction " }}}

function! s:destroy_window () " {{{
    let l:winnr = s:get_zdict_window_id()
    if l:winnr != 0
        execute 'silent '. l:winnr .'wincmd w'
        q
    endif
endfunction " }}}

function! zdict#close_zdict_window () " {{{
    call s:destroy_window()
    redraw!
endfunction " }}}

function! zdict#query ()
    if !executable('zdict')
        echo 'zdict is not installed, please install it first!'
        echo 'Please refer to https://github.com/M157q/zdict.git'
        return
    endif
    let l:word = s:get_word()
    if s:get_zdict_window_id() == 0 || l:word !=? s:last_queried_word
        echo 'Querying ...'
        call s:initialize_window()
        call s:query(l:word)
        call s:post_query()
    else
        call zdict#close_zdict_window()
    endif
    let s:last_queried_word = l:word
endfunction

function! zdict#query_visual () range
    normal! gv
    call zdict#query()
endfunction
