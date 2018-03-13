export View, isviewable, view!, next!, trytoview

unsafe_view(p,s) = unsafe_wrap(Array, p, s)

const View = Array
offset = 1

isviewable(a::Union{DenseArray,SharedArray}{T}) where {T<:Number} = true
isviewable(a) = false

view(a::SharedArray{T}, i::Int = 1) where {T<:Number} = view(sdata(a), i)
view!(a::SharedArray{T}, i::Int, v::View{T}) where {T<:Number} = view(sdata(a), i, v)

function view(a::DenseArray{T}, i::Int = 1) where {T<:Number}
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

function view!(a::DenseArray{T}, i::Int, v::View{T}) where {T<:Number}
    p = convert(Ptr{Ptr{T}}, pointer_from_objref(v))
    unsafe_store!(p, pointer(a) + (i-1) * length(v) * sizeof(T), offset)
    v::View{T}
end

function view(a::DenseArray{T}, ind::UnitRange) where {T<:Number}
    if len(ind) == 0
        return Array{T}([size(a)...][1:end-1]...,0)
    end
    s = size(a)[1:end-1]
    p = pointer(a) + (fst(ind)-1) * prod(s) * sizeof(T)
    convert(View, unsafe_view(p, tuple(s..., length(ind)) ))::View{T}
end

@inline function next!(v::View{T}) where {T}
    p = convert(Ptr{Ptr{T}}, pointer_from_objref(v))
    datap = unsafe_load(p, offset)
    unsafe_store!(p, datap + length(v) * sizeof(T), offset)
    v
end

trytoview(a::DenseVector{T}, i = 1) where {T<:Number} = at(a,i)
trytoview(a::DenseVector{T}, i, v::View) where {T<:Number} = at(a,i)
trytoview(a::DenseArray{T}, i = 1) where {T<:Number} = view(a, i)
trytoview(a::DenseArray{T}, i, v::View) where {T<:Number} = view!(a, i, v)
trytoview(a, i) = at(a, i)
trytoview(a, i, v) = at(a, i)

