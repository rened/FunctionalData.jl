export View, isviewable, view!, next!, trytoview

import Base: size, getindex, setindex!

mutable struct View{T,N,M} <: AbstractArray{T,N}
    parent::AbstractArray{T,M}
    v::SubArray{T,N}
    ind::Int
end

size(a::View, args...) = size(a.v, args...)
getindex(a::View, args...) = getindex(a.v, args...)
function setindex!(a::View, value, args...)
    setindex!(a.v, value, args...)
    value
end


isviewable(a::Union{DenseArray,SharedArray}{T}) where {T<:Number} = true
isviewable(a) = false

function view(a::AbstractArray{T,1}, i::Int = 1) where T
    View(a, Base.view(a, i:i), i)
end

function view(a::AbstractArray, i::Int = 1)
    View(a, selectdim(a, ndims(a), i:i), i)
end

function view!(a::AbstractArray{T,N}, i::Int, v::View{T,N}) where T where N
    @assert v.parent == a
    v.v = view(a, i)
    v
end

function view(a::AbstractArray, ind::UnitRange)
    selectdim(a, ndims(a), ind)
end

function next!(v::View)
    v.ind += v.ind < len(v.parent) ? 1 : 0
    v.v = selectdim(v.parent, ndims(v.parent), v.ind:v.ind)
    v
end

trytoview(a::Vector{T}, i = 1) where {T<:Number} = at(a,i)
trytoview(a::Vector{T}, i, v::View) where {T<:Number} = at(a,i)
trytoview(a::DenseArray{T}, i = 1) where {T<:Number} = view(a, i)
trytoview(a::DenseArray{T}, i, v::View) where {T<:Number} = view!(a, i, v)
trytoview(a, i) = at(a, i)
trytoview(a, i, v) = at(a, i)
# trytoview(a, i) = view(a, i)
# trytoview(a, i, v) = view(a, i)

