include_backtrace() = false

function Try.enable_errortrace()
    old = include_backtrace()
    @eval include_backtrace() = true
    return old
end

function Try.disable_errortrace()
    old = include_backtrace()
    @eval include_backtrace() = false
    return old
end

function Try.enable_errortrace(yes::Bool)
    include_backtrace() == yes && return yes
    return yes ? Try.enable_errortrace() : Try.disable_errortrace()
end

maybe_backtrace() = include_backtrace() ? backtrace() : nothing

function common_suffix(bt, here = backtrace())
    a = lastindex(bt)
    b = lastindex(here)
    while true
        a < firstindex(bt) && return a  # unreachable?
        b < firstindex(bt) && break
        bt[a] != here[b] && break
        a -= 1
        b -= 1
    end
    return a
end

function simplify_backtrace_impl(bt)
    a = common_suffix(bt)
    no_common_suffix = a == lastindex(bt)
    bt = Base.process_backtrace(bt[1:a])

    j = lastindex(bt)
    if no_common_suffix
        # No common suffix. Evaluated in REPL's display?
        fr, = bt[end]
        if fr.func === :_start && basename(string(fr.file)) == "client.jl"
            j = findlast(((fr, _),) -> !fr.from_c && fr.func === :eval, bt)
            j = max(firstindex(bt), j - 1)
        end
    end

    i = firstindex(bt)
    if bt[i][1].func === :maybe_backtrace
        i += 1
    end
    if bt[i][1].func === :Err
        i += 1
    end

    return bt[i:j]
end

function simplify_backtrace(bt)
    try
        return simplify_backtrace_impl(bt)
    catch err
        @error(
            "Fail to simplify backtrace. Fallback to plain backtrace.",
            exception = (err, catch_backtrace()),
            maxlog = 5,
        )
        return bt
    end
end

struct ErrorTrace <: Exception
    exception::Exception
    backtrace::typeof(Base.backtrace())
end

function Base.showerror(io::IO, errtrace::ErrorTrace)
    print(io, "Original Error: ")
    showerror(io, errtrace.exception)
    println(io)

    # TODO: remove common prefix?
    buffer = IOBuffer()
    Base.show_backtrace(IOContext(buffer, io), simplify_backtrace(errtrace.backtrace))
    seekstart(buffer)
    println(io, "┌ Original: stacktrace")
    for ln in eachline(buffer)
        print(io, "│  ")
        println(io, ln)
    end
    println(io, "└")
end

function Base.show(io::IO, errtrace::ErrorTrace)
    Base.show(io, ErrorTrace)
    print(io, '(')
    Base.show(io, errtrace.exception)
    print(io, ", …)")
end
