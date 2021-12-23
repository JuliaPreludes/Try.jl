module TestBase

using Test
using Try

function test_convert()
    @test Try.unwrap(Try.convert(Int, 1)) === 1
    @test Try.unwrap(Try.convert(Union{Int,String}, 1)) === 1
    @test Try.iserr(Try.convert(Union{}, 1))
    @test Try.iserr(Try.convert(String, 1))
    @test Try.unwrap_err(Try.convert(Nothing, 1)) isa Try.NotImplementedError
end

function test_length()
    @test Try.unwrap_err(Try.length(nothing)) isa Try.NotImplementedError
    @test Try.unwrap_err(Try.length(x for x in 1:10 if isodd(x))) isa
          Try.NotImplementedError
    @test Try.unwrap(Try.length([1])) == 1
end

function test_eltype()
    @test Try.unwrap(Try.eltype(1)) === Int
    @test Try.unwrap(Try.eltype([1])) === Int
    @test Try.unwrap(Try.eltype(AbstractVector{Int})) === Int
    @test Try.unwrap(Try.eltype(AbstractArray{Int})) === Int
    @test Try.unwrap_err(Try.eltype(AbstractVector)) isa Try.NotImplementedError
end

function test_getindex()
    @test Try.unwrap(Try.getindex([111], 1)) === 111
    @test Try.unwrap_err(Try.getindex([111], 0)) isa BoundsError
    @test Try.unwrap_err(Try.getindex([111], 2)) isa BoundsError

    @test Try.unwrap(Try.getindex(Dict(:a => 111), :a)) === 111
    @test Try.unwrap_err(Try.getindex(Dict(:a => 111), :b)) isa KeyError
end

end  # module
