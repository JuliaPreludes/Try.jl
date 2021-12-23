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
    Base.show_backtrace(IOContext(buffer, io), errtrace.backtrace)
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
