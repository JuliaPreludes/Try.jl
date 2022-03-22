    Try.istryable(callable::Any) -> bool::Bool

Check if a `callable` can be called without causing a `MethodError`.

See also: [`@tryable`](@ref).

# Examples

```julia
julia> using TryExperimental: @tryable, istryable

julia> @tryable fn;

julia> istryable(fn)
true

julia> istryable(identity)
false
```

