export showinfo

showinfo(io::IO, a::String) = showinfo(io, a, "")
function showinfo(io::IO, a, comment::String = ""; showheader = true)
    v(a::Number) = [a]
    v(a) = vec(a)
    s(a::String) = length(a)
    s(a) = size(a)
    med(a::String) = @p map a uint8 | median | round Int _ | char
    med(a) = median(a)
    if isa(a, Union(Number, Array, SharedArray, String))
        showheader && print(io,  length(comment)==0 ? "----  " : comment*"  --  ")
        println(io, "    type: $(typeof(a))   size: $(s(a))")
        try
            if !isa(a, Array) || eltype(a)<:Number 
                println(io, "    min:  $(minimum(a))   max: $(maximum(a))\n    mean: $(mean(a))   median: $(med(v(a)))")
            end
        end
    else
        println(io, "type: $(typeof(a))")
    end
    a
end
showinfo(a...; kargs...) = showinfo(STDOUT, a...; kargs...)

