
let g:loaded_lsfiles = 1

command! -nargs=*  LsFiles     :call lsfiles#exec(<q-args>)

