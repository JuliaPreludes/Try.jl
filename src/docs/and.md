    Try.and(results...)

Return the first "failure" or the last result if all results are "success."

# Extended help

## Examples

```julia
julia> using Try

julia> Try.and(Ok(1), Ok(2), Ok(3))
Try.Ok: 3

julia> Try.and(Ok(1), Err(2), Ok(3))
Try.Err: 2

julia> Try.and(Some(1), Some(2), Some(3))
Some(3)

julia> Try.and(Some(1), nothing, Some(3))
```
