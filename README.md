# Try.jl: zero-overhead and debuggable error handling

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Try.jl/dev)
[![CI](https://github.com/tkf/Try.jl/actions/workflows/test.yml/badge.svg)](https://github.com/tkf/Try.jl/actions/workflows/test.yml)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Features:

* Error handling as simple manipulations of *values*.
* Focus on *inferrability* and *optimizability* leveraging unique properties of
  the Julia language and compiler.
* *Error trace* for determining the source of errors, without `throw`.
* Facilitate the ["Easier to ask for forgiveness than permission"
  (EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) approach as a
  robust and minimalistic alternative to the trait-based feature detection.
* Generic and extensible tools for composing failable procedures.

For more explanation, see [Discussion](#discussion) below.

See the [Documentation](https://tkf.github.io/Try.jl/dev/) for API reference.

## Examples

### Basic usage

For demonstration, let us import TryExperimental.jl to see how to use failable APIs built
using Try.jl.

```julia
julia> using Try

julia> using TryExperimental  # exports trygetindex etc.
```

Try.jl-based API returns either an `OK` value

```julia
julia> ok = trygetindex(Dict(:a => 111), :a)
Try.Ok: 111
```

or an `Err` value:

```julia
julia> err = trygetindex(Dict(:a => 111), :b)
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

and [more](https://tkf.github.io/Try.jl/dev/).

### Error trace

Consider an example where an error "bubbles up" from a deep stack of function
calls:

```JULIA
julia> using Try, TryExperimental

julia> f1(x) = x ? Ok(nothing) : Err(KeyError(:b));

julia> f2(x) = f1(x);

julia> f3(x) = f2(x);
```

Since Try.jl represents an error simply as a Julia value, there is no
information on the source of this error by default:

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
defined in `TryExperimental` does not throw when the method is not defined.  For
example, `trygeteltype` and `trygetlength` can be called on arbitrary objects (=
"asking for forgiveness") without checking if the method is defined (= "asking
for permission").

```julia
using Try, TryExperimental

function try_map_prealloc(f, xs)
    T = @? trygeteltype(xs)  # macro-based short-circuiting
    n = @? trygetlength(xs)
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
some success and failure paths can never be taken:

```julia
julia> using TryExperimental, InteractiveUtils

julia> @code_typed(trygetfirst((111, "two", :three)))[2]  # always succeeds for non empty tuples
Ok{Int64}

julia> @code_typed(trygetfirst(()))[2]  # always fails for an empty tuple
Err{BoundsError}

julia> @code_typed(trygetfirst(Int[]))[2]  # both are possible for an array
Union{Ok{Int64}, Err{BoundsError}}
```

### Constraining returnable errors

We can use the return type conversion `function f(...)::ReturnType ...  end` to
constrain possible error types. This is similar to the `throws` keyword in Java.

This can be used for ensuring that only the expected set of errors are returned
from Try.jl-based functions.  In particular, it may be useful for restricting
possible errors at an API boundary.  The idea is to separate "call API" `f` from
"overload API" `__f__` such that new methods are added to `__f__` and not to
`f`.  We can then wrap the overload API function by the call API function that
simply declares the return type:

```Julia
f(args...)::Result{Any,PossibleErrors} = __f__(args...)
```

Then, the API specification of `f` can include the overloading instruction explaining that a
method of `__f__` (instead of `f`) should be defined and can enumerate allowed set of
errors.

Here is an example of a call API `tryparse` with an overload API `__tryparse__` wrapping
`Base.tryparase`.  In this toy example, `__tryparse__` can return `InvalidCharError()` or
`EndOfBufferError()` as an error value:

```julia
using Try, TryExperimental

const Result{T,E} = Union{Ok{<:T},Err{<:E}}
# using TryExperimental: Result  # (almost equivalent)

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
the dynamism to get the performance comparable to static languages.  As such, many
successful features of Julia provide the usability of a dynamic language while
paying attentions to the optimizability of the composed code.  However, native
`throw`/`catch`-based exception is not optimized aggressively and existing
"static" solutions do not support idiomatic high-level style of programming.
Try.jl explores [an alternative solution](https://xkcd.com/927/) embracing the
dynamism of Julia while restricting the underlying code as much as possible to
the form that the compiler can optimize away.

### Focus on *actions*; not the types

Try.jl aims at providing generic tools for composing failable procedures.  This emphasis on
performing *actions* that can fail contrasts with other [similar Julia
packages](#similar-packages) focusing on types and is reflected in the name of the package:
*Try*.  This is an important guideline on designing APIs for dynamic programming languages
like Julia in which high-level code should be expressible without managing types.

For example, Try.jl provides [the APIs for short-circuit
evaluation](https://tkf.github.io/Try.jl/dev/#Short-circuit-evaluation) that can be used not
only for `Union{Ok,Err}`:

```julia
julia> Try.and_then(Ok(1)) do x
           Ok(x + 1)
       end
Try.Ok: 2

julia> Try.and_then(Ok(1)) do x
           iszero(x) ? Ok(x) : Err("not zero")
       end
Try.Err: "not zero"
```

but also for `Union{Some,Nothing}`:

```julia
julia> Try.and_then(Some(1)) do x
           Some(x + 1)
       end
Some(2)

julia> Try.and_then(Some(1)) do x
           iszero(x) ? Some(x) : nothing
       end
```

Above code snippets mention constructors `Ok`, `Err`, and `Some` just enough for conveying
information about "success" and "failure."

Of course, in Julia, types can be used for controlling execution efficiently and flexibly.
In fact, the mechanism required for various short-circuit evaluation can be used for
arbitrary user-defined types by defining [the short-circuit evaluation
interface](https://tkf.github.io/Try.jl/dev/experimental/#customize-short-circuit)
(experimental).

### Dynamic returned value types for maximizing optimizability

Try.jl provides an API inspired by Rust's `Result` type and `Try` trait.  However, to fully
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
to communicate the intent of the code to the compiler (e.g., if a function
call always succeeds, always return an `Ok{T}`).

(That said, Try.jl also contains supports for concretely-typed returned value
when `Union` is not appropriate. This is for experimenting if such a manual
"type-instability-hiding" is a viable approach at a large scale and if providing
a pleasing uniform API is possible.)

### Debuggable error handling

A potential usability issue for using the `Result` type is that the detailed
context of the error is lost by the time the user received an error.  This makes
debugging Julia programs hard compared to simply `throw`ing the exception.  To
mitigate this problem, Try.jl provides an *error trace* mechanism for recording
the backtrace of the error.  This can be toggled using `Try.enable_errortrace()`
at the run-time.  This is inspired by Zig's [Error Return
Traces](https://ziglang.org/documentation/master/#Error-Return-Traces).

### EAFP and traits

TryExperiments.jl implements a limited set of "verbs" based on Julia `Base` such as
`trytake!` as a demonstration of Try.jl API.  These functions have a catch-all default
definition that returns an error value of type `Err{<:NotImplementedError}`.  This lets us
use these functions in the ["Easier to ask for forgiveness than permission"
(EAFP)](https://docs.python.org/3/glossary.html#term-EAFP) manner because they
can be called without getting the run-time `MethodError` exception.
Importantly, the EAFP approach does not have the problem of the trait-based
feature detection where the implementer must ensure that declared trait (e.g.,
`HasLength`) is compatible with the actual definition (e.g., `length`).  With
the EAFP approach, *the feature is declared automatically by defining of the
method providing it* (e.g., `trygetlength`).  Thus, by construction, it is hard to
make the feature declaration and definition out-of-sync.  Of course, this
approach works only for effect-free or "redo-able" functions when naively applied.  To check
if a sequence of destructive operations is possible, the trait-based approach is very
straightforward.  One way to use the EAFP approach for effectful computations is to create a
low-level two-phase API where the first phase constructs a recipe of how to apply the
effects in an EAFP manner and the second phase applies the effect.

(Usage notes: An "EAFP-compatible" function can be declared with `Try.@function f` instead
of `function f end`.  It automatically defines a catch-all fallback method that returns an
`Err{<:NotImplementedError}`.)

#### Side notes on `hasmethod` and `applicable` (and `invoke`)

Note that the EAFP approach using Try.jl is not equivalent to the ["Look before
you leap" (LBYL)](https://docs.python.org/3/glossary.html#term-LBYL) counterpart
using `hasmethod` and/or `applicable`.  Checking `applicable(f, x)` before calling `f(x)`
may look attractive as it can be done without any manual coding.  However, this LBYL
approach is fundamentally unusable for generic feature detection.  This is because
`hasmethod` and `applicable` cannot handle "blanket definition" with "internal dispatch"
like this:

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
Julia compiler can optimize Try.jl's error handling down to a simple flag-based low-level
code. Note that this style of programming requires a clear definition of
the API noting on what conditions certain errors are reported. That is to
say, such an API guarantees the detection of certain unsatisfied "pre-conditions" and the
caller *program* is expected to have some ways to recover from these errors.

In contrast, if there is no way for the caller program to recover from the
error and the error should be reported to a *human*, `throw`ing an exception is
more appropriate.  For example, if an inconsistency of the internal state of a
data structure is detected, it is likely a bug in the usage or implementation.
In this case, there is no way for the caller program to recover from such an
out-of-contract error and only the human programmer can take an action.  To
support typical interactive workflow in Julia, printing an error and aborting
the whole program is not an option.  Thus, it is crucial that it is possible to
recover even from an out-of-contract error in Julia.  Such a language construct
is required for building programming tools such as REPL and editor plugins.  In summary,
`return`-based error reporting is adequate for recoverable errors and `throw`-based error
reporting is adequate for unrecoverable (i.e., programmer's) errors.

### Links
#### Similar packages

* [ErrorTypes.jl](https://github.com/jakobnissen/ErrorTypes.jl)
* [ResultTypes.jl](https://github.com/iamed2/ResultTypes.jl)
* [Expect.jl](https://github.com/KristofferC/Expect.jl)

#### Other discussions

* [Can we have result value convention for fast error handling? · Discussion #43773 · JuliaLang/julia](https://github.com/JuliaLang/julia/discussions/43773)
* [Try.jl - JuliaLang - Zulip](https://julialang.zulipchat.com/#narrow/stream/137791-general/topic/Try.2Ejl)
* [[ANN] ErrorTypes.jl - Rust-like safe errors in Julia - Package Announcements / Package announcements - JuliaLang](https://discourse.julialang.org/t/ann-errortypes-jl-rust-like-safe-errors-in-julia/53953)
