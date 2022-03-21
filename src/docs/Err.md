    Err(value::E) -> err::Err{E}
    Err{E}(value) -> err::Err{E}

Indicate `value` a "failure" in a sense defined by the API returning this value.

See: [`iserr`](@ref), [`unwrap_err`](@ref)

# Examples
```julia
julia> using Try

julia> result = Try.Err(1)
Try.Err: 1

julia> Try.unwrap_err(result)
1
```
