export @p

#######################################
##  pipelining:  x = @p add 1 2 | minus _ 3 

macro p(a...)
    # println("\n\n\ninside p")
    # println()
    # println(a...)
    #map(x->print(typeof(x)),a)
    #println()
    #a = map(x->

    #b = {}
    #println(a)
    #map(x-> typeof(x)==Expr && x.args[1]==:|?append!(b,x.args[[2,1,3]]):push!(b,x),a)
    #println(string("b:  ",b))

    # flip arguments where the order was messed up by |
    output = a
    input = Any[]
    while input!=output
        input = output
        output = Any[]
        flatten(x) = typeof(x)==Expr && x.args[1]==:|?append!(output,x.args[[2,1,3]]):push!(output,x)
        # println(string("input before: ",input))
        # println(string("output before: ",output))
        # @show flatten input
        Base.map(flatten,input)
        # println(string("input after: ",input))
        # println(string("output after:  ",output))
    end
    

    currying = Any[:map, :map!, :map!r, :map2!, :mapmap, :shmap, :shmap!, :shmap!r, :shmap2!, :pmap, :lmap, 
        :work, :workwork, :shwork, :pwork, :lwork, :tee, :filter, :select, :reject, :takewhile, :dropwhile, :mapkeys, :mapvalues,
        :minelem, :maxelem, :extremaelem, :isany, :areall]
    currying2 = Any[:map2, :mapvec2]
    currying3 = Any[:map3, :mapvec3]
    currying4 = Any[:map4, :mapvec4]
    currying5 = Any[:map5, :mapvec5]

    parts = split(output,:|)
    # @show parts
    part = parts[1]
    if len(part) > 2 && in(part[1],currying) # ==:map
        length(part) < 3 && error("FunctionalData.@p: trying to use $(part[1]), but too few parameters given: $parts")
        f = :(x -> $(part[3])(x, $(part[4:end]...)) )
        ex = :( $(part[1])($(part[2]), $f) )
     elseif len(part) > 3 && in(part[1], currying2) # ==:map2
         length(part) < 4 && error("FunctionalData.@p: trying to use $(part[1]), but too few parameters given: $parts")
         f = :((x,y) -> $(part[4])(x, y, $(part[5:end]...)) )
         ex = :( $(part[1])($(part[2]), $(part[3]), $f) )
     elseif len(part) > 4 && in(part[1], currying3) # ==:map3
         length(part) < 5 && error("FunctionalData.@p: trying to use $(part[1]), but too few parameters given: $parts")
         f = :((x,y,z) -> $(part[5])(x, y, z, $(part[6:end]...)) )
         ex = :( $(part[1])($(part[2]), $(part[3]),$(part[4]), $f) )
     elseif len(part) > 5 && in(part[1], currying2) # ==:map2
         length(part) < 6 && error("FunctionalData.@p: trying to use $(part[1]), but too few parameters given: $parts")
         f = :((x,y,z,z2) -> $(part[6])(x, y, z, z2, $(part[7:end]...)) )
         ex = :( $(part[1])($(part[2]), $(part[3]), $(part[4]), $(part[5]), $f) )
     elseif len(part) > 6 && in(part[1], currying2) # ==:map2
         length(part) < 7 && error("FunctionalData.@p: trying to use $(part[1]), but too few parameters given: $parts")
         f = :((x,y,z,z2,z3) -> $(part[7])(x, y, z, z2, z3, $(part[8:end]...)) )
         ex = :( $(part[1])($(part[2]), $(part[3]), $(part[4]), $(part[5]), $(part[6]), $f) )
    else
        ex = :( $(part[1])($(part[2:end]...)) )
    end
    # println(ex)

    for i = 2:length(parts)
        # println("i is $i")
        part = parts[i]
        # @show part
        didreplace = false
        function replace_(a::Array)
            # @show "replacing" typeof(a) a
            r = a
            r = Base.map(replace_, r)
            if anyequal(a, :_)   # replace _ in expression
                if sum(part.==:_) > 1
                    error("Use can use '_' only once per section of a @p ... | ... | ... pipeline")
                end
                part[find(part.==:_)] = ex
                didreplace = true
            end
            r = :( $(part[1])( $(part[2:end]...)) )
        end
        function replace_(a::Expr)
            # @show "replacing" typeof(a) a
            if isa(a.args, Array)
                a.args = Base.map(replace_, a.args)
            end
            a
        end
        function replace_(a) 
            # @show "replacing" typeof(a) a
            if a == :_ 
                didreplace = true
                ex
            else
                a
            end
        end
        newex = replace_(part)
        if didreplace
            ex = newex
        else
            #println("fany==false")
            #println("### part[1] $(part[1]))")
            if len(part) > 1 && in(part[1],currying) # ==:map
                f = :( x-> $(part[2])(x, $(part[3:end]...)) )
                ex = :( $(part[1])($ex, $f) )
            elseif len(part) > 2 && in(part[1], currying2) # ==:map2
                f = :( (x,y) -> $(part[3])(x, y, $(part[4:end]...)) )
                ex = :( $(part[1])($ex, $(part[2]), $f) )
            elseif len(part) > 3 && in(part[1], currying3) # ==:map3
                f = :( (x,y,z) -> $(part[4])(x, y, z, $(part[5:end]...)) )
                ex = :( $(part[1])($ex, $(part[2]), $(part[3]), $f) )
            elseif len(part) > 4 && in(part[1], currying4) # ==:map4
                f = :( (x,y,z,z2) -> $(part[5])(x, y, z, z2, $(part[6:end]...)) )
                ex = :( $(part[1])($ex, $(part[2]), $(part[3]),  $(part[4]), $f) )
            elseif len(part) > 5 && in(part[1], currying5) # ==:map5
                f = :( (x,y,z,z2,z3) -> $(part[6])(x, y, z, z2, z3, $(part[7:end]...)) )
                ex = :( $(part[1])($ex, $(part[2]), $(part[3]), $(part[4]), $(part[5]), $f) )
            else
                ex = :( $(part[1])($ex, $(part[2:end]...)) )
            end
        end
        # println(ex)
    end
    #println()
    #println(ex)
    return esc(ex)  
end




