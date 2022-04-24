Try.map(f, ok::Ok) = Ok(f(ok.value))
Try.map(_, err::Err) = err

function Try.map(f, result)
    if Try.isok(result)
        Ok(f(Try.unwrap(result)))
    else
        # Need to "forget" about any Ok value type information:
        Err(Try.unwrap_err(result))
    end
end

Try.map(f, some::Some) = Some(f(something(some)))
Try.map(_, ::Nothing) = nothing

struct TryMap{F} <: Function
    f::F
end
TryMap(::Type{T}) where {T} = TryMap{Type{T}}(T)

(f::TryMap)(x) = Try.map(f.f, x)

Try.map(f::F) where {F} = TryMap(f)
