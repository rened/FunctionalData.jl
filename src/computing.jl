export map, mapvec, map!, map!r, map2!, mapmap, mapmapvec, mapi, mapveci, work, worki
export map2, map3, map4, map5
export mapvec2, mapvec3, mapvec4, mapvec5
export work2, work3, work4, work5
export mapprogress, mapkeys, mapvalues
export share, unshare
export shmap, shmap!, shmap!r, shmap2!, shwork
export pmap, pmap!, pmap!r, pmap2!, pwork
export pmapvec
export lmap, lmap!, lmap!r, lmap2!, lwork
export lmapvec
export hmap, hmap!, hmap!r, hmap2!, hwork
export amap, amap2, amapvec2
export table, ptable, ltable, htable, shtable, tableany, ptableany, ltableany, htableany, shtableany
export sort, sortrev, sortpermrev, uniq, filter, select, reject
export groupdict, groupby
export minelem, maxelem, extremaelem
export isany, areall
export tee
export *
export typed
export call, apply
export fold

typealias Callable Union{Function, Type}

import Base.sort
sort(a, f::Callable; kargs...) = part(a, sortperm(mapvec(a, f); kargs...))
sort(a, key; kargs...) = part(a, sortperm(extractvec(a, key); kargs...))
sortrev(a) = sort(a; rev = true)
sortpermrev(a) = sortperm(a; rev = true)
sortrev(a, f) = sort(a,f; rev = true)

function minelem(a, f::Callable)
    b = map(a,f)
    at(a, findfirst(b .== minimum(b)))
end

function maxelem(a, f::Callable)
    b = map(a,f)
    at(a, findfirst(b .== maximum(b)))
end

function extremaelem(a, f::Callable)
    b = map(a,f)
    mi = minimum(b)
    ma = maximum(b)
    [at(a, findfirst(b .== mi)), at(a, findfirst(b .== ma))]
end


function uniq(a,f = id)
    d = Dict{Any,Int}()
    h = f == id ? a : @p mapvec a f
    for i = len(h):-1:1
        d[at(h,i)] = i
    end
    @p vec d | sort snd | map snd | part a _
end

#######################################
## map, pmap


mapvec(a, f::Callable) = Any[f(trytoview(a,i)) for i in 1:len(a)]
mapvec2(a, b, f::Callable) = Any[f(trytoview(a,i),trytoview(b,i)) for i in 1:len(a)]
mapvec3(a, b, c, f::Callable) = Any[f(trytoview(a,i),trytoview(b,i),trytoview(c,i)) for i in 1:len(a)]
mapvec4(a, b, c, d, f::Callable) = Any[f(trytoview(a,i),trytoview(b,i),trytoview(c,i),trytoview(d,i)) for i in 1:len(a)]
mapvec5(a, b, c, d, e, f::Callable) = Any[f(trytoview(a,i),trytoview(b,i),trytoview(c,i),trytoview(d,i),trytoview(e,i)) for i in 1:len(a)]

map2(a, b, f::Callable) = flatten(mapvec2(a,b,f))
map3(a, b, c, f::Callable) = flatten(mapvec3(a,b,c,f))
map4(a, b, c, d, f::Callable) = flatten(mapvec4(a,b,c,d,f))
map5(a, b, c, d, e, f::Callable) = flatten(mapvec5(a,b,c,d,e,f))

mapi(a, f::Callable ) = map2(a, 1:len(a), f)
mapveci(a, f::Callable ) = mapvec2(a, 1:len(a), f)

import Base.map
map(a, f::Callable) = map(unstack(1:len(a)), i->f(at(a,i)))
map(a::AbstractString, f::Callable) = flatten(map(unstack(a),f))
function map{T,N}(a::AbstractArray{T,N}, f::Callable)
    isempty(a) && return []

    r1 = f(fst(a))
    r = arraylike(r1, len(a), a)

    setat!(r,1,r1)
    map_(f,a,r)                         
    return r
end

@inline function map_{Tin,Nin,Tout,Nout}(f::Callable,a::AbstractArray{Tin,Nin},r::Array{Tout,Nout})
    for i = 2:len(a)
        b = f(at(a,i))
        setat!(r,i,b)
    end
end

function map(a::Dict, f::Callable; kargs...)
    isempty(a) && return a
    makeentry(a::Void) = []
    makeentry(a::Union{Tuple,Pair}) = [a]
    makeentry{T<:Union{Tuple,Pair}}(a::Array{T}) = a
    makeentry(a) = error("FunctionalData: map(::Dict), got entry of type $(typeof(a)), not one of Void, Tuple{Symbol,Any}, Array{Tuple}")

    r = @p vec a | map f | map makeentry | flatten
    d = Dict()
    for x in r
        d[fst(x)] = snd(x)
    end
    d
