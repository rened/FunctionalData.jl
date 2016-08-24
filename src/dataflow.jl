export row, col, reshape
export split, concat
export subtoind, indtosub
export stack, flatten, unstack, vflatten, unflatten
export riffle
export matrix, unmatrix
export lines, unlines, unzip
export findsub
export randsample, flip, flip!, flipdims

#######################################
## row, col, reshape

row(a::Number) = row([a])
row(a) = reshape(a,1,length(a))
row(a::Tuple) = reshape([a...],1,length(a))
row(a...) = row(vcat(a...))

col(a::Number) = col([a])
col(a) = reshape(a,length(a),1)
col(a::Tuple) = reshape([a...],length(a),1)
col(a...) = col(vcat(a...))

import Base.reshape
reshape{T}(a::AbstractArray, siz::Array{T,2}) = reshape(a, siz...)
function reshape(a::AbstractArray) 
    if !(ndims(a)==1 || len(a)==1)
        error("FuncionalData.reshape(a): a was expected to be a vector or len(a)==1, actual size was: $(size(a))")
    end
    r2 = sqrt(length(a))
    r3 = cbrt(length(a))
    if round(r2)==r2
        return Base.reshape(a, round(Int,r2), round(Int,r2))
    elseif round(r3)==r3
        return Base.reshape(a, round(Int,r3), round(Int,r3), round(Int,r3))
    else
        error("cannot reshape array of size $(size(a)) to a square or cube")
    end
end


#######################################
##  split, cat

import Base.split
split(a::AbstractArray,x) = split(a, y->y==x)

function split(a::AbstractArray,f::Function)
    start = 1
    r = Any[]
    for i = 1:length(a)
        if f(a[i])
            push!(r, a[start:i-1])
            start = i + 1
        elseif i == length(a)
            push!(r, a[start:i])
        end
    end
    return r
end

concat(a) = concat(a...)
concat(a...) = @p flatten Any[reject(collect(a),x->(!isa(x,Symbol) && isempty(x)))...]

#######################################
## subtoind, indtosub

function subtoind(subs, a)
    strides_ = strides(a)
    r = oneel(subs)
    for i in 1:length(strides_)
        r +=(subs[i]-1) * strides_[i]
    end
    return r
end

indtosub(i::Int, a) = indtosub([i], a)
function indtosub(inds::AbstractArray, a::Union{Array,BitArray}) 
    @p ind2sub size(a) inds | unstack | map row | col | flatten
end

#######################################
## flatten, stack, unstack, unflatten


function stack{T}(a::Array{T,1})
    r = arraylike(fst(a), len(a))
    for i = 1:len(a)
        setat!(r, i, at(a,i))
    end
    return r
end
stack{T<:Real}(a::DenseArray{T}) = a

typealias StringLike Union{Char, AbstractString}
tostring(a) = string(a)
tostring(a::AbstractString) = a
flatten(a::StringLike) = a
flatten{T<:StringLike}(a::Array{T,1}) = join(a)

function flatten{T<:StringLike}(a::Array{T,2}) 
    assert(size(a,1)==1)
    join(vec(a))
end

flatten{T<:Real,N}(a::AbstractArray{T,N}) = a
function flatten{T}(a::Array{T,1})
    if isempty(a)
        return similar(a)
    end
    if isa(a[1], StringLike)
        return join(map(a,tostring))
    end
    if VERSION.minor > 3 && !method_exists(ndims,Tuple{typeof(fst(a))})
        return a
    end
    if ndims(fst(a)) == 1
        return vcat(a...)
    end
    r = arraylike(fst(fst(a)), sum([len(x) for x in a]))
    ind = 0
    for i = 1:len(a)
        for j = 1:len(a[i])
            setat!(r, ind+j, at(a[i],j))
        end
        ind += len(a[i])
    end
    return r
end

