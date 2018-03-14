Path do(
    absoluteIfNeeded := method(path,
        if(isURL(path), path, absolute(path))
    )

    isURL := method(path,
        path containsSeq("://")
    )
)
