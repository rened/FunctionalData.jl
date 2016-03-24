### <a name="accessors"></a>Data Access

##### at(a, i)

`at` allows to acces a single item from a collection.

```jl
at(3:5, 2)                          =>  4
at("abc",3)                         =>  'c'
at([1 2; 3 4],1)                    =>  [1 3]'
at(ones(2,3,4),3)                   =>  ones(2,3)
```

##### setat!(a, i, value)
`setat!` allows to modify items in a collection. It returns the collection.
```jl
a = [1 2 3; 4 5 6]
setat!(a, 2, [0, 1])                => [1 0 3; 4 1 6]
a = ["a", 0, "c"]
setat!(a, 2, "b")                   => ["a","b","c"]
```

##### fst(a), snd(a), third(a), last(a)
```jl
fst(a)                              =>  at(a,1)
snd(a)                              =>  at(a,2)
third(a)                            =>  at(a,3)
last(a)                             =>  at(a,len(a))
```

##### part(a, ind)

```jl
part(1:10, 3:5)                     =>  3:5
part("abc", 2:3)                    =>  "bc"
part(1:10, [3,5,8])                 =>  [3,5,8]
part("abc", [3,1,2,2])              =>  "cabb"
a = [1 2 3; 4 5 6]
part(a, 2:3)                        =>  [2 3; 5 6]
```

##### trimmedpart(a, ind)
Like `part`, but ignores indices which would access elements which do not exist.
```jl
trimmedpart("abc", 2:10)    => "bc"
```

##### take(a, n)
Take up to `n` items from the beginning.
```jl
take([1 2 3 4 5], 3)        =>  [1 2 3]
take(1:3, 100)              =>  1:3
```

##### takelast(a, n)
Take up to `n` items from the end.
```jl
takelast(1:10, 2)           =>  9:10
takelast(1:3, 100)          =>  1:3

```

##### drop
```jl

```

##### droplast
```jl

```

##### tail
```jl

```

##### partition
```jl

```

##### partsoflen
```jl

```

##### extract
```jl

```

