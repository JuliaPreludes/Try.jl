module TestInferrability

using Test

include("../../../examples/inferrability.jl")

should_test_module() = lowercase(get(ENV, "JULIA_PKGEVAL", "false")) != "true"

function test()
    @test @inferred(UnionTyped.f((111,))) == Some(111)
    @test @inferred(UnionTyped.f(())) === nothing
    @test ConcretelyTyped.f((111,)) == Some(111)
    @test ConcretelyTyped.f(()) === nothing
end

end  # module
