
let g:loaded_lsfiles = 1

command! -bang -nargs=*  LsFiles     :call lsfiles#exec(<q-bang>, <q-args>)

