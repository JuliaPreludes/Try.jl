module TestDoctest

using Documenter
using Test
using Try

function test()
    doctest(Try; manual = false)
end

end  # module
