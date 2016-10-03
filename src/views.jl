export View, isviewable, view!, next!, trytoview

if VERSION < v"0.5-"
    unsafe_view = pointer_to_array
else
    unsafe_view(p,s) = unsafe_wrap(Array, p, s)
end

typealias View Array
offset = 1

isviewable{T<:Real}(a::Union{DenseArray,SharedArray}{T}) = true
isviewable(a) = false

view{T<:Real}(a::SharedArray{T}, i::Int = 1) = view(sdata(a), i)
view!{T<:Real}(a::SharedArray{T}, i::Int, v::View{T}) = view(sdata(a), i, v)

function view{T<:Real}(a::DenseArray{T}, i::Int = 1)
    s = size(a)
    if length(s) > 2
        s = s[1:end-1]
    elseif length(s) == 2
        s = (s[1],1)
    else
        s = (1,)
    end
    view!(a, i, convert(View, unsafe_view(pointer(a), s)))
end

function view!{T<:Real}(a::DenseArray{T}, i::Int, v::View{T})
    p = convert(Ptr{Ptr{T}}, pointer_from_objref(v))
    unsafe_store!(p, pointer(a) + (i-1) * length(v) * sizeof(T), offset)
    v::View{T}
end

function view{T<:Real}(a::DenseArray{T}, ind::UnitRange)
    if len(ind) == 0
        return Array{T}([size(a)...][1:end-1]...,0)
    end
    s = size(a)[1:end-1]
    p = pointer(a) + (fst(ind)-1) * prod(s) * sizeof(T)
    convert(View, unsafe_view(p, tuple(s..., length(ind)) ))::View{T}
end

@inline function next!{T}(v::View{T})
    p = convert(Ptr{Ptr{T}}, pointer_from_objref(v))
    datap = unsafe_load(p, offset)
    unsafe_store!(p, datap + length(v) * sizeof(T), offset)
    v
end

trytoview{T<:Real}(a::DenseVector{T}, i = 1) = at(a,i)
trytoview{T<:Real}(a::DenseVector{T}, i, v::View) = at(a,i)
trytoview{T<:Real}(a::DenseArray{T}, i = 1) = view(a, i)
trytoview{T<:Real}(a::DenseArray{T}, i, v::View) = view!(a, i, v)
trytoview(a, i) = at(a, i)
trytoview(a, i, v) = at(a, i)

