    TryExperimental.@tryable name

Create a function that can be called without causing a `MethodError`.

Note that [`Ok`](@ref Try.Ok) and [`Err`](@ref Try.Err) values can be used in arbitrary
functions.  `@tryablefn` is simply a shorthand for defining a fallback implementation

```JULIA
fn(args...; kwargs...) = Err(NotImplementedError(fn, args, values(kwargs)))
```

(and auxiliary methods like [`istryable`](@ref TryExperimental.istryable)) to help the
["Easier to ask for forgiveness than permission" (EAFP)](https://github.com/JuliaPreludes/Try.jl#eafp)
approach.

See also: [`istryable`](@ref TryExperimental.istryable).

# Examples

```julia
julia> using TryExperimental: @tryable

julia> @tryable fn;

julia> fn
fn (tryable function with 1 method)

julia> fn(1)
Try.Err: Not Implemented: fn(1)
```
