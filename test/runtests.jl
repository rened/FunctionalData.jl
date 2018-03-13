println("\n\n\nStarting runtests.jl $(join(ARGS, " ")) ...")

push!(LOAD_PATH, joinpath(dirname(@__FILE__), "../src"))
using Test, FunctionalData

# macro shouldtest(a, f) = (length(ARGS) == 0 || a == ARGS[1]) && f : nothing
# macro shouldtestcontext(a, f) = length(ARGS) < 2 || a == ARGS[2] ? facts(f, a) : nothing

mutable struct A
    a
    b
end

function checkcodeexamples(filename)
    absname = @p functionloc checkcodeexamples | fst | dirname | joinpath "../doc/"*filename
    mdlines = @p read absname String | lines

    startasserts = true
    insidecode = false

    for line in mdlines
        isempty(strip(line)) && continue
        if startswith(line, "```jl")
            insidecode = true && startasserts
        elseif startswith(line, "```")
            insidecode = false
        elseif insidecode 
            # println(line)
            if contains(line, "=>")
                line = @p split line "=>" | concat "@test (" fst(_) ")  ==  (" snd(_) ")" 
            end
            eval(Meta.parse(line))
        end
    end
end 

@testset "doc" begin
    @testset "computing" begin
        checkcodeexamples("computing.md")
    end
    @testset "dataflow" begin
        checkcodeexamples("dataflow.md")
    end
    @testset "helpers" begin
        checkcodeexamples("helpers.md")
    end
    @testset "io" begin
        checkcodeexamples("io.md")
    end
    @testset "lensize" begin
        checkcodeexamples("lensize.md")
    end
    @testset "output" begin
        checkcodeexamples("output.md")
    end
    @testset "pipeline" begin
        checkcodeexamples("pipeline.md")
    end
end

@testset "views" begin
    a = [1,2,3]
    @test FD.view(a,1)  ==  [1]
    @test FD.view(a,3)  ==  [3]
    a = [1 2 3]
    @test FD.view(a,1)  ==  row([1])
    @test FD.view(a,3)  ==  row([3])
    a = [1 2 3; 4 5 6]
    @test FD.view(a,1)  ==  col([1,4])
    @test FD.view(a,3)  ==  col([3,6])
    v = FD.view(a,2) 
    v[2] = 10
    @test a == [1 2 3; 4 10 6]
    a = UInt8[1 2 3; 4 5 6]
    @test FD.view(a,1)  ==  col(UInt8[1,4])
    @test FD.view(a,3)  ==  col(UInt8[3,6])
    @test FD.view(a,2:3)  == part(a,2:3)
end

@testset "lensize" begin
    @test siz(1)      ==  transpose([1 1])
    @test siz([1])    ==  transpose([1 1])
    @test siz([1,2])  ==  transpose([2 1])
    @test siz([1;2])  ==  transpose([2 1])
    @test siz([1 2])  ==  transpose([1 2])
    @test siz(transpose([1 2]))  ==  transpose([2 1])

    @test siz3(rand(1))  == [1 1 1]'
    @test siz3(rand(1,2))  == [1 2 1]'
    @test siz3(rand(1,2,3))  == [1 2 3]'

    @test len(1)        ==  1
    @test len([1])      ==  1
    @test len([1,2])    ==  2
    @test len([1;2])    ==  2
    @test len([1 2])    ==  2
    @test len([1,2,3])  ==  3
    @test len([1 1 1 ;2 2 3])  ==  3
    @test len("adsf")   ==   4
    @test len('a')      ==  1
    @test len(['a',1])  ==  2
end

