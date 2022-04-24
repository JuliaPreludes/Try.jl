    Try.map(f, result) -> result′
    Try.map(f, Ok(value)) -> Ok(f(value))
    Try.map(_, err::Err) -> err
    Try.map(f, Some(value)) -> Some(f(value))
    Try.map(_, nothing) -> nothing
    Try.map(f) -> result -> Try.map(f, result)

Apply `f` in the value wrapped in the "successful" result.

# Examples

```julia
julia> using Try

julia> Try.map(x -> x + 1, Ok(1))
Try.Ok: 2

julia> Try.map(x -> x + 1, Err(KeyError(:a)))
Try.Err: KeyError: key :a not found

julia> Try.map(x -> x + 1, Some(1))
Some(2)

julia> Try.map(x -> x + 1, nothing)
```
