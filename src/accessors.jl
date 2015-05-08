export at, setat!, fst, snd, third, last
export part, rowpart, trimmedpart, take, takelast, drop, dropat, droplast, partition, partsoflen
export getindex
export extract


#######################################
##  at

@compat @inline at{T,N}(a::NTuple{T,N},i) = a[i]
@compat @inline at(a::AbstractArray, ind::Tuple) = a[ind...]
@compat @inline at{T}(a::AbstractArray{T},i::AbstractArray) = 
    len(i) == 1 ? (size(i,1) == 1 ? at(a, i[1]) : a[subtoind(i,a)]) : error("index has len>1")
@compat @inline at{T}(a::AbstractArray{T,1},i::Number) = a[i]
#at{T,N}(a::AbstractArray{T,N},i) = slicedim(a,N,i)
@compat @inline at{T}(a::AbstractArray{T,2},i::Number) = col(a[:,i])
@compat @inline at{T}(a::AbstractArray{T,3},i::Number) = a[:,:,i]
@compat @inline at{T}(a::AbstractArray{T,4},i::Number) = a[:,:,:,i]
@compat @inline at{T}(a::AbstractArray{T,5},i::Number) = a[:,:,:,:,i]
@compat @inline at{T}(a::AbstractArray{T,6},i::Number) = a[:,:,:,:,:,i]
@compat @inline at{T}(a::AbstractArray{T,7},i::Number) = a[:,:,:,:,:,:,i]
@compat @inline at{T}(a::AbstractArray{T,8},i::Number) = a[:,:,:,:,:,:,:,i]
@compat @inline at(a,i) = a[i]


#######################################
##  setat!

@compat @inline setat!{T}(a::AbstractArray{T,1},i::Number,v) = (a[i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,2},i::Number,v) = (a[:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,3},i::Number,v) = (a[:,:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,4},i::Number,v) = (a[:,:,:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,5},i::Number,v) = (a[:,:,:,:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,6},i::Number,v) = (a[:,:,:,:,:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,7},i::Number,v) = (a[:,:,:,:,:,:,i] = v; a)
@compat @inline setat!{T}(a::AbstractArray{T,8},i::Number,v) = (a[:,:,:,:,:,:,:,i] = v; a)
@compat @inline setat!(a,i,v) = (a[i] = v; a)

@compat @inline fst(a) = at(a,1)
@compat @inline snd(a) = at(a,2)
@compat @inline third(a) = at(a,3)

import Base.last
@compat @inline last(a::Union(AbstractArray,String)) = at(a,len(a))
@compat @inline last(a::Union(AbstractArray,String), n) = trimmedpart(a,(-n+1:0)+len(a))

#######################################
##  part

part(a, i::Real) = part(a,[i])
part{T}(a::Vector, i::AbstractArray{T,1}) = a[i]
part{T}(a::String, i::AbstractArray{T,1}) = string(a[i])
part{T}(a::NTuple{T},i::Int) = a[i]
part{T,T2,N}(a::AbstractArray{T2,N}, i::AbstractArray{T,1}) = slicedim(a,max(2,ndims(a)),i)
part{T1,T2}(a::AbstractArray{T1,1}, i::AbstractArray{T2,1}) = a[i]
part{T}(a::Dict, i::AbstractArray{T,1}) = Base.map(x->at(a,x),i)
part{T<:Real}(a,i::DenseArray{T,2}) = map(i, x->at(a,x))

rowpart(a::Matrix, i) = a[i, :]

trimmedpart(a, i::UnitRange) = part(a, max(1, minimum(i)):min(len(a),maximum(i)))
trimmedpart(a, i) = part(a, i[(i .>= 1) & (i .<= len(a))])

import Base.take
take(a::Union(Array, UnitRange, String), n::Int) = part(a, 1:min(n, len(a)))
takelast(a, n::Int = 1) = part(a, max(1,len(a)-n+1):len(a))

drop(a,i) = part(a,i+1:len(a))
dropat(a, ind) = part(a, setdiff(1:len(a), ind))

droplast(a) = part(a,1:max(1,len(a)-1))
droplast(a,i) = part(a,1:max(1,len(a)-i))

function partition(a,n) 
    n = min(n, len(a))
    ind = round(Int, linspace(1, len(a)+1, n+1))
    r = cell(n)
    for i = 1:n
        r[i] = part(a, ind[i]:ind[i+1]-1)
    end
    r
end

function partsoflen(a,n::Int)
    s = len(a)
    [part(a, i:floor(min(s,i+n-1))) for i in 1:n:s]
end
            
extract(a::Array, x::Any, default = nothing) = map(a, y->extract(y, x, default))
extract(a::Array, x::Symbol, default = nothing) = map(a, y->extract(y, x, default))
extract(a::Dict, x::Symbol, default = nothing) = get(a, x, default)
extract(a::Dict, x, default = nothing) = get(a, x, default)
extract(a, x::Symbol, default = nothing) = a.(x)