end

mapkeys(a::Dict, f) = map(a, x -> (f(fst(x)),snd(x)))
mapvalues(a::Dict, f) = map(a, x ->(fst(x),f(snd(x))))
mapmap(a::Dict, f) = [f(v) for (k,v) in a]

function mapmap(a, f)
    isempty(a) && return Any[]
    g(x) = map(x,f)
    map(a, g)
end

function mapmapvec(a, f)
    isempty(a) && return Any[]
    g(x) = mapvec(x,f)
    map(a, g)
end

function map{T<:Number}(a::DenseArray{T,1},f::Callable)
    isempty(a) && return []
    r1 = f(fst(a))
    r = arraylike(r1, len(a), a)
    if isviewable(r)
        rv = view(r,1)
        rv[:] = r1
        next!(rv)
        for i = 2:len(a)
            rv[:] = f(a[i]) 
            next!(rv)
        end
        r
    else
        setat!(r, 1, r1)
        map_(f,a,r)
        r
    end
end

function map{T<:Number,N}(a::DenseArray{T,N},f::Callable)
    isempty(a) && return []
    v = view(a,1)
    r1 = f(v)
    r = arraylike(r1, len(a), a)
    if isviewable(r)
        rv = view(r,1)
        rv[:] = r1
        next!(v)
        next!(rv)
        for i = 2:len(a)
            rv[:] = f(v) 
            next!(v)
            next!(rv)
        end
        r
    else
        setat!(r, 1, r1)
        map_(f,a,r)
        r
    end
end

function map2!{T<:Number,N}(a::DenseArray{T,N}, f1::Callable, f2::Callable)
    isempty(a) && return []
    v = view(a,1)
    r1 = f1(v)
    r = arraylike(r1, len(a), a)
    rv = view(r,1)
    rv[:] = r1
    map2!(view(a, 2:len(a)), view(r, 2:len(a)), f2)
    r
end

function map2!{T<:Number,N,T2<:Number,M}(a::DenseArray{T,N}, r::DenseArray{T2,M}, f::Callable)
    isempty(a) && return []
    v = view(a,1)
    rv = view(r,1)
    for i = 1:len(a)
        f(rv, v) 
        next!(v)
        next!(rv)
    end
    r
end

import Base.map!
function map!r{T<:Number,N}(a::DenseArray{T,N},f::Callable)
    isempty(a) && return a
    v = view(a,1)
    for i = 1:len(a)
        v[:] = f(v)
        next!(v)
    end
    a
end

function map!{T<:Number,N}(a::DenseArray{T,N},f::Callable)
    isempty(a) && return a
    v = view(a,1)
    for i = 1:len(a)
        f(v)
        next!(v)
    end
    a
end
 
work(a,f::Callable) = for i in 1:len(a) f(at(a,i)) end
work(a::Dict,f::Callable) = map(vec(a),(k,v)->(f;nothing))
function work{T<:Number,N}(a::DenseArray{T,N},f::Callable)
    len(a)==0 && return
    v = view(a,1)
    for i = 1:len(a)
        f(v) 
        next!(v)
    end
end
lwork(a, f) = (g(x) = (f(x);nothing); lmap(a, g); nothing)
pwork(a, f) = (g(x) = (f(x);nothing); pmap(a, g); nothing)
hwork(a, f) = (g(x) = (f(x);nothing); hmap(a, g); nothing)
shwork(a, f) = (g(x) = (f(x);nothing); shmap(a, g); nothing)
workwork(a, f) = (g(x) = (f(x);nothing); mapmap(a, g); nothing)

work2(a, b, f::Callable) = [(f(at(a,i),at(b,i)); nothing) for i in 1:len(a)]
work3(a, b, c, f::Callable) = [(f(at(a,i),at(b,i),at(c,i)); nothing) for i in 1:len(a)]
work4(a, b, c, d, f::Callable) = [(f(at(a,i),at(b,i),at(c,i),at(d,i)); nothing) for i in 1:len(a)]
work5(a, b, c, d, e_, f::Callable) = [(f(at(a,i),at(b,i),at(c,i),at(d,i),at(e_,i)); nothing) for i in 1:len(a)]
worki(a, f) = mapi(a,(x,i)->(f(x,i);nothing))
 
