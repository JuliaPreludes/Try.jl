    Try.errtype(::Type{Err{E}}) -> E::Type
    Try.errtype(::Err{E}) -> E::Type

Get the type of the value stored in an `Err`.

# Examples
```julia
julia> using Try

julia> Try.errtype(Err{Symbol})
Symbol

julia> Try.errtype(Err(:a))
Symbol
```
