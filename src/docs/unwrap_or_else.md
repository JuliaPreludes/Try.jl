    Try.unwrap_or_else(_, Ok(value)) -> value
    Try.unwrap_or_else(f, Err(x))  -> f(x)

Unwrap an [`Ok`](@ref) value or compute a result from the value wrapped in [`Err`](@ref).

# Examples
```julia
julia> using Try

julia> Try.unwrap_or_else(length, Try.Ok(1))
1

julia> Try.unwrap_or_else(length, Try.Err("four"))
4
```
