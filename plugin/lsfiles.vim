
let g:loaded_lsfiles = 1

command! -bang -nargs=0  LsFiles     :call lsfiles#exec(<q-bang>, <q-args>)

