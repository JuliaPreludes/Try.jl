function Try.and_then(f::F) where {F}
    function and_then_closure(result)
        Try.and_then(f, result)
    end
end

Try.and_then(f, result::Ok)::AbstractResult = f(Try.unwrap(result))
Try.and_then(_, result::Err) = result
function Try.and_then(f, result::ConcreteResult)::ConcreteResult
    value = result.value
    if value isa Ok
        f(Try.unwrap(value))
    else
        value
    end
end

function Try.or_else(f::F) where {F}
    function or_else_closure(result)
        Try.or_else(f, result)
    end
end

Try.or_else(_, result::Ok) = result
Try.or_else(f, result::Err)::AbstractResult = f(Try.unwrap_err(result))
function Try.or_else(f, result::ConcreteResult)::ConcreteResult
    value = result.value
    if value isa Err
        f(Try.unwrap_err(value))
    else
        value
    end
end
