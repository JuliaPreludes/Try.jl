const DynamicResult{T,E} = Union{Ok{T},Err{E}}

function _ConcreteResult end

struct ConcreteResult{T,E} <: AbstractResult{T,E}
    value::DynamicResult{T,E}

    global _ConcreteResult(::Type{T}, ::Type{E}, value) where {T,E} = new{T,E}(value)
end

const Result{T,E} = Union{ConcreteResult{<:T,<:E},DynamicResult{<:T,<:E}}
