    Try.or_else(f, result) -> result′
    Try.or_else(f) -> result -> result′

Return `result` as-is if it is a "successful" value; otherwise, unwrap a "failure" value in
`result` and then evaluate `f` on it.

| Invocation                | Equivalent code  |
|:---                       |:---              |
| `or_else(f, ok::Ok)`      | `ok`             |
| `or_else(f, Err(value))`  | `f(value)`       |
| `or_else(f, some::Some)`  | `some`           |
| `or_else(f, nothing)`     | `f(nothing)`     |

See also: [`@?`](@ref) [`@and_return`](@ref), [`and_then`](@ref).

# Extended help

## Examples

Let's define a function `nitems` that works like `length` but falls back to iteration-based
counting:

```julia
using Try, TryExperimental

nitems(xs) =
    Try.or_else(trygetlength(xs)) do _
        Ok(count(Returns(true), xs))
    end |> Try.unwrap

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
