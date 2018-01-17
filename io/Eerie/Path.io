Regex

Path do(
    absoluteIfNeeded := method(path,
        if(isURL(path), path, absolute(path))
    )

    isURL := method(path,
        regex := "[a-z]+\:\/\/" asRegex caseless
        path hasMatchOfRegex(regex)
    )
)
