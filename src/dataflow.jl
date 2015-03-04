export row, col, reshape
export split, concat
export subtoind, indtosub
export stack, flatten, unstack
export riffle
export matrix, unmatrix
export lines, unlines, unzip
export findsub
export randsample

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
reshape{T}(a::Array, siz::Array{T,2}) = reshape(a, siz...)
function reshape(a::Array) 
    if !(ndims(a)==1 || len(a)==1)
        error("FuncionalData.reshape(a): a was expected to be a vector or len(a)==1, actual size was: $(size(a))")
    end
    r2 = sqrt(length(a))
    r3 = cbrt(length(a))
    if round(r2)==r2
        return Base.reshape(a, int(r2), int(r2))
    elseif round(r3)==r3
        return Base.reshape(a, int(r3), int(r3), int(r3))
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

function concat(a...) 
    try
        flatten(Any[a...])
    catch
        Any[a...]
    end
end


#######################################
## subtoind, indtosub

function subtoind(subs,a)
    strides_ = strides(a)
    r = 1;
    [r += (subs[i]-1)*at(strides_,i) for i in 1:length(strides_)]
    return r
end

indtosub(i::Int, a) = indtosub([i], a)
function indtosub(inds::AbstractArray, a::Union(Array,BitArray)) 
    @p ind2sub size(a) inds | unstack | map row | col | flatten
end

#######################################
## flatten, stack, unstack


function stack{T}(a::Array{T,1})
    r = arraylike(fst(a), len(a))
    for i = 1:len(a)
        setat!(r, i, at(a,i))
    end
    return r
end
stack{T<:Real}(a::DenseArray{T}) = a

typealias StringLike Union(Char, AbstractString)
tostring(a) = string(a)
tostring(a::AbstractString) = a
flatten(a::StringLike) = a
flatten{T<:StringLike}(a::Array{T,1}) = join(a)

function flatten{T<:StringLike}(a::Array{T,2}) 
    assert(size(a,1)==1)
    join(vec(a))
end

function flatten{T}(a::Array{T,1})
    if isempty(a)
        return arraylike(a)
    end
    if isa(a[1], StringLike)
        return join(map(a,tostring))
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


unstack{T,N}(a::AbstractArray{T,N}) = Any[at(a,i) for i in 1:len(a)]
unstack(a::Tuple) = Any[at(a,i) for i in 1:len(a)]

unstack(a::ASCIIString) = Any[at(a,i) for i in 1:len(a)]




#######################################
##  riffle

function riffle(a::ASCIIString,x::Union(Char,ASCIIString))
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

lines(a) = split(a,r"\r\n|\n")
unlines(a) = join(a,'\n')


#######################################
##  randperm, randsample

import Base.randperm
_randperm = randperm
randperm(a::Number) = _randperm(a)
randperm(a) = part(a, randperm(len(a)))

randsample(a, n) = part(a, rand(1:len(a), int(n)))



#####################################################
##   unzip

function unzip(a)
    if isempty(a)
        return Any[]
    end
    
    n = len(fst(a))
    assert(all(Base.map(x -> len(x)==n, a)))
    r = Any[cell(len(a)) for j = 1:n]
    for i = 1:len(a)
        for j = 1:n
            r[j][i] = at(at(a, i), j)
        end
    end
    for i = 1:len(r)
        try
            r[i] = flatten(r[i])
        end
    end
    r
end

#####################################################
##   find

findsub(a::Union(Array,BitArray)) = indtosub(find(a.!=0), a)


