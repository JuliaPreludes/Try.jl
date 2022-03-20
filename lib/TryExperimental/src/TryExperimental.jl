baremodule TryExperimental

import Try

module InternalPrelude
include("prelude.jl")
end  # module InternalPrelude
InternalPrelude.@reexport_try

Try.@function convert
# Try.@function promote

# Collection interface
Try.@function length
Try.@function eltype

Try.@function getindex
Try.@function setindex!

Try.@function first
Try.@function last

Try.@function push!
Try.@function pushfirst!
Try.@function pop!
Try.@function popfirst!

Try.@function put!
Try.@function take!

Try.@function push_nowait!
Try.@function pushfirst_nowait!
Try.@function pop_nowait!
Try.@function popfirst_nowait!

Try.@function put_nowait!
Try.@function take_nowait!

module Internal

import ..TryExperimental
const Try = TryExperimental
using .Try
using .Try: Causes

using Base: IteratorEltype, HasEltype, IteratorSize, HasLength, HasShape

include("base.jl")

end  # module Internal

end  # baremodule TryExperimental