share{T<:Number,N}(a::DenseArray{T,N}) = convert(SharedArray, a)
share(a::SharedArray) = a
unshare(a::SharedArray) = sdata(a)

function loopovershared(r::View, a::View, f::Callable)
    v = view(a,1)
    rv = view(r,1)
    for i = 1:len(a)
        rv[:] = f(v)
        next!(v)
        next!(rv)
    end
end

function loopovershared!(a::View, f::Callable)
    v = view(a, 1)
    for i = 1:len(a)
        f(v)
        next!(v)
    end
end

function loopovershared!r(a::View, f::Callable)
    v = view(a, 1)
    for i = 1:len(a)
        v[:] = f(v)
        next!(v)
    end
end

function loopovershared2!(r::View, a::View, f::Callable)
    v = view(a,1)
    rv = view(r,1)
    for i = 1:len(a)
        f(rv, v)
        next!(v)
        next!(rv)
    end
end

function shsetup(a::SharedArray; withfirst = false)
    pids = procs(a)
    if length(pids) > 1
        pids = pids[pids .!= 1]
    end
    ind = (withfirst ? 1 : 2):len(a)
    n = min(length(pids), len(ind))
    inds = partition(ind, n)
    pids, inds, n
end

shmap{T<:Number,N}(a::DenseArray{T,N}, f::Callable) = shmap(share(a), f)
function shmap{T<:Number,N}(a::SharedArray{T,N}, f::Callable)
    pids, inds, n = shsetup(a)

    r1 = f(view(a,1))
    r = sharraylike(r1, len(a))
    rv = view(r,1)
    rv[:] = r1

    @sync for i in 1:n
        @spawnat pids[i] loopovershared(view(r, inds[i]), view(a, inds[i]), f)
    end
    r
end

shmap!{T<:Number,N}(a::DenseArray{T,N}, f::Callable) = shmap!(share(a), f)
function shmap!{T<:Number,N}(a::SharedArray{T,N}, f::Callable)
    pids, inds, n = shsetup(a; withfirst = true)

    @sync for i in 1:n
        @spawnat pids[i] loopovershared!(view(a, inds[i]), f)
    end
    a
end

shmap!r{T<:Number,N}(a::DenseArray{T,N}, f::Callable) = shmap!r(share(a), f)
function shmap!r{T<:Number,N}(a::SharedArray{T,N}, f::Callable)
    pids, inds, n = shsetup(a; withfirst = true)

    @sync for i in 1:n
        @spawnat pids[i] loopovershared!r(view(a, inds[i]), f)
    end
    a
end

shmap2!{T<:Number, N}(a::DenseArray{T,N}, f1::Callable, f2::Callable) = shmap2!(share(a), f1, f2)
function shmap2!{T<:Number, N}(a::SharedArray{T,N}, f1::Callable, f2::Callable)
    r1 = f1(view(a,1))
    r = sharraylike(r1, len(a))
    rv = view(r,1)
    rv[:] = r1
    shmap2!(a, r, f2, withfirst = false)
    r
end

shmap2!{T<:Number,N, T2<:Number, M}(a::DenseArray{T,N}, r::SharedArray{T2,M}, f::Callable) = shmap2!(share(a), r, f)
function shmap2!{T<:Number,N, T2<:Number, M}(a::SharedArray{T,N}, r::SharedArray{T2,M}, f::Callable; withfirst = true)
    pids, inds, n = shsetup(a, withfirst = withfirst)
    @sync for i in 1:n
        @spawnat pids[i] loopovershared2!(view(r, inds[i]), view(a, inds[i]), f)
    end
    r
end

###############################
#  pmap

import Base.pmap
mapper(a, f) = map(a,f)
mappervec(a, f) = mapvec(a,f)
mapper!(a, f) = map!(a,f)
mapper!r(a, f) = map!r(a,f)
mapper2!(a, f1::Callable, f2) = map2!(a,f1,f2)
mapper2!(a, r, f) = map2!(a,r,f)
pmap(a, f::Callable; kargs...) = pmap_internal(mapper, a, f; kargs...)
pmapvec(a, f::Callable; kargs...) = pmap_internal(mappervec, a, f; kargs...)
pmap!(a, f; kargs...) = pmap_internal(mapper!, a, f; kargs...)
pmap!r(a, f; kargs...) = pmap_internal(mapper!r, a, f; kargs...)
pmap2!r(a, f1::Callable, f2::Callable; kargs...) = pmap_internal2!(mapper2!, a, f1, f2; kargs...)
pmap2!r(a, r, f::Callable; kargs...) = pmap_internal2!(mapper2!, a, r, f; kargs...)

