module UnionTyped
import TryExperimental
const Try = TryExperimental
using .Try
g(xs) = Ok(xs)
f(xs) = g(xs) |> Try.and_then(xs -> Try.getindex(xs, 1)) |> Try.ok
end  # module UnionTyped

module ConcretelyTyped
import TryExperimental
const Try = TryExperimental
using .Try
g(xs) = Try.ConcreteOk(xs)
function trygetfirst(xs)::Try.ConcreteResult{eltype(xs),BoundsError}
    Try.getindex(xs, 1)
end
f(xs) = g(xs) |> Try.and_then(trygetfirst) |> Try.ok
end  # module
