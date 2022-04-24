    Try.or(results...)

Return the first "successful" result or the last result if all results are "failures."

# Extended help

## Examples

```julia
julia> using Try

julia> Try.or(Err(1), Ok(2), Err(3))
Try.Ok: 2

julia> Try.or(Err(1), Err(2), Err(3))
Try.Err: 3

julia> Try.or(nothing, Some(2), Some(3))
Some(2)

julia> Try.or(nothing, nothing, nothing)
```