workerpool(pids) =  VERSION < v"0.5-" ? pids : WorkerPool(pids)

function pmapsetup(a; pids = workers())
    if length(pids) > 1
        pids = pids[pids .!= 1]
    end
    n = min(length(pids)*10, len(a))
    inds = partition(1:len(a), n)
    pids, inds, n
end

function pmapparts(a, inds, n) 
    if isa(a, DenseArray) && eltype(a)<:Number
        parts = [view(a, inds[i]) for i in 1:n]
    else
        parts = [part(a, inds[i]) for i in 1:n]
    end
end

function pmap_exec(g, a; nworkers = typemax(Int), vec = false, kargs...)
    pids, inds, n = pmapsetup(a; kargs...)
    parts = pmapparts(a, inds, n)
    pids = workerpool(take(pids, nworkers))
    if VERSION < v"0.5-" 
        r = Base.pmap(x->(yield();g(x)), parts, pids = pids)
    else
        r = Base.pmap(pids, x->(yield();g(x)), parts)
    end
    for x in r
        isa(x,RemoteException) && rethrow(x)
    end
    flatten(r)
end

function pmap_internal(mapf::Callable, a, f::Callable; pids = workers(), kargs...)
    g(a) = mapf(a,f)
    pmap_exec(g, a; pids = pids, kargs...)
end

function pmap_internal2!(mapf::Callable, a, f1::Callable, f2::Callable; pids = workers(), kargs...)
    g(a) = mapf(a,f1,f2)
    pmap_exec(g, a; pids = pids, kargs...)
end

function pmap_internal2!(mapf::Callable, a, r, f::Callable; nworkers = typemax(Int), kargs...)
    g(a) = mapf(fst(a), snd(a), f)
    pids, inds, n = pmapsetup(a; kargs...)
    partsa = pmapparts(a, inds, n)
    partsr = pmapparts(r, inds, n)
    parts = zip(partsa, partsr)
    pids = workerpool(take(pids,nworkers))
    @show pids
    r = Base.pmap(g, parts, pids = pids)
    flatten(r)
end

export localworkers
localworkers(pid = myid()) = (r = sort(procs(pid)); len(r) > 1 ? r[2:end] : r)

export hostpids
hostpids() = @p map unstack(workers()) procs | map sort | unique | map x->x[1]==1 && len(x)>1 ? x[2] : x[1]

export hmap, hmap!, hmap!r, hmap2!r
hmap(a, f; kargs...) = pmap_internal(mapper, a, f; pids = hostpids(), kargs...)
hmap!(a, f; kargs...) = pmap_internal(mapper!, a, f; pids = hostpids(), kargs...)
hmap!r(a, f; kargs...) = pmap_internal(mapper!r, a, f; pids = hostpids(), kargs...)
hmap2!r(a, f1::Callable, f2::Callable; kargs...) = pmap_internal2!(mapper2!, a, f1, f2; pids = hostpids(), kargs...)
hmap2!r(a, r, f::Callable; kargs...) = pmap_internal2!(mapper2!, a, r, f; pids = hostpids(), kargs...)

lmap(a, f; kargs...) = pmap_internal(mapper, a, f; pids = localworkers(), kargs...)
lmapvec(a, f; kargs...) = pmap_internal(mappervec, a, f; pids = localworkers(), kargs...)
lmap!(a, f; kargs...) = pmap_internal(mapper!, a, f; pids = localworkers(), kargs...)
lmap!r(a, f; kargs...) = pmap_internal(mapper!r, a, f; pids = localworkers(), kargs...)
lmap2!r(a, f1::Callable, f2::Callable; kargs...) = pmap_internal2!(mapper2!, a, f1, f2; pids = localworkers(), kargs...)
lmap2!r(a, r, f::Callable; kargs...) = pmap_internal2!(mapper2!, a, r, f; pids = localworkers(), kargs...)

amapvec(a,f; kargs...) = amap(a,f; n = 10, mapper = mapvec)
function amap(a,f; n = 10, mapper = map)
    n = min(len(a),n)
    a = @p partition a n
    r = Array{Any}(n)
    @sync for i in 1:n 
        @async r[i] = mapper(a[i], f)
    end
    flatten(r)
end
amap2(a,b,f; kargs...) = amap(czip(unstack(a),unstack(b)), x->f(fst(x),snd(x)); kargs...)
amapvec2(a,b,f; kargs...) = amapvec(czip(unstack(a),unstack(b)), x->f(fst(x),snd(x)); kargs...)

