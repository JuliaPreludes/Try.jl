function Base.show(io::IO, ::MIME"text/plain", result::ConcreteResult)
    print(io, "TryExperimental.ConcreteResult ")
    value = result.value
    if value isa Ok
        printstyled(io, "(Ok)"; color = :green, bold = true)
        print(io, ": ")
        show(io, MIME"text/plain"(), Try.unwrap(value))
    else
        printstyled(io, "(Err)"; color = :red, bold = true)
        print(io, ": ")
        ex = Try.unwrap_err(err)
        backtrace = err.backtrace
        if backtrace === nothing
            showerror(io, ex)
        else
            showerror(io, ex, simplify_backtrace(err.backtrace))
        end
    end
end
