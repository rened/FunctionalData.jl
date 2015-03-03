export map, map!, map!r, map2!, mapmap, work
export share, unshare
export shmap, shmap!, shmap!r, shmap2!, shwork
export pmap, pmap!, pmap!r, pmap2!, pwork
export lmap, lmap!, lmap!r, lmap2!, lwork
export hmap, hmap!, hmap!r, hmap2!, hwork
export table, ptable, ltable, shtable, tableany, ptableany, ltableany, shtableany
export sort, sortrev, unique

import Base.sort
sort(a, f; kargs...) = part(a, sortperm(vec(map(a, f)); kargs...))
sortrev(a, f) = sort(a,f; rev = true)

import Base.unique
unique(a,f) = @p part a unique(map(a,f))

#######################################
## map, pmap


import Base.map
map(a::String, f::Function) = flatten(map(unstack(a),f))
function map{T,N}(a::AbstractArray{T,N}, f::Function)
    isempty(a) && return Any[]

    r1 = f(fst(a))
    r = arraylike(r1, len(a), a)

    setat!(r,1,r1)
    map_(f,a,r)                         
    return r
end

@compat @inline function map_{Tin,Nin,Tout,Nout}(f::Function,a::AbstractArray{Tin,Nin},r::Array{Tout,Nout})
    for i = 2:len(a)
        b = f(at(a,i))
        setat!(r,i,b)
    end
end

map(a::Dict, f::Function) = @compat Dict(Base.map((x) -> (x[1], f(x[2])), a))
function mapmap(a, f)
    isempty(a) && return Any[]
    g = x -> map(x,f)
    map(a, g)
end

function map{T<:Real,N}(a::DenseArray{T,N},f::Function)
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

function map2!{T<:Real,N}(a::DenseArray{T,N}, f1::Function, f2::Function)
    v = view(a,1)
    r1 = f1(v)
    r = arraylike(r1, len(a), a)
    rv = view(r,1)
    rv[:] = r1
    map2!(view(a, 2:len(a)), view(r, 2:len(a)), f2)
    r
end

function map2!{T<:Real,N,T2<:Real,M}(a::DenseArray{T,N}, r::DenseArray{T2,M}, f::Function)
    v = view(a,1)
    rv = view(r,1)
    for i = 1:len(a)
        f(rv, v) 
        next!(v)
        next!(rv)
    end
    r
end
function map!r{T<:Real,N}(a::DenseArray{T,N},f::Function)
    v = view(a,1)
    for i = 1:len(a)
        v[:] = f(v)
        next!(v)
    end
    a
end
function map!{T<:Real,N}(a::DenseArray{T,N},f::Function)
    v = view(a,1)
    for i = 1:len(a)
        f(v)
        next!(v)
    end
    a
end
 
work(a,f::Function) = (for i in 1:len(a) f(at(a,i)) end; nothing)
function work{T<:Real,N}(a::DenseArray{T,N},f::Function)
    v = view(a,1)
    for i = 1:len(a)
        f(v) 
        next!(v)
    end
end
lwork(a, f) = (g(x) = (f(x);uint8(0)); lwork(a, g); nothing)
pwork(a, f) = (g(x) = (f(x);uint8(0)); pwork(a, g); nothing)
shwork(a, f) = (g(x) = (f(x);uint8(0)); shwork(a, g); nothing)
workwork(a, f) = (g(x) = (f(x);uint8(0)); workwork(a, g); nothing)
 
share{T<:Real,N}(a::DenseArray{T,N}) = convert(SharedArray, a)
share(a::SharedArray) = a
unshare(a::SharedArray) = sdata(a)

function loopovershared(r::View, a::View, f::Function)
    v = view(a,1)
    rv = view(r,1)
    for i = 1:len(a)
        rv[:] = f(v)
        next!(v)
        next!(rv)
    end
end

function loopovershared!(a::View, f::Function)
    v = view(a, 1)
    for i = 1:len(a)
        f(v)
        next!(v)
    end
end

function loopovershared!r(a::View, f::Function)
    v = view(a, 1)
    for i = 1:len(a)
        v[:] = f(v)
        next!(v)
    end
end

