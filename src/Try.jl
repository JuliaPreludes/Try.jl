baremodule Try

export @?, Ok, Err

module InternalPrelude
abstract type AbstractResult{T,E} end
function _IsOkError end
end  # module InternalPrelude

struct Ok{T} <: InternalPrelude.AbstractResult{T,Union{}}
    value::T
end

struct Err{E} <: InternalPrelude.AbstractResult{Union{},E}
    value::E
    backtrace::Union{Nothing,typeof(InternalPrelude.backtrace())}
end

function unwrap end
function unwrap_err end

function oktype end
function errtype end
function isok end
function iserr end

function enable_errortrace end
function disable_errortrace end

function istryable end
function var"@function" end

# Core exceptions
struct IsOkError <: InternalPrelude.Exception
    ok::InternalPrelude.AbstractResult

    InternalPrelude._IsOkError(ok) = new(ok)
end

abstract type NotImplementedError <: InternalPrelude.Exception end

macro and_return end
function var"@?" end

function and_then end
function or_else end

module Internal

import ..Try: @and_return, @?, @function
using ..Try: Err, Ok, Try
using ..Try.InternalPrelude: AbstractResult, _IsOkError

include("ExternalDocstrings.jl")
using .ExternalDocstrings: @define_docstrings

include("core.jl")
include("errortrace.jl")
include("function.jl")
include("branch.jl")
include("show.jl")

end  # module Internal

Internal.@define_docstrings

end  # baremodule Try
