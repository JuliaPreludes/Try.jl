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

julia> result = Try.getindex(Dict(:a => 111), :a)
Try.Ok: 111

julia> Try.isok(result)
true

julia> Try.unwrap(result)
111

julia> result = Try.getindex(Dict(:a => 111), :b)
Try.Err: KeyError: key :b not found

julia> Try.iserr(result)
true

julia> Try.unwrap_err(result)
KeyError(:b)
```

### Error trace

Consider an example where an error "bubbles up" from a deep stack of function
calls:

```JULIA
julia> using Try

julia> f1(x) = x ? Ok(nothing) : Err(KeyError(:b));

julia> f2(x) = f1(x);

julia> f3(x) = f2(x);
```

Since Try.jl represents an error simply as a Julia value, there is no
information on the source this error:

```JULIA
julia> f3(false)
Try.Err: KeyError: key :b not found
```

We can enable the stacktrace recording of the error by calling 
`Try.enable_errortrace()`.

```JULIA
julia> Try.enable_errortrace();

julia> y = f3(false)
Try.Err: KeyError: key :b not found
Stacktrace:
 [1] f1
   @ ./REPL[2]:1 [inlined]
 [2] f2
   @ ./REPL[3]:1 [inlined]
 [3] f3(x::Bool)
   @ Main ./REPL[4]:1
 [4] top-level scope
   @ REPL[7]:1

julia> Try.disable_errortrace();
```

Note that `f3` didn't throw an exception. It returned a value of type `Err`:

```JULIA
julia> Try.iserr(y)
true

julia> Try.unwrap_err(y)
KeyError(:b)
```

That is to say, the stacktrace is simply attached as "metadata" and
`Try.enable_errortrace()` does not alter how `Err` values behave.

**Limitation/implementation details**: To eliminate the cost of stacktrace
capturing when it is not used, `Try.enable_errortrace()` is implemented using
method invalidation. Thus, error trace cannot be enabled for `Task`s that have
been already started.

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
concretely typed `struct` type.  This is essential for idiomatic clean
high-level Julia code that avoids computing output type manually.  However, all
previous attempts in this space (such as
[ErrorTypes.jl](https://github.com/jakobnissen/ErrorTypes.jl),
[ResultTypes.jl](https://github.com/iamed2/ResultTypes.jl), and
[Expect.jl](https://github.com/KristofferC/Expect.jl)) use a `struct` type for
representing the result value (see
[`ErrorTypes.Result`](https://github.com/jakobnissen/ErrorTypes.jl/blob/c3a7d529716ebfa3ee956049f77f606b6c00700b/src/ErrorTypes.jl#L45-L47),
[`ResultTypes.Result`](https://github.com/iamed2/ResultTypes.jl/blob/42ebadf4d859964efa36ebccbeed3d5b65f3e9d9/src/ResultTypes.jl#L5-L8),
and
[`Expect.Expected`](https://github.com/KristofferC/Expect.jl/blob/6834049306c2b53c1666cbed504655e36b56e3b4/src/Expect.jl#L6-L9)).
Using a concretely typed `struct` as returned type has some benefits in that it
is easy to control the result of type inference.  However, this is at the cost
of losing the opportunity for the compiler to eliminate the success and/or
failure branches.  A similar optimization can happen in principle with the
concrete `struct` approach with some aggressive (post-inference) inlining,
scalar replacement of aggregate, and dead code elimination.  However, since type
inference is the main driving force in the inter-procedural analysis of the
Julia compiler, `Union` return type is likely to continue to be the most
effective way to communicate the intent of the code with the compiler (e.g., if
a function call always succeeds, return an `Ok{T}`).  (That said, Try.jl also
contains supports for concretely-typed returned value when `Union` is not
appropriate. This is for experimenting if such a manual "type-stabilization" is
a viable approach and if providing a seamless interop API is possible.)

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
can be called without getting the run-time `MethodError` exception.
Importantly, *the EAFP approach does not have the problem of the trait-based
feature detection* where the implementer must ensure that declared trait (e.g.,
`HasLength`) is compatible with the actual definition (e.g., `length`).  With
the EAFP approach, the feature is enabled simply by defining the method
providing the function (e.g., `Try.length`).  (Implementation details: In
Try.jl, such "EAFP-compatible" functions are declared using `Try.@function f`
instead of `function f end`.  They are defined as instances of `Tryable <:
Function` and not as a direct instance of `Function`.)
