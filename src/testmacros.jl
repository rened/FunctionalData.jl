export @test_equal, @assert_equal,  @test_almostequal

function test_equal(a, b, doassert = false)
        if isequal(a,b) && isequal(typeof(a), typeof(b)) return end
        local sizea = siz(a)
        local sizeb = siz(b)
        local sizesEqual = isequal(sizea,sizeb)
        local contentEqual = true
        if sizesEqual 
            for i = 1:length(a)
                if a[i] != b[i]
                    println("typeof a[i] is $(typeof(a[i]))")
                    println("typeof b[i] is $(typeof(b[i]))")
                    contentEqual = false
                    break
                end
            end
        end
        if !sizesEqual || !contentEqual
            println("########### Failed test: $(!sizesEqual ? : "size mismatch, " : "")$(!contentEqual ? "content mismatch" : "")")
            # println(a)
            println("\nShould have been: $b") 
            #println($(esc(b)))
            println("of size $(sizeb') \nof type $(typeof(b))")
            println("\nwas $a")
            #println($(esc(a)))
            println("of size $(sizea') \nof type $(typeof(a))\n")
            doassert && error("@assert_equal: test failed")
        end
end

macro test_equal(A,B)
    quote
        local a = $(esc(A))
        local b = $(esc(B))
        test_equal(a,b)
    end
end

macro assert_equal(A,B)
    quote
        local a = $(esc(A))
        local b = $(esc(B))
        test_equal(a,b,true)
    end
end


macro test_almostequal(A,B,MAXDIFF)
    #println(A) 
    quote
        local a = $(esc(A))
        #if isequal(a,Nothing)   # FIXME this check does not actually work
        #    error("test_equal: the following function does not return any output! \n\n $A \n\n")
        #end
        local b = $(esc(B))
        local maxdiff = $(esc(MAXDIFF))
        if isequal(a,b) && isequal(typeof(a), typeof(b)) return end
        local sizea = siz(a)
        local sizeb = siz(b)
        local sizesEqual = isequal(sizea,sizeb)
        local contentEqual = true
        if sizesEqual 
            for i = 1:length(a)
                if abs(a[i]-b[i]) > maxdiff
                    println("typeof a[i] is $(typeof(a[i]))")
                    println("typeof b[i] is $(typeof(b[i]))")
                    contentEqual = false
                    break
                end
            end
        end
        if ~sizesEqual || ~contentEqual
            println("########### Failed test:")
            println($(string(A)))
            println("\nShould have been: $b") 
            #println($(esc(b)))
            println("of size $(sizeb') \nof type $(typeof(b))")
            println("\nwas $a")
            #println($(esc(a)))
            println("of size $(sizea') \nof type $(typeof(b))\n")
        end
    end
end
