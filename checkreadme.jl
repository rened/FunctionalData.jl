using FunctionalData

mdlines = @p read "../README.md" | lines

startasserts = false
insidecode = false

for line in mdlines
    isempty(strip(line)) && continue
    if startswith(line, "### <a name=\"lensize\">")
        startasserts = true
    elseif fst(line) == '#'
    elseif startswith(line, "```jl")
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

