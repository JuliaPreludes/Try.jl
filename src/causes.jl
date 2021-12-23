Causes.notimplemented(
    f,
    args::Tuple,
    kwargs::Union{NamedTuple,Iterators.Pairs} = NamedTuple(),
) = Err(Try.NotImplementedError(f, args, kwargs))

Causes.empty(container) = Err(Try.EmptyError(container))

struct NotImplementedError{T} <: Try.NotImplementedError end
# TODO: check if it is better to "type-erase"
# TODO: don't ignore kwargs?

Try.NotImplementedError(f, args, _kwargs) =
    NotImplementedError{Tuple{_typesof(f, args...)...}}()

_typesof() = ()
_typesof(::Type{Head}, tail...) where {Head} = (Type{Head}, _typesof(tail...)...)
_typesof(head, tail...) = (typeof(head), _typesof(tail...)...)

struct EmptyError
    container::Any
end
# TODO: check if it is better to not "type-erase"

Try.EmptyError(container) = EmptyError(container)
