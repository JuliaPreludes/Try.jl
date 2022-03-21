    Try.@function name

Create a function that can be called without causing a `MethodError`.

See also: [`istryable`](@ref).

# Examples

```julia
julia> using Try

julia> Try.@function fn;

julia> fn
fn (tryable function with 1 method)

julia> fn(1)
Try.Err: Not Implemented: fn(1)
```
