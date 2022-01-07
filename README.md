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

Julia is a dynamic language with a compiler that can aggressively optimize away
the dynamism to get the performance comparable static languages.  As such, many
successful features of Julia provide the usability of a dynamic language while
paying attentions to the optimizability of the composed code.  However, native
`throw`/`catch`-based exception is not optimized aggressively and existing
"static" solutions do not support idiomatic high-level style of programming.
Try.jl explores [an alternative solution](https://xkcd.com/927/) embracing the
dynamism of Julia while restricting the underlying code as much as possible to
the form that the compiler can optimize away.

### Dynamic returned value types for maximizing optimizability

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
is easy to control the result of type inference.  However, this forces the user
to manually compute the type of the untaken paths.  This is tedious and
sometimes simply impossible.  This is also not idiomatic Julia code which
typically delegates output type computation to the compiler.  Futhermore, the
benefit of type-stabilization is at the cost of loosing the opportunity for the
compiler to eliminate the success and/or failure branches.  A similar
optimization can still happen in principle with the concrete `struct` approach
with the combination of (post-inference) inlining, scalar replacement of
aggregate, and dead code elimination.  However, since type inference is the main
driving force in the inter-procedural analysis and optimization in the Julia
compiler, `Union` return type is likely to continue to be the most effective way
to communicate the intent of the code with the compiler (e.g., if a function
call always succeeds, always return an `Ok{T}`).

(That said, Try.jl also contains supports for concretely-typed returned value
when `Union` is not appropriate. This is for experimenting if such a manual
"type-instability-hiding" is a viable approach at a large scale and if providing
a uniform API is possible.)

### Debuggable error handling

A potential usability issue for using the `Result` type is that the detailed
context of the error is lost by the time the user received an error.  This makes
debugging Julia programs hard compared to simply `throw`ing the exception.  To
mitigate this problem, Try.jl provides an *error trace* mechanism for recording
the backtrace of the error.  This can be toggled using `Try.enable_errortrace()`
at the run-time.  This is inspired by Zig's [Error Return
Traces](https://ziglang.org/documentation/master/#Error-Return-Traces).

### EAFP and traits

Try.jl exposes a limited set of "verbs" based on Julia `Base` such as
`Try.take!`.  These functions have a catch-all default definition that returns
an error value of type `Err{NotImplementedError}`.  This let us use these
functions in the ["Easier to ask for forgiveness than permission"
(EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) manner because they
can be called without getting the run-time `MethodError` exception.
Importantly, the EAFP approach does not have the problem of the trait-based
feature detection where the implementer must ensure that declared trait (e.g.,
`HasLength`) is compatible with the actual definition (e.g., `length`).  With
the EAFP approach, *the feature is declared automatically by defining of the
method providing it* (e.g., `Try.length`).  Thus, by construction, it is hard to
make the feature declaration and definition out-of-sync.  Of course, this
approach works only for effect-free or "redo-able" functions.  To check if a
sequence of destructive operations is possible, the trait-based approach is
perhaps unavoidable.  Therefore, these approaches are complementary.  The
EAFP-based strategy is useful for reducing the complexity of library extension
interface.

(Implementation details: In Try.jl, each "EAFP-compatible" function is declared
with `Try.@function f` instead of `function f end`.  It is defined as an
instance of a subtype of `Tryable <: Function` and not as an instance of a
"direct" subtype of `Function`.)
