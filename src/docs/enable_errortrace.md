    Try.enable_errortrace()

Enable stack trace capturing for each `Err` value creation for debugging.

See also: [`Try.disable_errortrace`](@ref)

# Examples
```JULIA
julia> using Try, TryExperimental

julia> trypush!(Int[], :a)
Try.Err: Not Implemented: tryconvert(Int64, :a)

julia> Try.enable_errortrace();

julia> trypush!(Int[], :a)
Try.Err: Not Implemented: tryconvert(Int64, :a)
Stacktrace:
 [1] convert
   @ ~/.julia/dev/Try/src/core.jl:28 [inlined]
 [2] Break (repeats 2 times)
   @ ~/.julia/dev/Try/src/branch.jl:11 [inlined]
 [3] branch
   @ ~/.julia/dev/Try/src/branch.jl:27 [inlined]
 [4] macro expansion
   @ ~/.julia/dev/Try/src/branch.jl:49 [inlined]
 [5] (::TryExperimental.var"##typeof_trypush!#298")(a::Vector{Int64}, x::Symbol)
   @ TryExperimental.Internal ~/.julia/dev/Try/lib/TryExperimental/src/base.jl:69
 [6] top-level scope
   @ REPL[4]:1
```
