    Try.@or(expressions...)

Evaluate to the first "successful" result of one of the `expressions` and do not evaluate
the rest of the `expressions`.  Otherwise, evaluate all `expressions` and return the last
result.

# Extended help

## Examples

```julia
julia> using Try

julia> Try.@or(Err(1), Ok(2), (println("this is not evaluated"); Err(3)))
Try.Ok: 2

julia> Try.@or(Err(1), Err(2), Err(3))
Try.Err: 3

julia> Try.@or(nothing, Some(2), (println("this is not evaluated"); Some(3)))
Some(2)

julia> Try.@or(nothing, nothing, nothing)
```
