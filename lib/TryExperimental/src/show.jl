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

# TODO: simplify arguments when they are too long
function Base.showerror(io::IO, ex::NotImplementedError)
    print(io, "Not Implemented: ")
    show(io, ex.f)
    print(io, '(')
    let isfirst = true
        for a in ex.args
            if isfirst
                isfirst = false
            else
                print(io, ", ")
            end
            show(IOContext(io, :compact => true, :limit => true), a)
        end
    end
    let isfirst = true
        for (k, v) in pairs(ex.kwargs)
            if isfirst
                isfirst = false
                print(io, "; ")
            else
                print(io, ", ")
            end
            print(io, k, " = ")
            show(IOContext(io, :compact => true, :limit => true), v)
        end
    end
    print(io, ')')
end
