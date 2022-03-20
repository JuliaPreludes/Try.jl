"""
    Tryable <: Function

An *implementation detail* of `Try.@function`.

This is not exposed as an API because:

* It may be required for a callable to be in another type hierarchy.  Such callables are
  incompatible with the code written with `_ isa Tryable`.
* When a Tryable function is part of stack trace, its printing is not great. It may be
  better to just use a plain `function` and define `istryable`.
* The tryability many depend on some run-time properties.
"""
abstract type Tryable <: Function end

Try.istryable(::Any) = false
Try.istryable(::Tryable) = true

const var"@define_function" = var"@function"

macro define_function(name::Symbol)
    typename = gensym("typeof_$name")
    quote
        struct $typename <: $Tryable end
        const $name = $typename()
        $Base.nameof(::$typename) = $(QuoteNode(name))
    end |> esc
end

(fn::Tryable)(args...; kwargs...) = Causes.notimplemented(fn, args, kwargs)

# TODO: show methods
