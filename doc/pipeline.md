### <a name="pipeline"></a>Pipeline Syntax

`_` gets replaced with the result of the previous step. `_` can also be used multiple times.


##### @p
```jl
@p ones 2 3 | minus 2   => -ones(2,3)
```

###### Caveats

* Literal ranges sometimes need to be places in parentheses: 
```jl
@p id 1:10
@p id (1:10) | sum
```
 
