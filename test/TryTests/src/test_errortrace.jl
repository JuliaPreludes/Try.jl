module TestErrorTrace

using Test
using Try
using Try.Internal: ErrorTrace

function module_context(f)
    old = Try.enable_errortrace(true)
    try
        Base.invokelatest(f)
    finally
        Try.enable_errortrace(old)
    end
end

@noinline f1(x) = x ? Ok(nothing) : Err(ErrorException("nope"))
@noinline f2(x) = f1(x)
@noinline f3(x) = f2(x)

function test_errtrace()
    err = f1(false)
    @test err isa Err
    errmsg = sprint(show, "text/plain", err)
    @test occursin("f1(x::Bool)", errmsg)

    exc = try
        Try.unwrap(err)
        nothing
    catch x
        x
    end
    @test exc isa ErrorTrace
    excmsg = sprint(showerror, exc)
    @test occursin("f1(x::Bool)", excmsg)
end

end  # module
