export zerossiz, onessiz, randsiz, randnsiz
export shzeros, shones, shrand, shrandn
export shzerossiz, shonessiz, shrandsiz, shrandnsiz
export zeroel, oneel
export +, *, repeat, nop, id,  istrue, isfalse, not, or, and, @dict
export plus, minus, times, divby, square, power
export any, anyequal, all, allequal, unequal
export inside
export minimum, maximum

#######################################
##  zerossiz, onessiz, randsiz, randnsiz

zerossiz(a::AbstractArray, T::Type = Float64) = zeros(T, a...)
onessiz(a::AbstractArray, T::Type = Float64) = ones(T, a...)
randsiz(a::AbstractArray, T::Type = Float64) = rand(T, a...)
randnsiz(a::AbstractArray) = randn(a...)
randnsiz(a::AbstractArray, T::Type) = (r = Array{T,length(a)r}(a...); fillrandn(r))

shzerossiz(a::AbstractArray, T::Type = Float64) = shzeros(T, a...)
shonessiz(a::AbstractArray, T::Type = Float64) = shones(T, a...)
shrandsiz(a::AbstractArray, T::Type = Float64) = shrand(T, a...)
shrandnsiz(a::AbstractArray, T::Type = Float64) = shrandn(a...)

fillrand(a::SharedArray{T}) where {T} = (for i = 1:length(a) a[i] = rand(T) end; a)
fillrandn(a::SharedArray{T}) where {T} = (for i = 1:length(a) a[i] = randn() end; a)
shzeros(a...) = SharedArray(Float64, a...)
shzeros(T::Type, a...) = SharedArray{T,length(a)}(a...)
shones(a...) = fill!(SharedArray{Float64,length(a)}(a...), one(Float64))
shones(T::Type, a...) = fill!(SharedArray{T,length(a)}(a...), one(T))
shrand(a...) = fillrand(SharedArray{Float64,length(a)}(a...))
shrand(T::Type, a...) = fillrand(SharedArray{T,length(a)}(a...))
shrandn(a...) = fillrandn(SharedArray{Float64,length(a)}(a...))
shrandn(T::Type, a...) = fillrandn(SharedArray{T,length(a)}(a...))




#######################################
## zeroel, oneel

zeroel(a) = zero(eltype(a))
oneel(a) = one(eltype(a))

macro dict(a...)
    esc(Expr(:call, :Dict, [Meta.parse(":$x => $x") for x in a]...))
end

import Base.*
*(a::Union{Char,AbstractString}...) = string(a...)

import Base.repeat
# repeat(a::AbstractArray{T,1}, n::Integer) where T = flatten(map(unstack(1:n), x->a))
repeat(a::AbstractArray{T,2}, n::Integer) where T = flatten(map(unstack(1:n), x->a))
repeat(a, n) = flatten(map(unstack(1:n), x->a))

nop(a...) = return
id(a) = a
id(a...) = a

istrue(a::Bool) = a
istrue(f::Function) = istrue(f())
isfalse(a) = !(istrue(a))


#######################################
##  not, or, and

not = !
or(a,b) =  a || b
and(a,b) = a && b

#######################################
###  any, anyequal, all, allequal


import Base.any
function any(a::AbstractArray, f::Function)
    v = trytoview(a,1)
    for i = 1:len(a)
        if f(trytoview(a,i,v))
            return true
        end
    end
    return false
end

anyequal(a::AbstractArray, x) = return any(a, y -> isequal(y, x))

import Base.all
function all(a::AbstractArray, f::Function)
    v = trytoview(a,1)
    for i = 1:len(a)
        if !f(trytoview(a,i,v))
            return false
        end
    end
    return true
end

allequal(a::AbstractArray, x) = all(a, y -> isequal(y, x))


#######################################
##  internal data management

newarraysize(a::Number,n::Int) = (n,)
function newarraysize(a,n::Int)
    s = siz(a)
    if s[end] == 1
        s = s[1:end-1]
    end
    tuple(s...,n)
end
 
arraylike(a::T, n::Int, array = nothing) where {T<:AbstractString} = Array{T,1}(undef, n)
function arraylike(a::T, n::Int, array = nothing) where T
    # if !(a == nothing || (array != nothing && !(eltype(array) <: Number)))
    if T <: AbstractArray
        s = newarraysize(a,n)
        r = Array{eltype(a),length(s)}(undef, s...)
    else
        return Vector{T}(undef,n)
    end
end

function sharraylike(a, n::Int)
    s = newarraysize(a,n)
    SharedArray{eltype(a),length(s)}(s...)
end

plus(a,b) = a.+b
minus(a,b) = a.-b
times(a,b) = a.*b
divby(a,b) = a./b
unequal(a,b) = !(isequal(a,b))
square(a) = a.*a
power(a,n) = a.^n

inside = in

import Base: minimum, maximum
minimum(::Type{T} = Float64) where {T<:AbstractFloat} = -floatmax(T)
maximum(::Type{T} = Float64) where {T<:AbstractFloat} =  floatmax(T)
minimum(::Type{T}) where {T<:Number} = typemin(T)
maximum(::Type{T}) where {T<:Number} = typemax(T)

