Try.Ok(::Type{T}) where {T} = Try.Ok{Type{T}}(T)

Try.Err(value) = Try.Err(value, maybe_backtrace())
Try.Err{E}(value) where {E} = Try.Err{E}(value, maybe_backtrace())

Try.unwrap(ok::Ok) = ok.value
Try.unwrap(err::Err) = _throw(err)

Try.unwrap_err(ok::Ok) = throw(Try.IsOkError(ok))
Try.unwrap_err(err::Err) = err.value

function _throw(err::Err)
    if err.backtrace === nothing
        throw(err.value)
    else
        throw(ErrorTrace(err.value, err.backtrace))
    end
end

function Try.IsOkError(ok)
    if Try.iserr(ok)
        error("unexpected error value: ", ok)
    end
    return _IsOkError(ok)
end

Base.convert(::Type{Ok{T}}, ok::Ok) where {T} = Ok{T}(ok.value)
Base.convert(::Type{Err{E}}, err::Err) where {E} = Err{E}(err.value)
# An interesting approach may be to simply throw the `err.value` if it is not a
# subtype of `E`.  It makes the error value propagation pretty close to the
# chain-of-custody Julep.  Maybe this should be done only when the destination
# type is `AbstractResult{<:Any,E′}` s.t. `!(err.value isa E′)`.

Try.oktype(::Type{R}) where {T,R<:AbstractResult{T}} = T
Try.oktype(result::AbstractResult) = Try.oktype(typeof(result))

Try.errtype(::Type{R}) where {E,R<:AbstractResult{<:Any,E}} = E
Try.errtype(result::AbstractResult) = Try.errtype(typeof(result))

Try.isok(::Ok) = true
Try.isok(::Err) = false

Try.iserr(::Ok) = false
Try.iserr(::Err) = true
