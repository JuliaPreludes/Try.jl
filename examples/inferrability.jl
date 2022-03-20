module UnionTyped
using Try
using TryExperimental
using TryExperimental: Maybe
g(xs) = Ok(xs)
f(xs) = g(xs) |> Try.and_then(xs -> trygetindex(xs, 1)) |> Maybe.ok
end  # module UnionTyped

module ConcretelyTyped
using Try
using TryExperimental
using TryExperimental: Maybe
g(xs) = Try.ConcreteOk(xs)
function trygetfirst(xs)::Try.ConcreteResult{eltype(xs),BoundsError}
    trygetindex(xs, 1)
end
f(xs) = g(xs) |> Try.and_then(trygetfirst) |> Maybe.ok
end  # module