function flatten{T}(a::Array{T,2})
    if isempty(a)
        return arraylike(a)
    end
    if isa(a[1], StringLike)
        assert(size(a,1) == 1)
        return flatten(vec(a))
    end
    ms = Base.map(x->size(x,1), a)
    ns = Base.map(x->size(x,2), a)
    msum = 0
    nsum = 0
    for mi = 1:size(a,1)
        for ni = 2:size(a,2)
            if ms[mi,ni] != ms[mi,1]
                error("flatten: ms[mi,ni] was $(ms[mi,ni]) but ms[mi,1] was $(ms[mi,1])")
            end
        end
        msum += ms[mi,1]
    end
    for ni = 1:size(a,2)
        for mi = 2:size(a,1)
            if ns[mi,ni] != ns[1,ni]
                error("flatten: ns[mi,ni] was $(ns[mi,ni]) but ns[1,ni] was $(ns[1,ni])")
            end
        end
        nsum += ns[1,ni]
    end
    
    typ = eltype(a[1])
    for i = 1:length(a)
        typ = promote_type(typ, eltype(a[i]))
    end

    r = Array(typ, msum, nsum)

    ncum = 0
    for n = 1:size(a,2)
        mcum = 0
        for m = 1:size(a,1)
            r[mcum + (1:ms[m,n]), ncum + (1:ns[m,n])] = a[m,n]
            mcum += ms[m,n]
        end
        ncum += ns[1,n]
    end
    r
end

vflatten(a) = @p transpose a | flatten | transpose

unstack(a) = Any[at(a,i) for i in 1:len(a)]


function unflatten(a,template)
    lens = @p mapvec template len
    ends = cumsum(lens)
    starts = @p droplast [1; ends+1]
    @p mapvec2 starts ends (i,j)->part(a,i:j)
end



#######################################
##  riffle

function riffle(a::AbstractString,x::Union{Char,AbstractString})
    join(a,x)
end

function riffle(a::Array{Any,1},x)
    if len(a)==1 return a end

    dims = size(a)
    #dims[end] = dims[end]*2-1
    dims = tuple(dims[1:end-1]..., dims[end]*2-1)
    r = similar(a,dims...)
    
    for i = 1:len(a)
        r[i*2-1] = a[i]
    end
    for i = 2:2:len(r)-1
        r[i] = x
    end
    return r
end


function riffle(a,x)
    if len(a)==1 return a end

    dims = size(a)
    #dims[end] = dims[end]*2-1
    dims = tuple(dims[1:end-1]..., dims[end]*2-1)
    r = similar(a,dims...)
    # println("dims: $dims   r: $r")
    for i = 1:len(a)
        setat!(r, i*2-1, at(a,i))
    end
    for i = 2:2:len(r)-1
        setat!(r, i, x)
    end
    return r
end



#######################################
##  matrix, unmatrix

matrix{T<:Number}(a::AbstractArray{T}) = @p reshape a div(length(a),len(a)) len(a)
matrix(a) = @p map a col | flatten
function unmatrix(a, example) 
    r = @p map a (x->reshape(x,siz(fst(example)))) 
    if eltype(example)==Any
        r = unstack(r)
    end
    r
end


#######################################
##  lines, unlines

function lines(a)
    r = split(a,r"\r\n|\n")
    if !isempty(r) && last(r)==""
        droplast(r)
    else
        r
    end
end
unlines(a) = join(a,'\n')


#######################################
##  randperm, randsample

import Base.randperm
_randperm = randperm
randperm(a::Number) = _randperm(a)
randperm(a) = part(a, randperm(len(a)))

randsample(a, n = 1) = part(a, rand(1:len(a), round(Int,n)))

flip!(a::Array) = a[:] = flip(a)
flip(a::Pair) = Pair(snd(a),fst(a))
flip(a::Dict) = @p vec a | map flip | Dict
flip(a) = part(a, len(a):-1:1)
function flipdims(a,d1,d2)
    dims = collect(1:ndims(a))
    dims[d1] = d2
    dims[d2] = d1
    permutedims(a, dims)
end



#####################################################
##   unzip

function unzip(a)
    forth(a) = at(a,4)
    fifth(a) = at(a,5)
    if len(fst(a)) == 2
        map(a, fst), map(a, snd)
    elseif len(fst(a)) == 3
        map(a, fst), map(a, snd), map(a, third)
    elseif len(fst(a)) == 4
        map(a, fst), map(a, snd), map(a, third), map(a, forth)
    elseif len(fst(a)) == 5
        map(a, fst), map(a, snd), map(a, third), map(a, forth), map(a, fifth)
    else
        error("FunctionalData.unzip: cannot unzip of len(fst(a))==$(len(fst(a)))")
    end
end



#####################################################
##   find

findsub(a::Union{Array,BitArray}) = indtosub(find(a.!=0), a)


