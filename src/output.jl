export showinfo

showinfo(io::IO, a::String) = showinfo(io, a, "")
function showinfo(io::IO, a, comment::String = "")
    v(a::Number) = [a]
    v(a) = vec(a)
    s(a::String) = length(a)
    s(a) = size(a)
    med(a::String) = @p map a uint8 | median | round Integer _ | char
    med(a) = median(a)
    if isa(a, Union(Number, Array, SharedArray, String))
        print( isempty(comment) ? "--  " : comment*"  --  ")
        println("type: $(typeof(a))   size: $(s(a))")
        try
            if !isa(a, Array) || eltype(a)<:Number 
                println("    min:  $(minimum(a))   max: $(maximum(a))\n    mean: $(mean(a))   median: $(med(v(a)))")
            end
        end
    else
        println("type: $(typeof(a))")
    end
    a
end
showinfo(a, comment::String = "") = showinfo(STDOUT, a, comment)

