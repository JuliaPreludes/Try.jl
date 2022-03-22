using Try

import ..TryExperimental: @tryable, istryable
using ..TryExperimental: TryExperimental
include("tryable.jl")

macro exported_function(name::Symbol)
    m = @__MODULE__
    quote
        $m.@tryable($name)
        export $name
    end |> esc
end
