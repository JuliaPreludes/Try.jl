    Try.@function name

Create a function that can be called without causing a `MethodError`.

Note that [`Ok`](@ref) and [`Err`](@ref) values can be used in arbitrary functions.
`Try.@function fn` is simply a shorthand for defining a fallback implementation

    fn(args...; kwargs...) = Err(Try.NotImplementedError(fn, args, values(kwargs)))

(and auxiliary methods like [`Try.istryable`](@ref)) to help the ["Easier to ask for
forgiveness than permission" (EAFP)](https://github.com/tkf/Try.jl#eafp) approach.

See also: [`Try.istryable`](@ref).

# Examples

```julia
julia> using Try

julia> Try.@function fn;

julia> fn
fn (tryable function with 1 method)

julia> fn(1)
Try.Err: Not Implemented: fn(1)
```
