export at, atend, atrow, setat!, fst, snd, third, last
export part, values, ckeys, cvalues, vec, rowpart, trimmedpart, take, takelast, takewhile
export drop, dropat, droplast, dropwhile, cut
export every
export partition, partsoflen
export getindex
export extract, extractvec, extractnested
export fieldvalues, dict
export isnil
export czip


#######################################
##  at, atend

@inline at{T,N}(a::NTuple{T,N},i) = a[i]
@inline at(a::AbstractArray, ind::Tuple) = a[ind...]
@inline at{T}(a::AbstractArray{T},i::AbstractArray) = 
    len(i) == 1 ? (size(i,1) == 1 ? at(a, i[1]) : a[subtoind(i,a)]) : error("index has len>1")
@inline at{T}(a::AbstractArray{T,1},i::Number) = a[i]
#at{T,N}(a::AbstractArray{T,N},i) = slicedim(a,N,i)
@inline at{T}(a::AbstractArray{T,2},i::Number) = col(a[:,i])
@inline at{T}(a::AbstractArray{T,3},i::Number) = a[:,:,i]
@inline at{T}(a::AbstractArray{T,4},i::Number) = a[:,:,:,i]
@inline at{T}(a::AbstractArray{T,5},i::Number) = a[:,:,:,:,i]
@inline at{T}(a::AbstractArray{T,6},i::Number) = a[:,:,:,:,:,i]
@inline at{T}(a::AbstractArray{T,7},i::Number) = a[:,:,:,:,:,:,i]
@inline at{T}(a::AbstractArray{T,8},i::Number) = a[:,:,:,:,:,:,:,i]
@inline at{T,N}(a::AbstractArray{T,N},i::Number,args...) = at(at(a,i), args...)
@inline at(a::Dict,i) = a[i]
@inline at(a::Dict,ind...) = at(at(a, ind[1]), ind[2:end]...)
@inline at(a,i) = a[i]
atend(a, i) = at(a, len(a)-i+1)
atrow(a,i) = a[i,:]


#######################################
##  setat!

@inline setat!{T}(a::AbstractArray{T,1},i::Number,v) = (a[i] = v; a)
@inline setat!{T}(a::AbstractArray{T,2},i::Number,v) = (a[:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,3},i::Number,v) = (a[:,:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,4},i::Number,v) = (a[:,:,:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,5},i::Number,v) = (a[:,:,:,:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,6},i::Number,v) = (a[:,:,:,:,:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,7},i::Number,v) = (a[:,:,:,:,:,:,i] = v; a)
@inline setat!{T}(a::AbstractArray{T,8},i::Number,v) = (a[:,:,:,:,:,:,:,i] = v; a)
@inline setat!(a,i,v) = (a[i] = v; a)

@inline fst(a) = at(a,1)
@inline snd(a) = at(a,2)
@inline third(a) = at(a,3)

import Base.last
@inline last(a::Union{AbstractArray,AbstractString}) = at(a,len(a))
@inline last(a::Union{AbstractArray,AbstractString}, n) = trimmedpart(a,(-n+1:0)+len(a))

#######################################
##  part

part(a::AbstractArray, i::Real) = part(a,[i])
part{T}(a::Vector, i::AbstractArray{T,1}) = a[i]
part{T}(a::AbstractString, i::AbstractArray{T,1}) = string(a[i])
part{T}(a::NTuple{T},i::Int) = a[i]
part{T,T2,N}(a::AbstractArray{T2,N}, i::AbstractArray{T,1}) = slicedim(a,max(2,ndims(a)),i)
part{T1,T2}(a::AbstractArray{T1,1}, i::AbstractArray{T2,1}) = a[i]
dictpart(a, inds) = Dict(map(filter(collect(keys(a)), x->in(x,inds)), x->Pair(x,at(a,x))))
part(a::Dict, inds::AbstractVector) = dictpart(a, inds)
part(a::Dict, inds...) = dictpart(a, inds)
part{T<:Real}(a::AbstractArray,i::DenseArray{T,2}) = map(i, x->at(a,x))
part(a::AbstractArray,i::Base.ValueIterator) = part(a,typed(collect(i)))

import Base.values
values(a::Dict, ind, inds...) = values(a, [ind; inds...])
values(a::Dict, inds::AbstractArray) = mapvec(inds,x->at(a,x))
ckeys(a::Dict) = collect(keys(a))
cvalues(a::Dict) = collect(values(a))
values(a, inds...) = Any[getfield(a,x) for x in inds]

import Base.vec
vec(a::Dict) = [Pair(k,a[k]) for k in keys(a)]

rowpart(a::Matrix, i) = a[i, :]

trimmedpart(a, i::Int) = trimmedpart(a, [i])
trimmedpart(a, i::UnitRange) = part(a, max(1, minimum(i)):min(len(a),maximum(i)))
trimmedpart(a, i::AbstractArray) = part(a, i[(i .>= 1) & (i .<= len(a))])

import Base.take
take(a::Union{Array, UnitRange, AbstractString}, n::Int) = part(a, 1:min(n, len(a)))
takelast(a, n::Int = 1) = part(a, max(1,len(a)-n+1):len(a))
function takewhile(a, f)
    for i in 1:len(a)
        if !f(at(a,i))
            i == 1 && return []
            return take(a,i-1)
        end
    end
    a
end

import Base.drop
drop(a::AbstractString,i::Int) = part(a,i+1:len(a))
drop(a::AbstractArray,i::Int) = part(a,i+1:len(a))
dropat(a, ind) = part(a, setdiff(1:len(a), ind))

droplast(a) = isempty(a) ? a : part(a,1:(len(a)-1))
droplast(a,i) = isempty(a) ? a : part(a,1:(len(a)-i))
function dropwhile(a, f)
    for i in 1:len(a)
        if !f(at(a,i))
            return drop(a,i-1)
        end
    end
    []
end

cut(a, i) = (dropat(a,i),part(a,i))

every(a,n) = part(a,1:n:len(a))

function partition(a,n) 
    n = min(n, len(a))
    ind = round(Int, linspace(1, len(a)+1, n+1))
    r = Array{Any}(n)
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
extractvec(a::Array, x::Any, default = nothing) = mapvec(a, y->extract(y, x, default))
extractvec(a::Array, x::Symbol, default = nothing) = mapvec(a, y->extract(y, x, default))
extract(a::Dict, x::Symbol, default = nothing) = get(a, x, default)
extract(a::Dict, x, default = nothing) = get(a, x, default)
extract(a, x::Symbol, default = nothing) = getfield(a,x)
extractnested(a::Array, args...) = map(a, x->at(x,args...))

fieldvalues(a) = [getfield(a,x) for x in sort(fieldnames(a))]
dict(a) = Dict([Pair(k,getfield(a,k)) for k in sort(fieldnames(a))])

isnil(a) = a == nothing || a == Void || (isa(a, Nullable) && isnull(a))

czip(a) = czip(a...)
function czip(a,b...)
    temp = Any[a, b...]
    mapvec(1:len(a), i->mapvec(temp, x->at(x,i)))
end

