baremodule Try

export Ok, Err, Result

using Base: Base, Exception

abstract type AbstractResult{T,E} end

struct Ok{T} <: AbstractResult{T,Union{}}
    value::T
end

struct Err{E} <: AbstractResult{Union{},E}
    value::E
    backtrace::Union{Nothing,typeof(Base.backtrace())}
end

const DynamicResult{T,E} = Union{Ok{T},Err{E}}

function _ConcreteResult end

struct ConcreteResult{T,E} <: AbstractResult{T,E}
    value::DynamicResult{T,E}
    global _ConcreteResult(::Type{T}, ::Type{E}, value) where {T,E} = new{T,E}(value)
end

const ConcreteOk{T} = ConcreteResult{T,Union{}}
const ConcreteErr{E} = ConcreteResult{Union{},E}

const Result{T,E} = Union{ConcreteResult{<:T,<:E},DynamicResult{<:T,<:E}}

function throw end

function unwrap end
function unwrap_err end

function oktype end
function errtype end
function isok end
function iserr end

function enable_errortrace end
function disable_errortrace end

function istryable end

# Core exceptions
struct IsOkError <: Exception
    ok::AbstractResult{<:Any,Union{}}
end

# Basic exceptions
abstract type NotImplementedError <: Exception end
abstract type ClosedError <: Exception end
abstract type EmptyError <: Exception end
abstract type FullError <: Exception end

baremodule Causes
function notimplemented end
function empty end
function closed end
end  # baremodule Cause

macro and_then end
macro or_else end
macro return_err end
function var"@return" end
function var"@function" end

function and_then end
function or_else end

module Internal

import ..Try: @return, @return_err, @and_then, @or_else, @function
using ..Try:
    AbstractResult,
    Causes,
    ConcreteErr,
    ConcreteOk,
    ConcreteResult,
    DynamicResult,
    Err,
    Ok,
    Result,
    Try,
    _ConcreteResult

using Base.Meta: isexpr

include("utils.jl")
include("core.jl")
include("show.jl")
include("errortrace.jl")
include("function.jl")
include("causes.jl")

include("tools.jl")
include("sugar.jl")

end  # module Internal

Internal.define_docstrings()

end  # baremodule Try
