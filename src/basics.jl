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

zerossiz(a::Array, typ::Type = Float64) = zeros(typ, a...)
onessiz(a::Array, typ::Type = Float64) = ones(typ, a...)
randsiz(a::Array, typ::Type = Float64) = rand(typ, a...)
randnsiz(a::Array) = randn(a...)
randnsiz(a::Array, typ::Type) = (r = Array(typ, a...); fillrandn(r))

shzerossiz(a::Array, typ::Type = Float64) = shzeros(typ, a...)
shonessiz(a::Array, typ::Type = Float64) = shones(typ, a...)
shrandsiz(a::Array, typ::Type = Float64) = shrand(typ, a...)
shrandnsiz(a::Array, typ::Type = Float64) = shrandn(a...)

fillrand{T}(a::SharedArray{T}) = (for i = 1:length(a) a[i] = rand(T) end; a)
fillrandn{T}(a::SharedArray{T}) = (for i = 1:length(a) a[i] = randn() end; a)
shzeros(a...) = SharedArray(Float64, a...)
shzeros(typ::Type, a...) = SharedArray(typ, a...)
shones(a...) = fill!(SharedArray(Float64, a...), one(typ))
shones(typ::Type, a...) = fill!(SharedArray(typ, a...), one(typ))
shrand(a...) = fillrand(SharedArray(Float64, a...))
shrand(typ::Type, a...) = fillrand(SharedArray(typ, a...))
shrandn(a...) = fillrandn(SharedArray(Float64, a...))
shrandn(typ::Type, a...) = fillrandn(SharedArray(typ, a...))




#######################################
## zeroel, oneel

zeroel(a) = zero(eltype(a))
oneel(a) = one(eltype(a))

macro dict(syms...)
    Expr(:typed_dict, :(Any=>Any), Any[ :($(string(s))=>$(esc(s))) for s in syms ]...)
end

import Base.*
*(a::Union(Char,String)...) = string(a...)

import Base.repeat
repeat(a::Char,n::Int) = repeat(string(a), n)
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
 
arraylike{T<:String}(a::T, n::Int, array = nothing) = Array(T, n)
function arraylike(a, n::Int, array = nothing)
    if a == nothing || (array != nothing && !(eltype(array) <: Number))
        return cell(n)
    end
    r = Array(eltype(a), newarraysize(a,n)...)
end

# function arraylike(a::Array, n::Int, array = nothing)
#     if isempty(a)
#         return cell(n)
#     end
#     r = Array(eltype(a), newarraysize(a,n)...)
# end

# arraylike(a, n::Int, array = nothing) = return cell(n)

sharraylike(a, n::Int) = SharedArray(eltype(a), newarraysize(a,n)...)

function copy(from, to)
    if length(from)!=length(to)
        error("in copy(from,to::SubArray): lengths do not match. length(from): $(length(from))  length(to): $(length(to))")
    end
    for i = 1:length(from)
        to[i] = from[i]
    end
end

plus(a,b) = a.+b
minus(a,b) = a.-b
times(a,b) = a.*b
divby(a,b) = a./b
unequal(a,b) = !(isequal(a,b))
square(a) = a.*a
power(a,n) = a.^n

inside = in

if VERSION >= v"0.4-"
    import Base: minimum, maximum
    minimum{T<:FloatingPoint}(::Type{T}) = -realmax(T)
    maximum{T<:FloatingPoint}(::Type{T}) =  realmax(T)
    minimum{T<:Number}(::Type{T}) = typemin(T)
    maximum{T<:Number}(::Type{T}) = typemax(T)
end

