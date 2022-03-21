    Try.unwrap(Ok(value)) -> value
    Try.unwrap(::Err)  # throws

Unwrap an [`Ok`](@ref) value; throws on an [`Err`](@ref).

To obtain a stack trace to the place `Err` is constructed (and not where `unwrap` is
called), use [`Try.enable_errortrace`](@ref).

# Examples
```julia
julia> using Try

julia> Try.unwrap(Try.Ok(1))
1
```
