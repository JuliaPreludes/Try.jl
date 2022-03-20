module TestBase

using Test
using Try
using TryExperimental

function test_convert()
    @test Try.unwrap(tryconvert(Int, 1)) === 1
    @test Try.unwrap(tryconvert(Union{Int,String}, 1)) === 1
    @test Try.iserr(tryconvert(Union{}, 1))
    @test Try.iserr(tryconvert(String, 1))
    @test Try.unwrap_err(tryconvert(Nothing, 1)) isa Try.NotImplementedError
end

function test_length()
    @test Try.unwrap_err(trygetlength(nothing)) isa Try.NotImplementedError
    @test Try.unwrap_err(trygetlength(x for x in 1:10 if isodd(x))) isa
          Try.NotImplementedError
    @test Try.unwrap(trygetlength([1])) == 1
end

function test_eltype()
    @test Try.unwrap(trygeteltype(1)) === Int
    @test Try.unwrap(trygeteltype([1])) === Int
    @test Try.unwrap(trygeteltype(AbstractVector{Int})) === Int
    @test Try.unwrap(trygeteltype(AbstractArray{Int})) === Int
    @test Try.unwrap_err(trygeteltype(AbstractVector)) isa Try.NotImplementedError
end

function test_getindex()
    @test Try.unwrap(trygetindex([111], 1)) === 111
    @test Try.unwrap_err(trygetindex([111], 0)) isa BoundsError
    @test Try.unwrap_err(trygetindex([111], 2)) isa BoundsError

    @test Try.unwrap(trygetindex(Dict(:a => 111), :a)) === 111
    @test Try.unwrap_err(trygetindex(Dict(:a => 111), :b)) isa KeyError
end

function test_first()
    @test Try.unwrap(trygetfirst([111, 222, 333])) === 111
    @test Try.unwrap(trygetfirst((111, 222, 333))) === 111
    @test Try.iserr(trygetfirst([]))
    @test Try.iserr(trygetfirst(()))
end

function test_last()
    @test Try.unwrap(trygetlast([111, 222, 333])) === 333
    @test Try.unwrap(trygetlast((111, 222, 333))) === 333
    @test Try.iserr(trygetlast([]))
    @test Try.iserr(trygetlast(()))
end

end  # module