function loopovershared2!(r::View, a::View, f::Function)
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

shmap{T<:Real,N}(a::DenseArray{T,N}, f::Function) = shmap(share(a), f)
function shmap{T<:Real,N}(a::SharedArray{T,N}, f::Function)
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

shmap!{T<:Real,N}(a::DenseArray{T,N}, f::Function) = shmap!(share(a), f)
function shmap!{T<:Real,N}(a::SharedArray{T,N}, f::Function)
    pids, inds, n = shsetup(a; withfirst = true)

    @sync for i in 1:n
        @spawnat pids[i] loopovershared!(view(a, inds[i]), f)
    end
    a
end

shmap!r{T<:Real,N}(a::DenseArray{T,N}, f::Function) = shmap!r(share(a), f)
function shmap!r{T<:Real,N}(a::SharedArray{T,N}, f::Function)
    pids, inds, n = shsetup(a; withfirst = true)

    @sync for i in 1:n
        @spawnat pids[i] loopovershared!r(view(a, inds[i]), f)
    end
    a
end

shmap2!{T<:Real, N}(a::DenseArray{T,N}, f1::Function, f2::Function) = shmap2!(share(a), f1, f2)
function shmap2!{T<:Real, N}(a::SharedArray{T,N}, f1::Function, f2::Function)
    r1 = f1(view(a,1))
    r = sharraylike(r1, len(a))
    rv = view(r,1)
    rv[:] = r1
    shmap2!(a, r, f2, withfirst = false)
    r
end

shmap2!{T<:Real,N, T2<:Real, M}(a::DenseArray{T,N}, r::SharedArray{T2,M}, f::Function) = shmap2!(share(a), r, f)
function shmap2!{T<:Real,N, T2<:Real, M}(a::SharedArray{T,N}, r::SharedArray{T2,M}, f::Function; withfirst = true)
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
mapper!(a, f) = map!(a,f)
mapper!r(a, f) = map!r(a,f)
mapper2!(a, f1::Function, f2) = map2!(a,f1,f2)
mapper2!(a, r, f) = map2!(a,r,f)
pmap(a, f::Function; kargs...) = pmap_internal(mapper, a, f; kargs...)
pmap!(a, f; kargs...) = pmap_internal(mapper!, a, f; kargs...)
pmap!r(a, f; kargs...) = pmap_internal(mapper!r, a, f; kargs...)
pmap2!r(a, f1::Function, f2::Function; kargs...) = pmap_internal2!(mapper2!, a, f1, f2; kargs...)
pmap2!r(a, r, f::Function; kargs...) = pmap_internal2!(mapper2!, a, r, f; kargs...)

function pmapsetup(a; pids = workers())
    if length(pids) > 1
        pids = pids[pids .!= 1]
    end
    n = min(length(pids)*10, len(a))
    inds = partition(1:len(a), n)
    pids, inds, n
end

function pmapparts(a, inds, n) 
    if isa(a, DenseArray) && eltype(a)<:Real
        parts = [view(a, inds[i]) for i in 1:n]
    else
        parts = [part(a, inds[i]) for i in 1:n]
    end
end

function pmap_exec(g, a; kargs...)
    pids, inds, n = pmapsetup(a; kargs...)
    parts = pmapparts(a, inds, n)
    if VERSION.minor >= 4
        r = Base.pmap(g, parts, pids = pids)
    else
        r = pmapon(g, parts, pids = pids)
    end
    flatten(r)
end

