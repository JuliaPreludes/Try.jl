    Try.@return result


| Invocation            | Equivalent code  |
|:---                   |:---              |
| `@return Ok(value)`   | `return value`   |
| `@return Err(value)`  | `value`          |
| `@return Some(value)` | `return value`   |
| `@return nothing`     | `nothing`        |

See also: [`@?`](@ref) [`and_then`](@ref), [`or_else`](@ref).

# Extended help

## Examples

Let's define a function `nitems` that works like `length` but falls back to iteration-based
counting:

```julia
using Try, TryExperimental

function nitems(xs)
    Try.@return trygetlength(xs)
    count(Returns(true), xs)
end

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
