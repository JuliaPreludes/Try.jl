module TestShow

using Test
using Try
using TryExperimental: @tryable, NotImplementedError

@tryable dummy

function test_tryable()
    @test string(dummy) == "dummy"
    @test sprint(show, dummy) == "dummy"
    @test sprint(show, "text/plain", dummy) == "dummy (tryable function with 1 method)"
end

function test_notimplementederror()
    ex = NotImplementedError(identity, (1, 2, 3), (a = 4, b = 5))
    msg = sprint(showerror, ex)
    @test occursin("identity(1, 2, 3; a = 4, b = 5)", msg)
end

end  # module
