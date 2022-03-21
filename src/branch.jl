###
### Experimental API
###

# This is very similar to Rust's `Try`` trait and `ControlFlow` enum.
# https://doc.rust-lang.org/std/ops/trait.Try.html
# https://doc.rust-lang.org/std/result/enum.Result.html
# https://doc.rust-lang.org/std/ops/enum.ControlFlow.html

struct Break{T}
    result::T
end

struct Continue{T}
    result::T
end

function branch end
function resultof end
function valueof end

###
### Implementation
###

branch(ok::Ok) = Continue(ok)
branch(err::Err) = Break(err)
branch(result::AbstractResult) =
    if Try.isok(result)
        Continue(result)
    else
        Break(result)
    end

resultof(br) = br.result

valueof(br::Continue{<:AbstractResult}) = Try.unwrap(br.result)
valueof(br::Break{<:AbstractResult}) = Try.unwrap_err(br.result)

branch(some::Some) = Continue(some)
branch(::Nothing) = Break(nothing)

valueof(br::Continue{<:Some}) = something(br.result)
valueof(::Break{Nothing}) = nothing

const var"@or_return" = var"@?"
macro or_return(ex)  # aka @?
    quote
        br = branch($(esc(ex)))
        if br isa Break
            return br.result
        else
            valueof(br)
        end
    end
end

macro and_return(ex)
    quote
        br = branch($(esc(ex)))
        if br isa Continue
            return br.result
        else
            valueof(br)
        end
    end
end

function Try.and_then(f::F) where {F}
    function and_then_closure(result)
        Try.and_then(f, result)
    end
end

function Try.and_then(f, result)
    br = branch(result)
    if br isa Continue
        f(valueof(br))
    else
        br.result
    end
end

function Try.or_else(f::F) where {F}
    function or_else_closure(result)
        Try.or_else(f, result)
    end
end

function Try.or_else(f, result)
    br = branch(result)
    if br isa Break
        f(valueof(br))
    else
        br.result
    end
end
