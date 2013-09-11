let s:mapping = {
            \   'cpp': {
            \     'header': [".hpp", ".hh", ".h"],
            \     'src': [".cpp", ".c", ".cc"],
            \     'test': ["_tests.cpp", "_test.cpp"]
            \   },
            \   'c': {
            \     'header': [".hh", ".h"],
            \     'src': [".c", ".cc"],
            \     'test': ["_tests.c", "_test.c"]
            \   }
            \ }

function! Levenshtein_distance(str1, str2)
    let str1_chars = split(a:str1, '\zs') | let str1_len = len(str1_chars)
    let str2_chars = split(a:str2, '\zs') | let str2_len = len(str2_chars)

    let matrix = []
    let y = 0
    while y <= str2_len
        let row = range(0, str1_len)
        let row[0] = y
        call add(matrix, row)
        let y += 1
    endwhile

    let y = 1
    while y <= str2_len
        let x = 1
        while x <= str1_len
            let cost = !(str1_chars[x - 1] ==# str2_chars[y - 1])
            let matrix[y][x] = min([
                        \ matrix[y][x - 1] + 1,
                        \ matrix[y - 1][x] + 1,
                        \ matrix[y - 1][x - 1] + cost,
                        \ ])
            let x += 1
        endwhile
        let y += 1
    endwhile

    return matrix[str2_len][str1_len]
endfunction

"key, precmd
fun! TagSwitch(...)
    let argKey = ""
    let precmd = ""

    "echom "got args" len(a:000)
    for qarg in a:000
        if qarg =~ "^\".*\"$"
            " Strip quotes
            let qarg = qarg[1:-2]
        endif
        if qarg == ""
            continue
        elseif index(["src", "header", "test"], qarg) >= 0
            "echom "  argkey" qarg
            let argKey = qarg
        else
            "echom "  precmd '" . qarg . "'"
            let precmd = qarg
        endif
    endfor

    "echom "argKey" argKey
    "echom "precmd" precmd

    let fullFromName = expand("%:p")
    let toName = expand("%:t:r")
    let toName = substitute(toName, "_tests\\?$", "", "")

    for ft in split(&ft, '\.')
        let realKey = argKey
        if realKey == ""
            let fileExt = "." . expand("%:e")
            "echom "ext" fileExt ft
            for tryKey in [ "header", "src" ]
                if realKey != ""
                    break
                endif
                "echom "tryKey" tryKey
                for ext in s:mapping[ft][tryKey]
                    if realKey != ""
                        break
                    endif
                    "echom "tryExt" ext
                    if ext == fileExt
                        if tryKey == "header"
                            let realKey = "src"
                        else
                            let realKey = "header"
                        endif
                    endif
                endfor
            endfor
        endif
        if realKey == ""
            "echom "unable to find a type for file"
            continue
        endif

        let extensions = s:mapping[ft][realKey]
        for ext in extensions
            "echom "try" ft realKey ext
            let headerSearch = "^" . toName . ext . "$"
            let best = ""
            let best_dist = -1
            for header in taglist(headerSearch)
                if header["kind"] == "F"
                    let dist = Levenshtein_distance(header["filename"], fullFromName)
                    if dist < best_dist || best_dist == -1
                        let best_dist  = dist
                        let best = header["filename"]
                    endif
                endif
            endfor
            if strlen(best) != 0
                if strlen(precmd) != 0
                    execute precmd
                endif
                execute "edit " . fnameescape(header["filename"])
                return
            endif
        endfor
    endfor
    echoerr "Unable to find tag matching request" toName
endfunc

function! TagSwitchAbove(...)
    call call("TagSwitch", a:000 + ['let cursb=&sb | set nosb | split | if cursb | set sb | endif'])
endfunc
function! TagSwitchBelow(...)
    call call("TagSwitch", a:000 + ['let cursb=&sb | set nosb | split | wincmd j | if cursb | set sb | endif'])
endfunc
function! TagSwitchLeft(...)
    call call("TagSwitch", a:000 + ['let curspr=&spr | set nospr | vsplit | if curspr | set spr | endif'])
endfunc
function! TagSwitchRight(...)
    call call("TagSwitch", a:000 + ['let curspr=&spr | set nospr | vsplit | wincmd l | if curspr | set spr | endif'])
endfunc

" TODO: add -bang to create a file in the "right" spot
"       - if there is are hpp/cpp files next to this one, find their pairs and
"       prompt for location
"       - else, look through file tags, and find closest locations
" TODO: prompt if multiple matches, and remember choice
com! -nargs=? TagSwitchHere call TagSwitch(<f-args>)
com! -nargs=? TagSwitchAbove call TagSwitchAbove(<f-args>)
com! -nargs=? TagSwitchBelow call TagSwitchBelow(<f-args>)
com! -nargs=? TagSwitchRight call TagSwitchRight(<f-args>)
com! -nargs=? TagSwitchLeft call TagSwitchLeft(<f-args>)

function! MapTS(lead, direction, cmd, arg)
    execute "nmap" a:lead . a:direction ":TagSwitch" . a:cmd  a:arg . "<CR>"
    "echo "execute nmap" a:lead . direction ":" . cmd  a:firstArg . "<CR>"
endfun

function! MapSplits(arg, lead, extra)
    for direction in ["h", "j", "k", "l"] + a:extra
        let cmd = "Here"
        if direction == "h"
            let cmd = "Left"
        elseif direction == "j"
            let cmd = "Below"
        elseif direction == "k"
            let cmd = "Above"
        elseif direction == "l"
            let cmd = "Right"
        endif
        call MapTS(a:lead, direction, cmd, a:arg)
    endfor
endfun

" ,f{hjklf} -> pick header/source
" ,ft{hjklft} -> go to tests
" ,fs{hjklfs} -> go to source
" ,fi{hjklfi} -> go to header ([i]nclude)

function! MapTagSwitch(lead, ...)
    call MapSplits("", a:lead, ["f"] + a:000)
    call MapSplits("src", a:lead . "s", ["s", "f", ""] + a:000)
    call MapSplits("header", a:lead . "t", ["i", "f", ""] + a:000)
    call MapSplits("test", a:lead . "t", ["t", "f", ""] + a:000)
endfunc

call MapTagSwitch(",f", "f")
