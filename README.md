# Try.jl: zero-overhead and debuggable error handling

Features:

* Error handling as simple manipulations of *values*.
* Focus on *inferrability* and *optimizability* leveraging unique properties of
  the Julia language and compiler.
* *Error trace* for determining the source of errors, without `throw`.
* Facilitate the ["Easier to ask for forgiveness than permission"
  (EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) approach as a
  robust and minimalistic alternative to the trait-based feature detection.

For more explanation, see [Discussion](#discussion) below.

## Examples

### Basic usage

```julia
julia> import TryExperimental as Try
```

Try.jl-based API return either an `OK` value

```julia
julia> ok = Try.getindex(Dict(:a => 111), :a)
Try.Ok: 111
```

or an `Err` value:

```julia
julia> err = Try.getindex(Dict(:a => 111), :b)
Try.Err: KeyError: key :b not found
```

Together, these values are called *result* values.  Try.jl provides various
tools to deal with the result values such as predicate functions:

```julia
julia> Try.isok(ok)
true

julia> Try.iserr(err)
true
```

unwrapping function:

```julia
julia> Try.unwrap(ok)
111

julia> Try.unwrap_err(err)
KeyError(:b)
```

and more.

### Error trace

Consider an example where an error "bubbles up" from a deep stack of function
calls:

```JULIA
julia> import TryExperimental as Try

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

As explained in [EAFP and traits](#eafp-and-traits) below, the `Base`-like API
defined in `Try` namespace does not throw when the method is not defined.  For
example, `Try.eltype` and `Try.length` can be called on arbitrary objects (=
"asking for forgiveness") without checking if the method is defined (= "asking
for permission").

```julia
import TryExperimental as Try
using .Try

function try_map_prealloc(f, xs)
    T = Try.@return_err Try.eltype(xs)  # macro-based short-circuiting
    n = Try.@return_err Try.length(xs)
    ys = Vector{T}(undef, n)
    for (i, x) in zip(eachindex(ys), xs)
        ys[i] = f(x)
    end
    return Ok(ys)
end

mymap(f, xs) =
    try_map_prealloc(f, xs) |>
    Try.or_else() do _  # functional composition
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

### Success/failure path elimination

Function using Try.jl for error handling (such as `Try.first`) typically has a
return type of `Union{Ok,Err}`. Thus, the compiler can sometimes prove that
success or failure paths can never be taken:

```julia
julia> import TryExperimental as Try

julia> using .Try

julia> using InteractiveUtils

julia> @code_typed(Try.first((111, "two", :three)))[2]  # always succeeds for non empty tuples
Try.Ok{Int64}

julia> @code_typed(Try.first(()))[2]  # always fails for an empty tuple
Try.Err{BoundsError}

julia> @code_typed(Try.first(Int[]))[2]  # both are possible for an array
Union{Try.Ok{Int64}, Try.Err{BoundsError}}
```

### Constraining returnable errors

We can use the return type conversion `function f(...)::ReturnType ...  end` to
constrain possible error types. This is similar to the `throws` keyword in Java.

This can be used for ensuring that only the expected set of errors are returned
from Try.jl-based functions.  In particular, it may be useful for restricting
possible errors at an API boundary.  The idea is to separate "call API" `f` from
"overload API" `__f__` such that new methods are added to `__f__` and not to
`f`.  We can then wrap the overload API function by the call API function that
simply declare the return type:

```Julia
f(args...)::Result{Any,PossibleErrors} = __f__(args...)
```

(Using type assertion as in `__f__(args...)::Result{Any,PossibleErrors}` also
works in this case.)

Then, the API specification of `f` can include the overloading instruction
explaining that method of `__f__` should be defined and enumerate allowed set of
errors.

Here is an example of providing the call API `tryparse` with the overload API
`__tryparse__` wrapping `Base.tryparase`.  In this toy example, `__tryparse__`
can return `InvalidCharError()` or `EndOfBufferError()` as an error value:

```julia
import TryExperimental as Try
using .Try

struct InvalidCharError <: Exception end
struct EndOfBufferError <: Exception end

const ParseError = Union{InvalidCharError, EndOfBufferError}

tryparse(T, str)::Result{T,ParseError} = __tryparse__(T, str)

function __tryparse__(::Type{Int}, str::AbstractString)
    isempty(str) && return Err(EndOfBufferError())
    Ok(@something(Base.tryparse(Int, str), return Err(InvalidCharError())))
end

tryparse(Int, "111")

# output
Try.Ok: 111
```

```julia
tryparse(Int, "")

# output
Try.Err: EndOfBufferError()
```

```julia
tryparse(Int, "one")

# output
Try.Err: InvalidCharError()
```

Constraining errors can be useful for generic programming if it is desirable to
ensure that error handling is complete.  This pattern makes it easy to *report
invalid errors directly to the programmer* (see [When to `throw`? When to
`return`?](#when-to-throw-when-to-return)) while correctly implemented methods
do not incur any run-time overheads.

See also:
[julep: "chain of custody" error handling · Issue #7026 · JuliaLang/julia](https://github.com/JuliaLang/julia/issues/7026)

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
compiler to eliminate the success and/or failure branches (see [Success/failure
path elimination](#successfailure-path-elimination) above).  A similar
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

(Usage notes: An "EAFP-compatible" function can be declared with `Try.@function f` instead
of `function f end`.  It automatically defines a catch-all fallback method that returns an
`Err{<:NotImplementedError}`.)

#### Side notes on `hasmethod` and `applicable` (and `invoke`)

Note that the EAFP approach using Try.jl is not equivalent to the ["Look before
you leap" (LBYL)](https://docs.python.org/3/glossary.html#term-LBYL) counterpart
using `hasmethod` and/or `applicable`.  That is to say, checking `applicable(f,
x)` before calling `f(x)` may look attractive as it can be done without any
building blocks.  However, this LBYL approach is fundamentally unusable for
generic feature detection.  This is because `hasmethod` and `applicable` cannot
handle "blanket definition" with "internal dispatch" like this:

```julia
julia> f(x::Real) = f_impl(x);  # blanket definition

julia> f_impl(x::Int) = x + 1;  # internal dispatch

julia> applicable(f, 0.1)
true

julia> hasmethod(f, Tuple{Float64})
true
```

Notice that `f(0.1)` is considered callable if we trust `applicable` or
`hasmethod` even though `f(0.1)` will throw a `MethodError`.  Thus, unless the
overload instruction of `f` specifically forbids the blanket definition like
above, the result of `applicable` and `hasmethod` cannot be trusted.  (For
exactly the same reason, the use of `invoke` on library functions is
problematic.)

The EAFP approach works because the actual code path "dynamically declares" the
feature.

### When to `throw`? When to `return`?

Having two modes of error reporting (i.e., `throw`ing an exception and 
`return`ing an `Err` value) introduces a complexity that must be justified.  Is
Try.jl just a workaround until the compiler can optimize `try`-`catch`?   ("Yes"
may be a reasonable answer.)  Or is there a principled way to distinguish the
use cases of them?  (This is what is explored here.)

Reporting error by `return`ing an `Err` value is particularly useful when an
error handling occurs in a tight loop.  For example, when composing concurrent
data structure APIs, it is sometimes required to know the failure mode (e.g.,
logical vs temporary/contention failures) in a tight loop. It is likely that
Julia compiler can compile this down to a simple flag-based low-level code or a
state machine. Note that this style of programming requires a clear definition
of the API noting on what conditions certain errors are reported. That is to
say, the API ensures the detection of unsatisfied pre-conditions and it is
likely that the caller have some ways to recover from the error.

In contrast, if there is no way for the caller *program* to recover from the
error and the error should be reported to a *human*, `throw`ing an exception is
more appropriate.  For example, if an inconsistency of the internal state of a
data structure is detected, it is likely a bug in the usage or implementation.
In this case, there is no way for the caller program to recover from such an
out-of-contract error and only the human programmer can take an action.  To
support typical interactive workflow in Julia, printing an error and aborting
the whole program is not an option.  Thus, it is crucial that it is possible to
recover even from an out-of-contract error in Julia.  Such a language construct
is required for building programming tools such as REPL and editor plugins can
use it.  In summary, `return`-based error reporting is adequate for recoverable
errors and `throw`-based error reporting is adequate for unrecoverable (i.e.,
programmer's) errors.
