module TestDoctest

using Documenter
using Try
using TryExperimental

function test_try()
    VERSION < v"1.7" && return
    doctest(Try; manual = false)
end

function test_tryexperimental()
    VERSION < v"1.7" && return
    doctest(TryExperimental; manual = false)
end

end  # module
