function Base.show(io::IO, ::MIME"text/plain", ok::Ok)
    printstyled(io, "Try.Ok"; color = :green, bold = true)
    print(io, ": ")
    show(io, MIME"text/plain"(), Try.unwrap(ok))
end

function Base.show(io::IO, ::MIME"text/plain", err::Err)
    printstyled(io, "Try.Err"; color = :red, bold = true)
    print(io, ": ")
    ex = Try.unwrap_err(err)
    backtrace = err.backtrace
    if backtrace === nothing
        showerror(io, ex)
    else
        showerror(io, ex, err.backtrace)
    end
end
