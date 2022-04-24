    Try.@and_return result

Evaluate to a "success" value or `return` a "failure" value.

Use [`@return`](@ref) to return unwrapped value.

| Invocation                | Equivalent code  |
|:---                       |:---              |
| `@and_return ok::Ok`      | `return ok`      |
| `@and_return Err(value)`  | `value`          |
| `@and_return some::Some`  | `return some`    |
| `@and_return nothing`     | `nothing`        |

See also: [`@?`](@ref), [`@return`](@ref), [`and_then`](@ref), [`or_else`](@ref).

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
