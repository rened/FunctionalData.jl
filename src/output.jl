export tee, showinfo, makeliteral

tee(a...) = (@show a a[2] a[1]; a[2](part(a,vcat(1, 3:length(a)))); return a[end])

function showinfo(io::IO, a)
    v(a::Number) = [a]
    v(a) = vec(a)
    s(a::ASCIIString) = length(a)
    s(a) = size(a)
    med(a::ASCIIString) = @p map a uint8 | median | round Integer _ | char
    med(a) = median(a)
    if isa(a, Union(Number, Array, SharedArray, ASCIIString))
        println("type: $(typeof(a))   size: $(s(a))")
        try
            if !isa(a, Array) || eltype(a)<:Number 
                println("min:  $(minimum(a))   max: $(maximum(a))   mean: $(mean(a))   median: $(med(v(a)))")
            end
        end
    else
        println("type: $(typeof(a))")
    end
    a
end
showinfo(a) = showinfo(STDOUT, a)

function makeliteral(a) 
    buf = IOBuffer()
    showall(buf,a)
    return takebuf_string(buf)
end


