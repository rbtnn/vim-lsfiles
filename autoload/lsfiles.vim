
function! lsfiles#exec(q_args) abort
    let tstatus = term_getstatus(bufnr())
    if (tstatus != 'finished') && !empty(tstatus)
        call popup_notification('could not open on running terminal buffer', s:lsfiles_notification_opt)
    elseif !empty(getcmdwintype())
        call popup_notification('could not open on command-line window', s:lsfiles_notification_opt)
    elseif &modified
        call popup_notification('could not open on modified buffer', s:lsfiles_notification_opt)
    else
        let lines = s:system('git ls-files')
        if empty(lines)
            call popup_notification('no such file or not a git repository', s:lsfiles_notification_opt)
        else
            let winid = popup_menu(lines, {})
            call win_execute(winid, 'setlocal number')
            call s:PopupWin.enhance_menufilter(winid, s:lsfiles_options)
        endif
    endif
endfunction

function! s:system(cmd)
    let saved = getcwd()
    let lines = []
    try
        let toplevel = trim(system('git rev-parse --show-toplevel'))
        if toplevel !~# '^fatal:'
            cd `=toplevel`
            for line in split(system(a:cmd), "\n", 1)
                let path = s:fullpath(toplevel .. '/' .. line)
                if filereadable(path)
                    let lines += [path]
                endif
            endfor
        endif
    finally
        cd `=saved`
    endtry
    return lines
endfunction

function! s:lsfiles_callback(winid, key) abort
    if 0 < a:key
        let lnum = a:key
        let path = getbufline(winbufnr(a:winid), lnum, lnum)[0]
        if s:NO_MATCHES != path
            let matches = filter(getbufinfo(), {i,x -> s:fullpath(x.name) == path })
            if !empty(matches)
                execute printf('%s %d', 'buffer', matches[0]['bufnr'])
            else
                execute printf('%s %s', 'edit', fnameescape(path))
            endif
        endif
    endif
endfunction

function! s:fullpath(path) abort
    return fnamemodify(resolve(a:path), ':p:gs?\\?/?')
endfunction



let s:PopupWin = vital#lsfiles#import('PopupWin')

let s:NO_MATCHES = 'no matches'

let s:lsfiles_title = 'lsfiles'
let s:lsfiles_notification_opt = {
    \   'title' : s:lsfiles_title,
    \   'pos' : 'center',
    \   'padding' : [1,3,1,3],
    \ }
let s:lsfiles_options = {
    \   'title' : s:lsfiles_title,
    \   'callback' : function('s:lsfiles_callback'),
    \   'no_matches' : s:NO_MATCHES,
    \ }
