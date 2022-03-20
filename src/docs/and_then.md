    Try.and_then(f, result) -> result′
    Try.and_then(f) -> result -> result′

Evaluate `f(value)` if `result` is a "success" wrapping a `value`; otherwise, a "failure"
`value` as-is.

| Invocation                 | Equivalent code |
|:---                        |:---             |
| `and_then(f, Ok(value))`   | `f(value)`      |
| `and_then(f, err::Err)`    | `err`           |
| `and_then(f, Some(value))` | `f(value)`      |
| `and_then(f, nothing)`     | `nothing`       |

See also: [`@?`](@ref) [`@and_return`](@ref), [`or_else`](@ref).

# Extended help

## Examples

```julia
using Try, TryExperimental

try_map_prealloc(f, xs) =
    Try.and_then(trygetlength(xs)) do n
        Try.and_then(trygeteltype(xs)) do T
            ys = Vector{T}(undef, n)
            for (i, x) in zip(eachindex(ys), xs)
                ys[i] = f(x)
            end
            return Ok(ys)
        end
    end

Try.unwrap(try_map_prealloc(x -> x + 1, 1:3))

# output
3-element Vector{Int64}:
 2
 3
 4
```
