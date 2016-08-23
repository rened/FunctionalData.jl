### <a name="lensize"></a>Length and Size


##### len(a)

`len` returns the length of a collection.

```jl
len(1)                              =>  1
len(1:10)                           => 10
len("abc")                          =>  3
len(["a",1])                        =>  2
len(ones(2,3))                      =>  3
len(ones(2,3,4))                    =>  4
```

##### siz(a)

`siz` returns the size of an item. Items always have at least 2 dimensions. For arrays `siz(a) == col(size(a))`.

```jl
siz(1)                              =>  [1 1]'
siz(1:5)                            =>  [1 5]'
siz("abc")                          =>  [1 3]'
siz(["a",1])                        =>  [2 1]'
siz(["a" 1])                        =>  [1 2]'
siz(ones(2,3))                      =>  [2 3]'
siz(ones(2,3,4))                    =>  [2 3 4]'
```

##### siz3(a)
`siz3` works for arrays with `ndims<=3` and always returns a `3 x 1` vector. This can help in using the same code for 2D and 3D data.
```jl
siz3(ones(1))                       => [1 1 1]'
siz3(ones(1,2))                     => [1 2 1]'
siz3(ones(1,2,3))                   => [1 2 3]'
```
 
