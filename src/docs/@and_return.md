    Try.@and_return result -> result′

Evaluate `f(value)` if `result` is a "success" wrapping a `value`; otherwise, a "failure"
`value` as-is.

| Invocation                | Equivalent code  |
|:---                       |:---              |
| `@and_return Ok(value)`   | `value`          |
| `@and_return err::Err`    | `return err`     |
| `@and_return Some(value)` | `value`          |
| `@and_return nothing`     | `return nothing` |

See also: [`@?`](@ref) [`and_then`](@ref), [`or_else`](@ref).

# Extended help

## Examples

Let's define a function `nitems` that works like `length` but falls back to iteration-based
counting:

```julia
using Try, TryExperimental

function trygetnitems(xs)
    Try.@and_return trygetlength(xs)
    Ok(count(Returns(true), xs))
end

nitems(xs) = Try.unwrap(trygetnitems(xs))

nitems(1:3)

# output
3
```

`nitems` works with arbitrary iterator, including the ones that does not have `length`:

```julia
ch = foldl(push!, 1:3; init = Channel{Int}(3))
close(ch)

nitems(ch)

# output
3
```
