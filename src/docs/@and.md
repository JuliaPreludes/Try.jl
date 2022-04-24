    Try.@and(expressions...)

Evaluate to the first "failure" result of one of the `expressions` and do not evaluate
the rest of the `expressions`.  Otherwise, evaluate all `expressions` and return the last
result.

# Extended help

## Examples

```julia
julia> using Try

julia> Try.@and(Ok(1), Ok(2), Ok(3))
Try.Ok: 3

julia> Try.@and(Ok(1), Err(2), (println("this is not evaluated"); Ok(3)))
Try.Err: 2

julia> Try.@and(Some(1), Some(2), Some(3))
Some(3)

julia> Try.@and(Some(1), nothing, (println("this is not evaluated"); Some(3)))
```
