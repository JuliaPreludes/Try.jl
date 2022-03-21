    Err(value::E) -> err::Err{E}
    Err{E}(value) -> err::Err{E}

Indicate that `value` is a "failure" in a sense defined by the API returning this value.

See: [`iserr`](@ref), [`unwrap_err`](@ref)

# Examples
```julia
julia> using Try

julia> result = Err(1)
Try.Err: 1

julia> Try.unwrap_err(result)
1
```