function pmapon(f, lsts...; err_retry=true, err_stop=false, pids = workers())
    len = length(lsts)
    results = Dict{Int,Any}()
    retryqueue = []
    task_in_err = false
    is_task_in_error() = task_in_err
    set_task_in_error() = (task_in_err = true)
    nextidx = 0
    getnextidx() = (nextidx += 1)
    states = [start(lsts[idx]) for idx in 1:len]
    function getnext_tasklet()
        if is_task_in_error() && err_stop
            return nothing
        elseif !any(idx->done(lsts[idx],states[idx]), 1:len)
            nxts = [next(lsts[idx],states[idx]) for idx in 1:len]
            for idx in 1:len; states[idx] = nxts[idx][2]; end
                nxtvals = [x[1] for x in nxts]
                return (getnextidx(), nxtvals)
            elseif !isempty(retryqueue)
                return shift!(retryqueue)
            else
                return nothing
            end
        end
        @sync begin
            for wpid in pids
                @async begin
                    tasklet = getnext_tasklet()
                    while (tasklet != nothing)
                        (idx, fvals) = tasklet
                        try
                            result = remotecall_fetch(wpid, f, fvals...)
                            if isa(result, Exception)
                                ((wpid == myid()) ? rethrow(result) : throw(result))
                            else
                                results[idx] = result
                            end
                        catch ex
                        if err_retry
                            push!(retryqueue, (idx,fvals, ex))
                        else
                            results[idx] = ex
                        end
                        set_task_in_error()
                        break # remove this worker from accepting any more tasks
                    end
                    tasklet = getnext_tasklet()
                end
            end
        end
    end
    for failure in retryqueue
        results[failure[1]] = failure[3]
    end
    [results[x] for x in 1:nextidx]
end


function pmap_internal(mapf::Function, a, f::Function; kargs...)
    g(a) = mapf(a,f)
    pmap_exec(g, a; kargs...)
end

function pmap_internal2!(mapf::Function, a, f1::Function, f2::Function; kargs...)
    g(a) = mapf(a,f1,f2)
    pmap_exec(g, a; kargs...)
end

function pmap_internal2!(mapf::Function, a, r, f::Function; kargs...)
    g(a) = mapf(fst(a), snd(a), f)
    pids, inds, n = pmapsetup(a; kargs...)
    partsa = pmapparts(a, inds, n)
    partsr = pmapparts(r, inds, n)
    parts = zip(partsa, partsr)
    if VERSION.minor >= 4
        r = Base.pmap(g, parts, pids = pids)
    else
        r = Base.pmap(g, parts)
    end
    flatten(r)
end

export localworkers
localworkers(pid = myid()) = (r = sort(procs(pid)); len(r) > 1 ? r[2:end] : r)

export hostpids
hostpids() = @p map unstack(workers()) procs | map sort | unique | map x->x[1]==1 && len(x)>1 ? x[2] : x[1]

export hmap, hmap!, hmap!r, hmap2!r
hmap(a, f) = pmap_internal(mapper, a, f; pids = hostpids())
hmap!(a, f) = pmap_internal(mapper!, a, f; pids = hostpids())
hmap!r(a, f) = pmap_internal(mapper!r, a, f; pids = hostpids())
hmap2!r(a, f1::Function, f2::Function) = pmap_internal2!(mapper2!, a, f1, f2; pids = hostpids())
hmap2!r(a, r, f::Function) = pmap_internal2!(mapper2!, a, r, f; pids = hostpids())

lmap(a, f) = pmap_internal(mapper, a, f; pids = localworkers())
lmap!(a, f) = pmap_internal(mapper!, a, f; pids = localworkers())
lmap!r(a, f) = pmap_internal(mapper!r, a, f; pids = localworkers())
lmap2!r(a, f1::Function, f2::Function) = pmap_internal2!(mapper2!, a, f1, f2; pids = localworkers())
lmap2!r(a, r, f::Function) = pmap_internal2!(mapper2!, a, r, f; pids = localworkers())

table(f, a...) = table_internal(map, f, a...; flat = true)
ptable(f, a...) = table_internal(pmap, f, a...; flat = true)
ltable(f, a...) = table_internal(lmap, f, a...; flat = true)

tableany(f, a...) = table_internal(map, f, a...; flat = false)
ptableany(f, a...) = table_internal(pmap, f, a...; flat = false)
ltableany(f, a...) = table_internal(lmap, f, a...; flat = false)

function table_internal(mapf, f, args...; flat = true)
    a = [isa(x,Range) ? collect(x) : x for x in args]
    s = @p col [len(x) for x in a]
    S = tuple(s...)
    getarg(sub) = [at(a[i],sub[i]) for i in 1:length(a)]
    args = [getarg(ind2sub(S,x)) for x in 1:prod(s)]
    g(x) = f(x...)
    r = @p mapf args g

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

