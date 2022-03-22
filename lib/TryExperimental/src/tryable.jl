"""
    Tryable <: Function

An *implementation detail* of `@tryable`.

This is not exposed as an API because:

* It may be required for a callable to be in another type hierarchy.  Such callables are
  incompatible with the code written with `_ isa Tryable`.
* When a Tryable function is part of stack trace, its printing is not great. It may be
  better to just use a plain `function` and define `istryable`.
* The tryability many depend on some run-time properties.
"""
abstract type Tryable <: Function end

istryable(::Any) = false
istryable(::Tryable) = true

macro tryable(name::Symbol)
    typename = gensym("typeof_$name")
    quote
        struct $typename <: $Tryable end
        const $name = $typename()
        $Base.nameof(::$typename) = $(QuoteNode(name))
    end |> esc
end

(fn::Tryable)(args...; kwargs...) =
    Err(TryExperimental.NotImplementedError(fn, args, values(kwargs)))

struct NotImplementedError{F,Args<:Tuple,Kwargs<:NamedTuple} <:
       TryExperimental.NotImplementedError
    f::F
    args::Args
    kwargs::Kwargs
end
# TODO: check if it is better to "type-erase"
# TODO: don't capture values?

asnamedtuple(kwargs::NamedTuple) = kwargs
asnamedtuple(kwargs) = (; kwargs...)

TryExperimental.NotImplementedError(
    f,
    args::Tuple,
    kwargs::Union{NamedTuple,Iterators.Pairs} = NamedTuple(),
) = NotImplementedError(f, args, asnamedtuple(kwargs))

_typesof() = ()
_typesof(::Type{Head}, tail...) where {Head} = (Type{Head}, _typesof(tail...)...)
_typesof(head, tail...) = (typeof(head), _typesof(tail...)...)

Base.print(io::IO, fn::Tryable) = print(io, nameof(fn))
Base.show(io::IO, fn::Tryable) = print(io, nameof(fn))

function Base.show(io::IO, ::MIME"text/plain", fn::Tryable)
    print(io, nameof(fn))
    n = length(methods(fn))
    print(io, " (tryable function with ", n, " method", n == 1 ? "" : "s", ")")
end
