using Try

macro exported_function(name::Symbol)
    quote
        $Try.@function($name)
        export $name
    end |> esc
end
