
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

fun! ToHeader()
    call DoSwitch("header")
endfun

fun! ToSource()
    call DoSwitch("src")
endfun

fun! ToTest()
    call DoSwitch("test")
endfun

fun! DoSwitch(key)
    let toName = expand("%:t:r")
    for ft in split(&ft, '\.')
        let extensions = s:mapping[ft][a:key]
        for ext in extensions
            let headerSearch = "^" . toName . ext . "$"
            for header in taglist(headerSearch)
                if header["kind"] == "F"
                    exe "edit " . header["filename"]
                endif
            endfor
        endfor
    endfor
endfun
