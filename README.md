# Try.jl: zero-overhead and debuggable error handling

Features:

* Error handling as simple manipulations of *values*.
* Focus on *inferrability* and *optimizability* leveraging unique properties of
  the Julia language and compiler.
* *Error trace* for determining the source of errors, without `throw`.
* Facilitate the ["Easier to ask for forgiveness than permission"
  (EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) approach as a
  robust and minimalistic alternative to the trait-based feature detection.

## Examples

### Basic usage

```julia
julia> using Try

julia> result = Try.getindex(Dict(:a => 111), :a);

julia> Try.isok(result)
true

julia> Try.unwrap(result)
111

julia> result = Try.getindex(Dict(:a => 111), :b);

julia> Try.iserr(result)
true

julia> Try.unwrap_err(result)
KeyError(:b)
```

### EAFP

```julia
using Try

function try_map_prealloc(f, xs)
    T = Try.@return_err Try.eltype(xs)
    n = Try.@return_err Try.length(xs)
    ys = Vector{T}(undef, n)
    for (i, x) in zip(eachindex(ys), xs)
        ys[i] = f(x)
    end
    return Ok(ys)
end

mymap(f, xs) =
    try_map_prealloc(f, xs) |>
    Try.or_else() do _
        Ok(mapfoldl(f, push!, xs; init = []))
    end |>
    Try.unwrap

mymap(x -> x + 1, 1:3)

# output
3-element Vector{Int64}:
 2
 3
 4
```

```julia
mymap(x -> x + 1, (x for x in 1:5 if isodd(x)))

# output
3-element Vector{Any}:
 2
 4
 6
```

## Discussion

Try.jl provides an API inspired by Rust's `Result` type.  However, to fully
unlock the power of Julia, Try.jl uses the *small `Union` types* instead of a
concretely typed sum type.  Furthermore, it optionally supports concretely-typed
returned value when `Union` is not appropriate.

A potential usability issue for using the `Result` type is that the detailed
context of the error is lost by the time the user received an error.  This makes
debugging Julia programs hard compared to simply `throw`ing the exception.  To
solve this problem, Try.jl provides an *error trace* mechanism for recording the
backtrace of the error.  This can be toggled using `Try.enable_errortrace()` at
the run-time.  This is inspired by Zig's [Error Return
Traces](https://ziglang.org/documentation/master/#Error-Return-Traces).

Try.jl exposes a limited set of "verbs" based on Julia `Base` such as
`Try.take!`.  These functions have a catch-all default definition that returns
an error value `Err{NotImplementedError}`.  This let us use these functions in
the ["Easier to ask for forgiveness than permission"
(EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) manner because they
can be called without getting the run-time `MethodError` exception.  Such
functions can be defined using `Try.@function f` instead of `function f end`.
They are defined as instances of `Tryable <: Function` and not as a direct
instance of `Function`.
