    TryExperimental.ConcreteResult{T,E}

Similar to `Union{Ok{T},Err{E}}` but it is a concrete type.

# Examples
```julia
julia> using Try

julia> using TryExperimental: ConcreteResult

julia> convert(ConcreteResult{Symbol,Union{BoundsError,DomainError}}, Ok(:a))
TryExperimental.ConcreteResult (Ok): :a
```
