    TryExperimental.valueof(branch) -> value
    TryExperimental.valueof(branch::Continue{Ok{T}}) -> value::T
    TryExperimental.valueof(branch::Break{Err{T}}) -> value::T
    TryExperimental.valueof(branch::Continue{Some{T}}) -> value::T
    TryExperimental.valueof(branch::Break{Nothing}) -> nothing
