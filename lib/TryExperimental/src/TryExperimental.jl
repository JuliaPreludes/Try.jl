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

# Basic exceptions
abstract type EmptyError <: Exception end
abstract type ClosedError <: Exception end
# abstract type FullError <: Exception end

baremodule Causes
function notimplemented end
function empty end
function closed end
end  # baremodule Cause

module Internal

using ..TryExperimental: TryExperimental, Causes
using Try

for n = names(TryExperimental; all = true)
    startswith(string(n), "try") || continue
    fn = getproperty(TryExperimental, n)
    @eval import TryExperimental: $n
end

using Base: IteratorEltype, HasEltype, IteratorSize, HasLength, HasShape

include("causes.jl")
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
