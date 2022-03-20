module TestTools

using Test
using Try
using TryExperimental

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
