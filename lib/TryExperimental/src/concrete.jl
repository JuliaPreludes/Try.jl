const DynamicResult{T,E} = Union{Ok{T},Err{E}}

function _ConcreteResult end

struct ConcreteResult{T,E} <: AbstractResult{T,E}
    value::DynamicResult{T,E}

    global _ConcreteResult(::Type{T}, ::Type{E}, value) where {T,E} = new{T,E}(value)
end

# Is this mixture of invariance and covariance good?
const Result{T,E} = Union{ConcreteResult{T,E},DynamicResult{<:T,<:E}}

Try.unwrap(result::ConcreteResult) = Try.unwrap(result.value)
Try.unwrap_err(result::ConcreteResult) = Try.unwrap_err(result.value)
Try.isok(result::ConcreteResult) = result.value isa Ok
Try.iserr(result::ConcreteResult) = result.value isa Err

_concrete(result::Ok) = _ConcreteResult(Try.oktype(result), Union{}, result)
_concrete(result::Err) = _ConcreteResult(Union{}, Try.errtype(result), result)

Base.convert(::Type{ConcreteResult{T,E}}, result::Ok) where {T,E} =
    _ConcreteResult(T, E, convert(Ok{T}, result))
Base.convert(::Type{ConcreteResult{T}}, result::Ok) where {T} =
    _ConcreteResult(T, Union{}, convert(Ok{T}, result))

Base.convert(::Type{ConcreteResult{T,E}}, result::Err) where {T,E} =
    _ConcreteResult(T, E, convert(Err{E}, result))
Base.convert(::Type{ConcreteResult{<:Any,E}}, result::Err) where {E} =
    _ConcreteResult(Union{}, E, convert(Err{E}, result))

function Base.convert(
    ::Type{ConcreteResult{T,E}},
    result::ConcreteResult{T′,E′},
) where {T,E,T′<:T,E′<:E}
    value = result.value
    if value isa Ok
        return _ConcreteResult(T, E, Ok{T}(value.value))
    else
        return _ConcreteResult(T, E, Err{E}(value.value))
    end
end
