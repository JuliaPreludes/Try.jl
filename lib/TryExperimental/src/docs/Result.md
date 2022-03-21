    TryExperimental.Result{T,E}

A super type of `Ok{<:T}`, `Err{<:E}`, and `ConcreteResult{T,E}`.

See also: [`Try.Ok`](@ref), [`Try.Err`](@ref), [`ConcreteResult`](@ref).

# Extended help
# Examples

Consider creating an API `tryparse(T, input) -> result`.  To simplify the example, let us
define the implementation using `Base.tryparse`:

```julia
using Try
using TryExperimental
using TryExperimental: Result

struct InvalidCharError <: Exception end
struct EndOfBufferError <: Exception end

function __tryparse__(::Type{Int}, str::AbstractString)
    isempty(str) && return Err(EndOfBufferError())
    Ok(@something(Base.tryparse(Int, str), return Err(InvalidCharError())))
end
```

where `__tryparse__` is an overload-only API.  If it is decided that the call API `tryparse`
should have a limited set of failure modes, it can be enforced by the return value
conversion to a `Result` type.

```julia
tryparse(T, input)::Result{T,Union{InvalidCharError,EndOfBufferError}} =
    __tryparse__(T, input)
```

```julia
julia> tryparse(Int, "111")
Try.Ok: 111

julia> tryparse(Int, "one")
Try.Err: InvalidCharError()
```

## Discussion

Currently, `Result` is defined as

```JULIA
Result{T,E} = Union{ConcreteResult{T,E},Ok{<:T},Err{<:E}}
```

although there are other possible definitions:

```JULIA
Result{T,E} = Union{ConcreteResult{<:T,<:E},Ok{<:T},Err{<:E}}
Result{T,E} = Union{ConcreteResult{T,E},Ok{T},Err{E}}
Result{T,E} = AbstractResult{<:T, <:E}
Result = AbstractResult
```

The current definition of `Result` may look strange since the type parameters are invariant
for `ConcreteResult` and variant for `Ok` and `Err`.  This is chosen given the expectation
that `Union{Ok,Err}` users likely to prefer to let the compiler extra opportunities to
perform pass-dependent optimizations while `ConcreteResult` users likely to prefer control
the exact return type.  The definition of `Result` allows these usages simultaneously.

This let `__tryparse__` implementers opt-in `ConcreteResult` by simply converting their
return value to a `ConcreteResult`:

```JULIA
function __tryparse__(T::Type, io::MyIO)::ConcreteResult{T,InvalidCharError}
    ...
end
```

This example also demonstrates that `ConcreteResult{T,InvalidCharError}` can automatically
be converted to `Result{T,Union{InvalidCharError,EndOfBufferError}}`.

As explained above, `Result{T,E}` seems to have nice properties.  However, it is not clear
if it works in practice.  This is why `Result` is provided from `TryExperimental` but not
from `Try`.  For example, `ConcreteResult` may not be useful in practice.  If
`ConcreteResult` is dropped, it may be a good idea to define

```
Result{T,E} = Union{Ok{T},Err{E}}
```

so that the users can explicitly manipulate the variance of each parameters.
