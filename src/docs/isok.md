    Try.isok(::Ok) -> true
    Try.isok(::Err) -> false

Return `true` on an [`Ok`](@ref); return `false` on an [`Err`](@ref).

# Examples
```julia
julia> using Try

julia> Try.isok(Try.Ok(1))
true

julia> Try.isok(Try.Err(1))
false
```
