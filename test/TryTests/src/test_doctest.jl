module TestDoctest

using Documenter
using Try
using TryExperimental

function test_try()
    doctest(Try; manual = false)
end

function test_tryexperimental()
    doctest(TryExperimental; manual = false)
end

end  # module