table(a...; kargs...) = table_internal(map, a[end], a[1:end-1]...; flat = true, kargs...)
ptable(a...; kargs...) = table_internal(pmap, a[end], a[1:end-1]...; flat = true, kargs...)
ltable(a...; kargs...) = table_internal(lmap, a[end], a[1:end-1]...; flat = true, kargs...)
htable(a...; kargs...) = table_internal(hmap, a[end], a[1:end-1]...; flat = true, kargs...)

table(f::Callable, a...; kargs...) = table_internal(map, f, a...; flat = true, kargs...)
ptable(f::Callable, a...; kargs...) = table_internal(pmap, f, a...; flat = true, kargs...)
ltable(f::Callable, a...; kargs...) = table_internal(lmap, f, a...; flat = true, kargs...)
htable(f::Callable, a...; kargs...) = table_internal(hmap, f, a...; flat = true, kargs...)

tableany(a...; kargs...) = table_internal(map, a[end], a[1:end-1]...; flat = false, kargs...)
ptableany(a...; kargs...) = table_internal(pmap, a[end], a[1:end-1]...; flat = false, kargs...)
ltableany(a...; kargs...) = table_internal(lmap, a[end], a[1:end-1]...; flat = false, kargs...)
htableany(a...; kargs...) = table_internal(hmap, a[end], a[1:end-1]...; flat = false, kargs...)

tableany(f::Callable, a...; kargs...) = table_internal(map, f, a...; flat = false, kargs...)
ptableany(f::Callable, a...; kargs...) = table_internal(pmap, f, a...; flat = false, kargs...)
ltableany(f::Callable, a...; kargs...) = table_internal(lmap, f, a...; flat = false, kargs...)
htableany(f::Callable, a...; kargs...) = table_internal(hmap, f, a...; flat = false, kargs...)

function table_internal(mapf, f, args...; flat = true, kargs...)
    a = [isa(x,Range) ? collect(x) : x for x in args]
    s = @p col [len(x) for x in a]
    if any(s.==0)
        error("FunctionalData.xtable: empty arguments, lengths of the $(len(args)) arguments are $(vec(s))")
    end
    S = tuple(s...)
    getarg(sub) = [at(a[i],sub[i]) for i in 1:length(a)]
    args = [getarg(ind2sub(S,x)) for x in 1:prod(s)]
    g(x) = f(x...)
    r = mapf(args,g; kargs...)

    if flat
        if length(fst(r))==1
            news = s
        else
            s1 = siz(fst(r))
            s1 = s1[end] == 1 ? s1[1:end-1] : s1
            news = vcat(s1,s)
        end
        @p flatten r | reshape news
    else
        @p reshape r s
    end
end

areall(a, f::Callable) = !any(a, not*f)

function isany(a, f::Callable)
    for i in 1:len(a)
        f(at(a,i)) && return true
    end
    return false
end

tee(a,f) = (f(a);a)

import Base.*
*(f::Callable, g::Callable) = (a...) -> f(g(a...))

typed{N}(a::Array{Any,N}) = isempty(a) ? [] : convert(Array{typeof(a[1]),N}, a)
typed(a) = a

import Base.filter
filter(r::Regex, f2::Callable) = error()
filter(f1::Callable, f2::Callable) = error()
function filter(a, f::Callable)
    ind = vec(typed(map(a,f)))
    isempty(ind) ? [] : part(a, ind)
end

import Base.select
select(a, f::Callable) = filter(a, f)
reject(a, f::Callable) = select(a, not*f)

groupdict(a, s::Symbol) = groupdict(a, x->x[s])
function groupdict(a,f::Function = id)
    d = Dict()
    inds = @p map a f
    for i in 1:len(a)
        ind = @p at inds i
        d[ind] = push!(get(d,ind,[]), at(a,i))
    end
    mapvalues(d,flatten)
end

groupby(a, s::Symbol) = groupby(a, x->x[s])
function groupby(a,f = id)
    r = groupdict(a,f)
    ks = collect(keys(r))
    try
        ks = sort(ks)
    end
    values(r,ks)
end

import Base.apply
apply(f::Callable, f2::Callable) = error("undefined")
apply(f::Callable, args...) = f(args...)
apply(args, f::Callable) = f(args)

function fold(a, f::Callable)
    if isempty(a)
        return a
    end
    if len(a) == 1 
        return fst(a)
    end
    r = f(fst(a), snd(a))
    for i = 3:len(a)
        r = f(r,at(a,i))
    end
    r
end
