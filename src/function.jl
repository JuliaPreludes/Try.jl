const var"@define_function" = var"@function"

macro define_function(name::Symbol)
    typename = gensym("typeof_$name")
    quote
        struct $typename <: $Try.Tryable end
        const $name = $typename()
        $Base.nameof(::$typename) = $(QuoteNode(name))
    end |> esc
end

(fn::Try.Tryable)(args...; kwargs...) = Causes.notimplemented(fn, args, kwargs)

# TODO: show methods