@testset "basics" begin
    @testset "arraylike" begin
        @test size(FunctionalData.arraylike([1],2)) == (1,2)
        @test size(FunctionalData.arraylike([1 2],2)) == (1,2,2)
        @test size(FunctionalData.arraylike(1,2)) == (2,)
    end
    @testset "ones" begin
        @test onessiz([2 3 4]') == ones(2,3,4)
        @test zerossiz([2 3 4]') == zeros(2,3,4)
        @test size(randsiz([2 3 4]')) == (2,3,4)
        @test size(randnsiz([2 3 4]')) == (2,3,4)
    end
    @testset "shones" begin
        @test shonessiz([2 3 4]') == ones(2,3,4)
        @test shzerossiz([2 3 4]') == zeros(2,3,4)
        @test size(randsiz([2 3 4]')) == (2,3,4)
        @test size(randnsiz([2 3 4]')) == (2,3,4)
    end
    @testset "repeat" begin
        @test repeat('a',0) == ""
        @test repeat('a',1) == "a"
        @test repeat('a',3) == "aaa"
        @test repeat("a",0) == ""
        @test repeat("a",1) == "a"
        @test repeat("a",3) == "aaa"
        @test repeat(1,3)  == [1,1,1]
        @test repeat([1],3) == [1,1,1]
        @test repeat([1 2]',3) == [1 1 1; 2 2 2]
    end
    @testset "minimum" begin
        @test minimum(Float32)+maximum(Float32) == 0f0
        @test minimum(Float64)+maximum(Float64) == 0.0
        @test minimum(Int)+maximum(Int) == -1
        @test maximum() == maximum(Float64)
        @test minimum() == minimum(Float64)
    end
end

mutable struct _somedummytype
    a
    b
end

@testset "accessors" begin
    @testset "at" begin
        @test at([1,2,3],1) == 1
        @test at([1 2 3],1) == col([1])
        @test at([1;2;3],1) == 1
        @test at((1,2,3),1) == 1
        @test at([1 2 3; 4 5 6],1) == col([1 4])
        @test at(cat(3,[1 1],[2 2],[3 3]),1) == [1 1]

        @test at("asdf",1) == 'a'
        @test at(Any["aa",1],1) == "aa"
        @test at(['a','b'],2) == 'b'
        @test at(['a','b'],1) == 'a'

        # @test size(at(rand(2,3,4),(1,))) == ()
        # @test size(at(rand(2,3,4),(1:2,))) == (2,)
        # @test size(at(rand(2,3,4),([1,2],1:2))) == (2,2)

        d = Dict(:a => 1, :b => Dict(:c => 2, :d => Dict(:e => 3)))
        @test at(d,:a) == 1
        @test at(d,:b,:c) == 2
        @test at(d,:b,:c) == 2
        @test at(d,:b,:d,:e) == 3
    end
    @testset "atend" begin
        @test atend(1:10,1) == 10
        @test atend(1:10,2) == 9
    end


    @testset "setat" begin
        a = [1,2,3]
        setat!(a, 1, 10)
        @test at(a,1) == 10
        a = [1 2 3]
        setat!(a, 1, 10)
        @test at(a,1) == col([10])
        setat!(a, 1, col([10]))
        @test at(a,1) == col([10])
        a = [1 2 3; 4 5 6]
        setat!(a, 1, col([10,11]))
        @test at(a,1) == col([10,11])
        a = cat(3,[1 1],[2 2],[3 3])
        setat!(a,1,[10 11])
        @test at(a,1) == [10 11]

        a = Any["aa",1]
        setat!(a, 1, "bb")
        @test at(a,1) == "bb"
    end

    @testset "part" begin
        @test part([1,2,3],[1])  == [1]
        @test part([1,2,3],1:2) == [1,2]
        @test part([1,2,3],[1,2]) == [1,2]
        @test part([1 2 3],[1,3]) == [1 3]
        @test part([1 2 3],[1,3]) == selectdim([1 2 3],2,[1,3])
        @test part([1;2;3],[1,3]) == [1;3]
        @test part([1 2 3; 4 5 6],[1,3]) == [1 3;4 6]
        @test part([1 2 3; 4 5 6],[1 2; 3 2]) == [3,5]
    end

    @testset "dict" begin
        d = Dict(:a => 1, :b => 2)
        @test part(d, :a) == Dict(:a => 1)
        @test part(d, :a, :b) == d
        @test values(d, :a) == [1]
        @test values(d, :a, :b) == [1,2]
        @test values(A(1,2), :a, :b)  ==  [1,2]
    end

    @testset "trimmedpart" begin
        @test trimmedpart(collect(1:10), -1:3) == [1,2,3]
        @test trimmedpart(collect(1:10), 1:3) == [1,2,3]
        @test trimmedpart(collect(1:10), 8:13) == [8,9,10]
        @test trimmedpart(collect(1:10), 13:15) == []
        @test trimmedpart(1:10, [1,3,30,2,-10]) == [1,3,2]
    end

    @testset "fst" begin
        @test fst([1 2 3]) == col([1])
        @test fst(1:3) == 1
        @test fst([1 2 3; 4 5 6]) == col([1,4])
        @test fst('a') == 'a'
        @test fst("asdf") == 'a'
    end

    @testset "last" begin
        @test last([1 2 3]) == col([3])
        @test last(1:3) == 3
        @test last([1 2 3; 4 5 6]) == col([3,6])
        @test last('a') == 'a'
        @test last("asdf") == 'f'
    end

    @testset "drop" begin
        @test drop([1,2,3],1) == [2,3]
        @test drop(Any["test",2,"asdf"],1) == Any[2,"asdf"]
        @test drop(Any["test",2,"asdf"],2) == ["asdf"]

        @test drop(1:3,1) == 2:3
        @test drop([1 2 3],1) == [2 3]
        @test drop([1 2 3; 4 5 6],1) == [2 3; 5 6]
        @test drop([1 2 3; 4 5 6],2) == col([3; 6])
    end

    @testset "dropat" begin
        @test dropat(1:10,3:9) == [1,2,10]
    end

    @testset "take" begin
        @test take(1:3,1) == 1:1
        @test take([1 2 3],1) == col([1])
        @test take([1 2 3; 4 5 6],1) == col([1; 4])
        @test take([1 2 3; 4 5 6],2) == [1 2; 4 5]
        @test take("asdf",1) == "a"
        @test take("asdf",2) == "as"

        @test last(1:3,1) == 3:3
        @test last([1 2 3],1) == col([3])
        @test last([1 2 3; 4 5 6],1) == col([3; 6])
        @test last([1 2 3; 4 5 6],2) == [2 3; 5 6]
        @test last("asdf",1) == "f"
        @test last("asdf",2) == "df"
    end

    @testset "takelast" begin
        @test takelast("asdf",1) == "f"
        @test takelast("asdf",2) == "df"
        @test takelast("asdf",10) == "asdf"
    end

    @testset "takewhile" begin
        @test takewhile(1:10,x->x<5) == 1:4
        @test (@p takewhile (1:10) isless 5) == 1:4
        @test (@p takewhile (1:10) isless 50) == 1:10
        @test (@p takewhile (1:10) isless 0) == []
    end

    @testset "droplast" begin
        @test droplast(1:3,1) == 1:2
        @test droplast([1 2 3],1) == [1 2]
        @test droplast([1 2 3; 4 5 6],1) == [1 2 ; 4 5 ]
        @test droplast([1 2 3; 4 5 6],2) == col([1; 4])
        @test droplast([]) == []
        @test droplast([1]) == []
        @test droplast([],2) == []
    end

    @testset "dropwhile" begin
        @test dropwhile(1:10,x->x<5) == 5:10
        @test (@p dropwhile (1:10) isless 5) == 5:10
        @test (@p dropwhile (1:10) isless 50) == []
        @test (@p dropwhile (1:10) isless 0) == 1:10
    end

    @testset "cut" begin
        a = [1,2,3,4,5]
        b = [1 2 3; 4 5 6]
        @test cut(a,3)  ==  ([1,2,4,5],[3])
        @test cut(b,1)  ==  ([2 3; 5 6], col([1,4]))
        @test cut(b,2:3)  ==  (col([1,4]), [2 3; 5 6])
    end

    @testset "partition" begin
        @test partition(1:3,1)  == Any[1:3]
        # a = partition(1:3,2)
        # @test (a == Any[1:2, 3:3] || a == Any[1:1, 2:3])  ==  true  # Julia v0.3 and v0.4 work differently
        # @test partition(1:3,3)  == Any[1:1, 2:2, 3:3]
        # @test partition(1:3,4)  == Any[1:1, 2:2, 3:3]
    end

    @testset "partsoflen" begin
        # @test partsoflen(1:4,2)  ==  Any[1:2, 3:4]
        # @test partsoflen(1:4,3)  ==  Any[1:3, 4:4]
    end

    @testset "extract" begin
        @test extract(_somedummytype(1,2), :a)  ==  1
        @test extract(_somedummytype(1,2), :b)  ==  2
        @test extract([_somedummytype(1,2), _somedummytype(3,4)], :b)  ==  [2,4]
        d1 = Dict(:a => 1)
        d2 = Dict(:b => 2)
        @test extract(d1, :a)  ==  1
        @test extract(d1, :b)  ==  nothing
        @test extract([d1,d2], :a, 10)  ==  [1, 10]
    end
    @testset "extractnested" begin
        a = [Dict(:a => 1, :b => Dict(:c => 1)), Dict(:a => 2, :b => Dict(:c => 3))]
        @test extractnested(a,:b,:c) == Any[1,3]
    end
    @testset "fieldvalues" begin
        @test fieldvalues(A(1,2)) == [1,2]
        @test dict(A(1,2)) == Dict(:a => 1, :b => 2)
    end
    @testset "isnil" begin
        @test isnil(Nothing) == true
        @test isnil(nothing) == true
        @test isnil(1) == false
        @test isnil("asdf") == false
    end
end

# @testset "computing" begin
# @testset "fold" begin
# #         @test fold([1,2,3], max)  ==  3
# #         @test fold(["1","2","3"], concat)  ==  "123"
# #     end
# @testset "sort" begin
# #         @test FunctionalData.sort([1,2,3], id) == [1,2,3]
# #         @test FunctionalData.sort([1 2 3], x->x[1]) == [1 2 3]
# #         @test FunctionalData.sort([1,2,3], x->-x) == [3,2,1]
# #         @test FunctionalData.sort([1 2 3], x->-x[1]) == [3 2 1]
# #         local D = [Dict(:id => x, :a => string(x)) for x in 1:3]
# #         @test FunctionalData.sort(D, :id) == D
# #         @test FunctionalData.sort("dcba", x->convert(Int,x)) == "abcd"
# #         @test FunctionalData.sort("dcba", x->convert(Int,x); rev = true) == "dcba"
# #         @test FunctionalData.sortrev("dcba", x->convert(Int,x)) == "dcba"
# #     end
# @testset "groupdict" begin
# #         a = [1,2,3,2,3,3]
# #         @test (@p groupdict a id) == Dict(1 => Any[1], 2 => Any[2,2], 3 => Any[3,3,3])
# #     end
# @testset "groupby" begin
# #          a = ["a1","b1","c1","a2","b2","c2"]
# #          @test (@p groupby a snd) == Any[Any["a1","b1","c1"],Any["a2","b2","c2"]]
# #          a = [1,2,3,2,3,3]
# #          @test (@p groupby a id) == Any[Any[1],Any[2,2],Any[3,3,3]]
# #          a = [2 1 3 2 3 3; 20 10 30 20 30 30]
# #          @test (@p groupby a getindex 2) == Any[[1 10]', [2 2; 20 20], [3 3 3; 30 30 30]]
# #     end
# @testset "filter" begin
# #         @test filter([1,2,3],x->isodd(x)) == [1,3]
# #         @test filter([1,2,3],x->iseven(x)) == [2]
# #         @test (@p filter Any[1,2,3] unequal 3) == [1,2]
# #         @test (@p filter [1,2,3] unequal 3) == [1,2]
# #         @test (@p select [1,2,3] unequal 3) == [1,2]
# #         @test (@p reject [1,2,3] unequal 3) == [3]
# #     end
# @testset "uniq" begin
# #         @test uniq([10 20 30])  ==  [10 20 30]
# #         @test uniq([20 20 10], id)  ==  [20 10]
# #         @test uniq([20 -10 10], abs)  ==  [20 -10]
# #         @test uniq([20 10 -10], abs)  ==  [20 10]
# #         @test (@p uniq [20 10 -10] abs)  ==  [20 10]
# #         @test (@p uniq [20 10 -10] getindex 1)  ==  [20 10 -10]
# #     end
# @testset "map" begin
# #         @test map([1 2 3; 4 5 6], x->[size(x,1)]) ==   [2 2 2]
# #         @test map([1 2 3; 4 5 6], x->Any[size(x,1)]) ==   Any[2 2 2]
# #         @test map([1 2 3; 4 5 6], x->[size(x,1);size(x,1)]) == [2 2 2; 2 2 2]
# #         @test map([1 2 3; 4 5 6], x->[size(x,1);size(x,1)]) == [2 2 2; 2 2 2]
# #         @test map([1 2 3; 4 5 6], x->[size(x,1) size(x,1)]) == cat(3,[2 2],[2 2],[2 2])
# #         @test map((Dict(1 => 2)), x->(fst(x), 10*snd(x))) == Dict(1 => 20)
# #         @test map((Dict(1 => 2)), x->nothing) == Dict()
# #         @test (@p map Dict(1 => 2) x->(fst(x), 10*snd(x))) == Dict(1 => 20)
# #         @test (@p map Dict(1 => 2) x->nothing) == Dict()

# #         @test map(Dict(1 => 2, 3 => 4), x->(fst(x),10*fst(x)+snd(x))) == Dict(1=>12,3=>34)

# #         @test mapdict(Dict(1 => 2), (k,v) -> (k,k+v)) == Dict(1 => 3)
# #         @test (@p mapdict (Dict(1 => 2)) (k,v) -> (k,k+v)) == Dict(1 => 3)
# #         @test mapdict(Dict(1 => 10, 2 => 20), (k,v) -> k == 1 ? (k,k+v) : nothing) == Dict(1 => 11)
# #         @test mapkeys((Dict(1 => 2)), x -> 2x) == Dict(2 => 2)
# #         @test mapvalues((Dict(1 => 2)), x -> 2x) == Dict(1 => 4)
# #         d = Dict(:a => 1, :b => 2)
# #         @test (@p mapmap d id | sort) == [1,2]
# #         @test (@p map (1:3) BigInt)  ==  BigInt[1,2,3]
# #         @test (@p map Any[1,2,3] BigInt)  ==  BigInt[1,2,3]
# #     end
# @testset "mapi" begin
# #         @test reduce(&, mapi(0:9, (x,i)->x+1==i)) == true
# #     end
# @testset "worki" begin
# #         a = zeros(Int,3)
# #         worki(a,(x,i)->a[i]=2*i)
# #         @test a  ==  [2,4,6]
# #     end
# @testset "map2" begin
# #         @test map2(1:3, 10:12, (+))  ==  [11,13,15]
# #     end
# @testset "mapmap" begin
# #         @test mapmap([[1 2]; [3 4]], x -> x+1)  ==  [[2 3]; [4 5]]
# #     end
# @testset "map!" begin
# #         f(x) = x*2
# #         f!(x) = x[:] = f(x)
# #         f!r(x) = f(x)
# #         f2!(r,x) = r[:] = vcat(f(x),f(x))
# #         a = [1 2 3; 4 5 6]
# #         @test map(a,f) == [2 4 6; 8 10 12]
# #         a = [1 2 3; 4 5 6]
# #         map!(a,f!)
# #         @test a == [2 4 6; 8 10 12]
# #         a = [1 2 3; 4 5 6]
# #         map!r(a,f)
# #         @test a == [2 4 6; 8 10 12]
# #         a = [1 2 3; 4 5 6]
# #         r = zeros(Int, 4, 3)
# #         map2!(a, r, f2!)
# #         @test r == 2*vcat(a,a)
# #         r = zeros(Int, 4, 3)
# #         r = map2!(a, x->vcat(x,x)*2, f2!)
# #         @test r == 2*vcat(a,a)
# #     end
# @testset "shmap" begin
# #         a = row(collect(1:3))
# #         r = shmap(a, x->x+1)
# #         @test r == a + 1
# #         a = rand(10,round(Int,1e3))
# #         r = shmap(a, x->x+1)
# #         @test r == a+1
# #     end
# @testset "shmap!" begin
# #         a = share(row(collect(1:3)))
# #         orig = copy(a)
# #         shmap!(a, x->x[:] = x+1)
# #         @test a == orig + 1
# #         a = share(rand(10,round(Int,1e3)))
# #         orig = copy(a)
# #         shmap!(a, x->x[:] = x+1)
# #         @test a == orig + 1
# #     end
# @testset "shmap!r" begin
# #         a = share(row(collect(1:3)))
# #         orig = copy(a)
# #         shmap!r(a, x-> x+1)
# #         @test a == orig + 1
# #         # a = share(rand(10,round(Int,1e3)))
# #         # orig = copy(a)
# #         # shmap!r(a, x-> x+1)
# #         # @test a == orig + 1
# #     end
# @testset "shmap2!" begin
# #         a = row(collect(1:3))
# #         r = shmap2!(a, x->x+1, (r,x)->r[:] = x+1)
# #         @test r == a + 1
# #         r = shzerossiz(siz(a))
# #         shmap2!(a, r, (r,x)->r[:] = x+1)
# #         @test r == a + 1
# #         a = rand(10,round(Int,1e3))
# #         r = shmap2!(a, x->x+1, (r,x)->r[:] = x+1)
# #         @test r == a + 1
# #     end
# @testset "pmap" begin
# #         a = row(collect(1:3))
# #         r = pmap(a, x->x+1)
# #         @test r == a + 1
# #         @test eltype(r) == Int
# #         r = pmapvec(a, x->x+1)
# #         @test eltype(r) == Any
# #         a = rand(2,10)
# #         r = pmap(a, x->x+1)
# #         @test r == a+1
# #     end
# @testset "lmap" begin
# #         a = row(collect(1:3))
# #         r = lmap(a, x->x+1)
# #         @test r == a + 1
# #         @test eltype(r) == Int
# #         r = lmapvec(a, x->x+1)
# #         @test eltype(r) == Any
# #         a = rand(2,10)
# #         r = lmap(a, x->x+1)
# #         @test r == a+1
# #     end
# @testset "amap" begin
# #         a = row(1:30)
# #         r = amap(a, x->x+1)
# #         @test r == a + 1
# #         a = rand(2,10)
# #         r = amap(a, x->x+1)
# #         @test r == a+1
# #         @test amap2(1:10, 1:10, +) == collect(2*(1:10))
# #         f = AbstractString
# #         @test amap2("abc", 1:3, (x,y)->"$x$y") == map(f, ["a1","b2","c3"])
# #         # @test amapvec2(1:10, 1:10, +) == unstack(2*(1:10))
# #     end

# @testset "table" begin
# #         adder(x,y) = x+y
# #         pass(x,y) = [x,y]
# #         passarray(x,y) = col([x,y])
# #         @test table(id,[1,2,3])  ==  [1,2,3]
# #         @test table([1,2,3],id)  ==  [1,2,3]
# #         @test table(pass,[1,2],1:3)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test table([1,2],1:3,pass)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test ltable(id,[1,2,3])  ==  [1,2,3]
# #         @test ltable([1,2,3],id)  ==  [1,2,3]
# #         @test ltable(pass,[1,2],1:3)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test ltable([1,2],1:3,pass)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test ptable(id,[1,2,3])  ==  [1,2,3]
# #         @test ptable([1,2,3],id)  ==  [1,2,3]
# #         @test ptable(pass,[1,2],1:3)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test ptable([1,2],1:3,pass)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test tableany(id,[1,2,3])  ==  Any[1,2,3]
# #         @test tableany([1,2,3],id)  ==  Any[1,2,3]
# #         @test tableany(pass,[1,2],1:3)  ==  reshape(Any[[1,1], [2,1], [1,2], [2,2], [1,3], [2,3]], 2, 3)
# #         @test tableany([1,2],1:3,pass)  ==  reshape(Any[[1,1], [2,1], [1,2], [2,2], [1,3], [2,3]], 2, 3)
# #         @test table(passarray,[1,2],1:3)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test table([1,2],1:3,passarray)  ==  cat(3, [1 2; 1 1], [1 2; 2 2], [1 2; 3 3])
# #         @test tableany(passarray,[1,2],1:3)  ==  reshape(map(Any[[1,1], [2,1], [1,2], [2,2], [1,3], [2,3]],col), 2, 3)
# #         @test tableany([1,2],1:3,passarray)  ==  reshape(map(Any[[1,1], [2,1], [1,2], [2,2], [1,3], [2,3]],col), 2, 3)
# #         @test table(adder,[1 2; 3 4],1:3)  ==  cat(3, [2 3; 4 5], [3 4; 5 6], [4 5; 6 7])
# #         @test table([1 2; 3 4],1:3,adder)  ==  cat(3, [2 3; 4 5], [3 4; 5 6], [4 5; 6 7])
# #         # @test size(ptableany((x,y)->myid(), 1:3, 1:4, nworkers = 2)) == (3,4) # FIXME
# #         # @test size(ptableany(1:3, 1:4, (x,y)->myid(), nworkers = 2)) == (3,4) # FIXME
# #     end

# @testset "tee" begin
# #         a = Any[]
# #         @test tee(1:3, x->push!(a,x+1))  ==  1:3
# #         @test a  ==  Any[2:4]
# #         b = Any[]
# #         pushadd(x,param) = push!(b,x+param)
# #         c = @p tee 1 pushadd 10
# #         @test b  ==  [11]
# #         @test c  ==  1
# #     end
# @testset "*" begin
# #         @test (sum*abs)([-1,0,1])  ==  2
# #         @test (join*split)("a b c")  ==  "abc"
# #         @test (last*join*split)("a b c")  ==  'c'
# #     end
# @testset "apply" begin
# #         f(a,b) = a+b
# #         g() = 1
# #         @test apply(f,1,2) == 3
# #         @test apply(g) == 1
# #     end
# @testset "minelem" begin
# #         d = [Dict(:a => 1), Dict(:a => 2), Dict(:a => 3)]
# #         @test minelem(d,x->at(x,:a)) == Dict(:a => 1)
# #         @test (@p minelem d at :a) == Dict(:a => 1)
# #         @test maxelem(d,x->at(x,:a)) == Dict(:a => 3)
# #         @test (@p maxelem d at :a) == Dict(:a => 3)
# #         @test extremaelem(d,x->at(x,:a)) == [Dict(:a => 1), Dict(:a => 3)]
# #         @test (@p extremaelem d at :a) == [Dict(:a => 1), Dict(:a => 3)]
# #         @test (@p map [10,11,12] x->@p minelem [10,0,12,13] y->(abs(y-x))) == [10,10,12]
# #     end
# @testset "isany" begin
# #         @test isany(zeros(3), x->x==0) == true
# #         @test areall(zeros(3), x->x==0) == true
# #         @test isany(zeros(3), x->x!=0) == false
# #         @test areall(zeros(3), x->x!=0) == false
# #         @test (@p zeros 3 | areall unequal 0) == false
# #         @test (@p zeros 3 | isany unequal 0) == false
# #     end
# # end

@testset "dataflow" begin
    @testset "unflatten" begin
        a = Any[[1],[2,3,4],[5,6]]
        @test unflatten(flatten(a,),a)  ==  a
    end
    @testset "reshape" begin
        @test size(reshape(rand(9)))  ==  (3,3)
    end
    @testset "rowcol" begin
        @test row(1)  ==  ones(Int, 1, 1)
        @test row([1,2,3])  ==  [1 2 3]
        @test row(1,2,3)    ==  [1 2 3]
        @test col(1)  ==  ones(Int, 1, 1)
        @test col([1,2,3])  ==  [1 2 3]'
        @test col(1,2,3)    ==  [1 2 3]'
    end
    @testset "stack" begin
        @test stack(Any[1,2]) == [1,2]
        @test stack(Any[[1 2],[3 4]]) == cat(3,[1 2], [3 4])
        @test stack(Any[zeros(2,3,4),ones(2,3,4)]) == cat(4,zeros(2,3,4),ones(2,3,4))
    end
    @testset "flatten" begin
        @test flatten(Any[[1],[2]]) == [1,2]
        @test flatten(Any[row([1]),col([2])]) == [1 2]
        @test flatten(Any[[1 2],[2 3]]) == [1 2 2 3]
        @test flatten(Any[[1 2]',[2 3]']) == [1 2; 2 3]
        @test flatten(Any[[1, 2],[2, 3]]) == [1,2,2,3]
        @test flatten(Any[[1; 2],[2; 3]]) == [1,2,2,3]
        @test flatten(Any[Any[[1; 2],[2; 3]]]) == Any[[1; 2],[2; 3]]
        @test flatten(Char['a','b','c']) == "abc"
        @test flatten(Char['a' 'b' 'c']) == "abc"
        @test flatten(["a","b","c"]) == "abc"
        @test flatten(["a" "b" "c"]) == "abc"
        @test flatten(Any["a","b","c"]) == "abc"
        @test flatten(Any["a" "b" "c"]) == "abc"
    end
    @testset "concat" begin
        @test concat([1,2]) == [1,2]
        @test concat([[1,2];]) == [1,2]
        @test concat([[1,2];3]) == [1,2,3]
        @test concat(ones(2,3),zeros(2,4)) == hcat(ones(2,3),zeros(2,4))
    end
    @testset "unstack" begin
        @test unstack(cat(3,[1 2],[2 3])) == Any[[1 2],[2 3]]
        @test unstack(stack(Any[[1 2],[2 3]])) == Any[[1 2],[2 3]]
        @test unstack(stack(Any[zeros(2,3,4),ones(2,3,4)])) == Any[zeros(2,3,4),ones(2,3,4)]
        @test unstack([1 2 3; 4 5 6]) == Any[col([1,4]), col([2,5]), col([3,6])]
        @test unstack((1,2,3)) == Any[1,2,3]
    end
    @testset "riffle" begin
        @test riffle([1,2,3],0) == [1,0,2,0,3]
        @test riffle(1,0) == 1
        @test riffle([1 2 3; 4 5 6],zeros(2,1)) == [1 0 2 0 3; 4 0 5 0 6]
        @test riffle([1 2 3; 4 5 6],[8;9]) == [1 8 2 8 3; 4 9 5 9 6]
        @test riffle("abc",'_') == "a_b_c"
        @test riffle("abc","_") == "a_b_c"
        @test riffle("abc",", ") == "a, b, c"
        @test riffle([1,2,3],0) == [1,0,2,0,3]
    end
    @testset "matrix" begin
        a = Any[ones(2,3), zeros(2,3)]
        @test size(matrix(a))  ==  (6,2)
        @test size(matrix(zeros(2,3,4))) == (6,4)
        @test unmatrix(matrix(a),a)  ==  a
    end
    @testset "lines" begin
        @test lines("line1\nline2\r\nline3") == ["line1","line2","line3"]
        @test unlines(lines("line1\nline2\r\nline3")) == "line1\nline2\nline3"
    end
    @testset "findsub" begin
        a = [0 1 -1; 1 0 0]
        @test findsub(a)  ==  [2 1 1; 1 2 3]
    end
    @testset "subtoind" begin
        @test subtoind([1 1]', rand(2,3)) == 1
        @test subtoind([2 3]', rand(2,3)) == 6
        @test subtoind([1 2]', rand(2,3)) == 3
        @test subtoind([1 1 1]', rand(2,3,4)) == 1
        @test subtoind([2 3 4]', rand(2,3,4)) == 24
        @test subtoind([1 1 2]', rand(2,3,4)) == 7
    end
    @testset "randsample" begin
        @test size(randsample(1:10,5))  ==  (5,)
        @test size(randsample(rand(2,10),20))  ==  (2,20)
        @test randsample("aaa",5)  ==  "aaaaa"
    end
    @testset "flip" begin
        @test flip([])  ==  []
        @test flip("abc")  ==  "cba"
        @test flip(1:10)  ==  10:-1:1
        b = [1,2,3]
        flip!(b)
        @test b == [3,2,1]
        @test flip(Pair(1,2))  ==  Pair(2,1)
        @test flip(Dict(1=>2,3=>4))  ==  Dict(2=>1, 4=>3)
    end
    @testset "flipdims" begin
        @test size(flipdims(rand(2,3,4),1,1))  ==  (2,3,4)
        @test size(flipdims(rand(2,3,4),1,3))  ==  (4,3,2)
        @test size(flipdims(rand(2,3,4),2,1))  ==  (3,2,4)
    end
end

@testset "unzip" begin
    @test unzip([(1,1),(2,2)])  ==  ([1,2],[1,2])
    @test unzip([(1,2), "ab"])  ==  (Any[1,'a'], Any[2,'b'])
end


@testset "pipeline" begin
    @testset "general" begin
        add(x,y) = x.+y
        minus(x,y) = x.-y

        x = @p add 1 2
        @test x == 3

        @test (@p add 1 2) == 3
        @test (@p add 1 2 | minus 2) == 1
        @test (@p add 1 2 | minus _ 2) == 1
        @test (@p add 1 2 | minus 3 _) == 0

        @test (@p map [1 2 3] add 1)  ==  [2 3 4]
        @test (@p map [1 2 3] minus 1)  ==  [0 1 2]

        x = @p id (1:5) | map add 1
        @test x  ==  [2,3,4,5,6]

        x = @p add (1:5) 1 | map add 1 | map minus 1
        @test x  ==  [2,3,4,5,6]

        x = @p map (1:5) add 1 
        @test x  ==  [2,3,4,5,6]

        x = @p id [1] | map _ (x->x.+_.+_.+_)
        @test x  ==  row([4])

        @test square(2)  == 4
        @test power(2,3)  == 8
    end


    @testset "map2" begin
        add2(a,b) = a+b
        x = @p map2 1:3 10:12 add2
        @test x  ==  [11,13,15]

        o = ones(2,3)
        z = zeros(2,3)
        @test (@p map2 o z plus) == ones(2,3)
        @test (@p map3 o z z (a,b,c)->a+b+c) == ones(2,3)
        @test (@p map4 o z z z (a,b,c,d)->a+b+c+d) == ones(2,3)
        @test (@p map5 o z z z z (a,b,c,d,e)->a+b+c+d+e) == ones(2,3)

        @test (@p mapvec2 (1:2) [3,4] (a,b)->"$a$b") == ["13","24"]
        @test (@p map2 (1:2) [3,4] (a,b)->"$a$b") == "1324"

        Z = ones(Int,3)
        add3(a,b,c) = a+b+c
        x = @p map3 1:3 10:12 100Z add3
        @test x  ==  [111,113,115]

        add4(a,b,c,d) = a+b+c+d
        x = @p map4 1:3 10:12 100Z 2000Z add4
        @test x  ==  [2111,2113,2115]

        add5(a,b,c,d,e) = a+b+c+d+e
        x = @p map5 1:3 10:12 100Z 2000Z 30000Z add5
        @test x  ==  [32111,32113,32115]
    end
end

@testset "io" begin
    @testset "readwrite" begin
        filename = tempname()
        write("line1\nline2\nline3",filename)
        @test read(filename, String)  ==  "line1\nline2\nline3"
        @test lines(read(filename, String))  ==  lines("line1\nline2\nline3")

        @p read filename String | lines 
        @test (@p read filename String | lines | unlines | lines | unlines)  ==  "line1\nline2\nline3"
    end

    @testset "filenames" begin
        d = mktempdir()
        mk(a) = mkpath(joinpath(d,a))
        t(a...) = touch(joinpath(d,a...))
        mk("adir")
        mk("bdir")
        t("a")
        t("b")
        t("adir","a")
        t("adir","b")
        @test filenames(d)  ==  ["a","b"]
        @test dirnames(d)  ==  ["adir","bdir"]
        rm(d, recursive = true)
    end
end



