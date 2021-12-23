Try.Ok(::Type{T}) where {T} = Try.Ok{Type{T}}(T)

Try.Err(value) = Try.Err(value, maybe_backtrace())
Try.Err{E}(value) where {E<:Exception} = Try.Err{E}(value, maybe_backtrace())

Try.unwrap(result::ConcreteResult) = Try.unwrap(result.value)
Try.unwrap(ok::Ok) = ok.value
Try.unwrap(err::Err) = Try.throw(err)

Try.unwrap_err(result::ConcreteResult) = Try.unwrap_err(result.value)
Try.unwrap_err(ok::Ok) = throw(Try.IsOkError(ok))
Try.unwrap_err(err::Err) = err.value

Try.throw(err::ConcreteErr) = Try.throw(err.value)
function Try.throw(err::Err)
    if err.backtrace === nothing
        throw(err.value)
    else
        throw(ErrorTrace(err.value, err.backtrace))
    end
end

Base.convert(::Type{Ok{T}}, ok::Ok) where {T} = Ok{T}(ok.value)
Base.convert(::Type{Err{E}}, err::Err) where {E} = Err{E}(err.value)

function Base.convert(
    ::Type{ConcreteResult{T,E}},
    result::ConcreteResult{T′,E′},
) where {T,E,T′<:T,E′<:E}
    value = result.value
    if value isa Ok
        return ConcreteResult{T,E}(Ok{T}(value.value))
    else
        return ConcreteResult{T,E}(Err{E}(value.value))
    end
end

Base.convert(::Type{ConcreteResult{T,E}}, result::ConcreteOk) where {T,E} =
    ConcreteResult{T,E}(convert(Ok{T}, value.value))

Base.convert(::Type{ConcreteResult{T,E}}, result::ConcreteErr) where {T,E} =
    ConcreteResult{T,E}(convert(Err{E}, value.value))

Try.ConcreteOk{T}(value) where {T} = Try.ConcreteOk{T}(Ok{T}(value))
Try.ConcreteErr{E}(value) where {E} = Try.ConcreteErr{E}(Err{E}(value))
Try.oktype(::Type{R}) where {T,R<:AbstractResult{T}} = T
Try.oktype(result::AbstractResult) = Try.oktype(typeof(result))

Try.errtype(::Type{R}) where {E,R<:AbstractResult{<:Any,E}} = E
Try.errtype(result::AbstractResult) = Try.errtype(typeof(result))

Try.ok(result::Ok) = Some{Try.oktype(result)}(result.value)
Try.ok(::Err) = nothing
function Try.ok(result::ConcreteResult)
    value = result.value
    if value isa Ok
        return Try.ok(value)
    else
        return nothing
    end
end

Try.err(::Ok) = nothing
Try.err(result::Err) = Some{Try.errtype(result)}(result.value)
function Try.err(result::ConcreteResult)
    value = result.value
    if value isa Err
        return Try.err(value)
    else
        return nothing
    end
end

Try.isok(::Ok) = true
Try.isok(::Err) = false
Try.isok(result::ConcreteResult) = result.value isa Ok

Try.iserr(::Ok) = false
Try.iserr(::Err) = true
Try.iserr(result::ConcreteResult) = result.value isa Err
