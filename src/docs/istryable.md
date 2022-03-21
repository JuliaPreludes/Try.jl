    Try.istryable(callable::Any) -> bool::Bool

Check if a `callable` can be called without causing a `MethodError`.

See also: [`Try.@function`](@ref).

# Examples

```julia
julia> using Try

julia> Try.@function fn;

julia> Try.istryable(fn)
true

julia> Try.istryable(identity)
false
```

