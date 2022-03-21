module UnionTyped
using Try
using TryExperimental
using TryExperimental: Maybe
f(xs) = Ok(xs) |> Try.and_then(xs -> trygetindex(xs, 1)) |> Maybe.ok
end  # module UnionTyped

module ConcretelyTyped
using Try
using TryExperimental
using TryExperimental: ConcreteResult, Maybe
function trygetfirst(xs)::ConcreteResult{eltype(xs),BoundsError}
    trygetindex(xs, 1)
end
f(xs) = Ok(xs) |> Try.and_then(trygetfirst) |> Maybe.ok
end  # module
