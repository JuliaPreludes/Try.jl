Causes.notimplemented(
    f,
    args::Tuple,
    kwargs::Union{NamedTuple,Iterators.Pairs} = NamedTuple(),
) = Err(Try.NotImplementedError(f, args, kwargs))


Causes.empty(container) = Err(TryExperimental.EmptyError(container))

struct EmptyError <: TryExperimental.EmptyError
    container::Any
end
# TODO: check if it is better to not "type-erase"

TryExperimental.EmptyError(container) = EmptyError(container)


Causes.closed(container) = Err(TryExperimental.ClosedError(container))

struct ClosedError <: TryExperimental.ClosedError
    container::Any
end
# TODO: check if it is better to not "type-erase"

TryExperimental.ClosedError(container) = ClosedError(container)
