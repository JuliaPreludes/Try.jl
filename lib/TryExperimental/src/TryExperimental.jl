baremodule TryExperimental

module InternalPrelude
include("prelude.jl")
end  # module InternalPrelude

InternalPrelude.@exported_function tryconvert
# InternalPrelude.@exported_function trypromote

# Collection interface
InternalPrelude.@exported_function trygetlength
InternalPrelude.@exported_function trygeteltype

InternalPrelude.@exported_function trygetindex
InternalPrelude.@exported_function trysetindex!

InternalPrelude.@exported_function trygetfirst
InternalPrelude.@exported_function trygetlast

InternalPrelude.@exported_function trypush!
InternalPrelude.@exported_function trypushfirst!
InternalPrelude.@exported_function trypop!
InternalPrelude.@exported_function trypopfirst!

InternalPrelude.@exported_function tryput!
InternalPrelude.@exported_function trytake!

module Internal

import ..TryExperimental
using Try
using Try: Causes

for n in names(TryExperimental; all = true)
    startswith(string(n), "try") || continue
    fn = getproperty(TryExperimental, n)
    @eval import TryExperimental: $n
end

using Base: IteratorEltype, HasEltype, IteratorSize, HasLength, HasShape

include("base.jl")

end  # module Internal

# TODO: move this to Maybe.jl
baremodule Maybe
function ok end
function err end
module Internal
using ..Maybe
include("maybe.jl")
end
end  # module Maybe

end  # baremodule TryExperimental
