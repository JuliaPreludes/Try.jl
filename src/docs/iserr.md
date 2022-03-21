    Try.iserr(::Err) -> true
    Try.iserr(::Ok) -> false

Return `true` on an [`Err`](@ref); return `false` on an [`Ok`](@ref).

# Examples
```julia
julia> using Try

julia> Try.iserr(Try.Err(1))
true

julia> Try.iserr(Try.Ok(1))
false
```
