
function! lsfiles#exec(q_bang, q_args) abort
    let tstatus = term_getstatus(bufnr())
    if (tstatus != 'finished') && !empty(tstatus)
        call popup_notification('could not open on running terminal buffer', s:lsfiles_notification_opt)
    elseif !empty(getcmdwintype())
        call popup_notification('could not open on command-line window', s:lsfiles_notification_opt)
    elseif &modified
        call popup_notification('could not open on modified buffer', s:lsfiles_notification_opt)
    else
        let saved = getcwd()
        try
            let flag = v:false
            for dir in [expand('%:p:h'), fnamemodify(resolve(expand('%:p')), ':h'), getcwd()]
                if isdirectory(dir)
                    cd `=dir`
                    let toplevel = s:get_toplevel()
                    if isdirectory(toplevel)
                        let flag = v:true
                        cd `=toplevel`
                        if !has_key(s:lsfiles_caches, toplevel) || (a:q_bang == '!')
                            let s:lsfiles_caches[toplevel] = systemlist('git ls-files ' .. a:q_args)
                        endif
                        if empty(s:lsfiles_caches[toplevel])
                            call popup_notification('no such file', s:lsfiles_notification_opt)
                        else
                            let winid = s:PopupWinFinder.open(s:lsfiles_caches[toplevel], s:lsfiles_options)
                            call setwinvar(winid, 'toplevel', toplevel)
                        endif
                        break
                    endif
                endif
            endfor
            if !flag
                call popup_notification('not a git repository', s:lsfiles_notification_opt)
            endif
        finally
            cd `=saved`
        endtry
    endif
endfunction

function! s:lsfiles_callback(winid, key) abort
    if 0 < a:key
        let lnum = a:key
        let path = getbufline(winbufnr(a:winid), lnum, lnum)[0]
        if s:NO_MATCHES != path
            let toplevel = getwinvar(a:winid, 'toplevel')
            let fullpath = s:fullpath(toplevel .. '/' .. path)
            let matches = filter(getbufinfo(), {i,x -> s:fullpath(x.name) == fullpath })
            if !empty(matches)
                execute printf('%s %d', 'buffer', matches[0]['bufnr'])
            else
                execute printf('%s %s', 'edit', fnameescape(fullpath))
            endif
        endif
    endif
endfunction

function! s:fullpath(path) abort
    return fnamemodify(resolve(a:path), ':p:gs?\\?/?')
endfunction

function! s:get_toplevel() abort
    for dir in [expand('%:p:h'), fnamemodify(resolve(expand('%:p')), ':h'), getcwd()]
        if isdirectory(dir)
            let xs = split(dir, '[\/]')
            while !empty(xs)
                if isdirectory(join(xs + ['.git'], '/'))
                    return s:fullpath(join(xs, '/'))
                endif
                call remove(xs, -1)
            endwhile
        endif
    endfor
    return ''
endfunction


" :Vitalize . --name=lsfiles +PopupWinFinder
let s:PopupWinFinder = vital#lsfiles#import('PopupWinFinder')

let s:NO_MATCHES = 'no matches'

let s:lsfiles_caches = get(s:, 'lsfiles_caches', {})
let s:lsfiles_title = 'lsfiles'
let s:lsfiles_notification_opt = {
    \   'title' : s:lsfiles_title,
    \   'pos' : 'center',
    \   'padding' : [1,3,1,3],
    \ }
let s:lsfiles_options = {
    \   'title' : s:lsfiles_title,
    \   'callback' : function('s:lsfiles_callback'),
    \ }

