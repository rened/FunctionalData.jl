function checkcodeexamples(filename)
    mdlines = @p readstring filename | lines

    startasserts = true
    insidecode = false

    for line in mdlines
        isempty(strip(line)) && continue
        # if startswith(line, "### <a name=\"lensize\">")
            # startasserts = true
        # if fst(line) == '#'
        if startswith(line, "```jl")
            insidecode = true && startasserts
        elseif startswith(line, "```")
            insidecode = false
        elseif insidecode 
            println(line)
            if contains(line, "=>")
                line = @p split line "=>" | concat "@assert_equal (" fst(_) ")  (" snd(_) ")" 
            end
            eval(parse(line))
        end
    end
end
