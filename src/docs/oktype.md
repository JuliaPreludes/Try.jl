    Try.oktype(::Type{Ok{T}}) -> T::Type
    Try.oktype(::Ok{T}) -> T::Type

Get the type of the value stored in an `Ok`.

# Examples
```julia
julia> using Try

julia> Try.oktype(Ok{Symbol})
Symbol

julia> Try.oktype(Ok(:a))
Symbol
```
