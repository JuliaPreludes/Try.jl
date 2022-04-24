module TestCore

using Test
using Try

function test_ok_nothing()
    @test Ok() === Ok(nothing)::Ok{Nothing}
end

end  # module
