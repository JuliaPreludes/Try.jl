module TestTools

using Test
using Try
using TryExperimental

function trygetnitems(xs)
    Try.@and_return trygetlength(xs)
    Ok(count(Returns(true), xs))
end

function nitems(xs)
    Try.or_else(trygetlength(xs)) do _
        Ok(count(Returns(true), xs))
    end |> Try.unwrap
end

function test_and_return()
    @test Try.unwrap(trygetnitems(1:3)) == 3

    ch = foldl(push!, 1:3; init = Channel{Int}(3))
    close(ch)
    @test Try.unwrap(trygetnitems(ch)) == 3
end

function test_or_else()
    @test nitems(1:3) == 3

    ch = foldl(push!, 1:3; init = Channel{Int}(3))
    close(ch)
    @test nitems(ch) == 3
end

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

function try_map_prealloc2(f, xs)
    T = @? trygeteltype(xs)  # macro-based short-circuiting
    n = @? trygetlength(xs)
    ys = Vector{T}(undef, n)
    for (i, x) in zip(eachindex(ys), xs)
        ys[i] = f(x)
    end
    return Ok(ys)
end

function test_and_then()
    @test Try.unwrap(try_map_prealloc(x -> x + 1, 1:3)) == 2:4
end

function test_or_return()
    @test Try.unwrap(try_map_prealloc2(x -> x + 1, 1:3)) == 2:4
end

function test_curry()
    value =
        tryconvert(String, 1) |>
        Try.or_else() do _
            Ok("123")
        end |>
        Try.and_then() do x
            Ok(@something(tryparse(Int, x), return Err(ErrorException(""))))
        end |>
        Try.unwrap

    @test value == 123
end

function demo_macro(xs)
    i = firstindex(xs)
    y = nothing
    while true
        #! format: off
        x = @Try.or_else(trygetindex(xs, i)) do _
            return :oob
        end
        @Try.and_then(trygetindex(xs, Try.unwrap(x))) do z
            if z > 1
                y = z
                break
            end
        end
        #! format: on
        i += 1
    end
    return y
end

function test_macro()
    @test demo_macro(1:2:10) == 5
    @test demo_macro(1:0) === :oob
end

end  # module
