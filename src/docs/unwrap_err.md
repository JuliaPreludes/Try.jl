    Try.unwrap_err(Err(value)) -> value
    Try.unwrap_err(::Ok)  # throws

Unwrap an [`Err`](@ref) value; throws on an [`Ok`](@ref).

# Examples
```julia
julia> using Try

julia> Try.unwrap_err(Try.Err(1))
1
```
