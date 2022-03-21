    TryExperimental.resultof(branch) -> result 
    TryExperimental.resultof(branch::Continue{<:Ok}) ->  result::Ok
    TryExperimental.resultof(branch::Break{<:Err}) ->  result::Err
    TryExperimental.resultof(branch::Continue{<:Some}) ->  result::Some
    TryExperimental.resultof(branch::Break{Nothing}) -> nothing
