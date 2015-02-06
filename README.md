## FunctionalData

[![Build Status](https://travis-ci.org/rened/FunctionalData.jl.png)](https://travis-ci.org/rened/FunctionalData.jl)

`FunctionalData` is a package for fast and expressive data modification. 

Built around a simple memory layout convention, it provides a small set of general purpose [functional constructs](#dataflow) as well as routines for [efficient computation](#views) with dense numerical arrays.

Optionally, it supplies a [syntax](#pipeline) for clean, concise code:
 
```jl
wordcount(filename) = @p read filename | lines | map split | flatten | length
```
 
#### Memory Layout 

Indexing is simplified for dense n-dimensional arrays with individual (n-1)-dimensional items. 

For example, this allows to use the exact same code for 2D patches and 3D blocks:

```jl
a = [1 2 3; 4 5 6]
b = ones(2, 2, 10)          #  10 2D patches
c = ones(2, 2, 2, 10)       #  10 3D blocks

len(a)       =>   3
len(b)       =>  10
len(c)       =>  10

at(a,2)      =>  [2 5]'
part(a,2:3)  =>  [2 3; 5 6]

normsum(x) = x/sum(x)

map(b, normsum)   =>  [0.25 ...  ] of size 2 x 2 x 10
map(c, normsum)   =>  [0.125 ... ] of size 2 x 2 x 2 x 10

#  Result shape may change:
map(b, sum)       =>  [4 ... ]     of size 1 x 10
map(c, sum)       =>  [8 ... ]     of size 1 x 10
```

#### Efficiency

Using a custom `View` type based on this memory layout assumption, the provided `map` operations can be considerably faster than built-ins. Given our data and desired operation

```jl
a = rand(10, 1000000)   #  =>  80 MB

csum!(x) = for i = 2:length(x) x[i] += x[i-1] end
csumoncopy(x) = (for i = 2:length(x) x[i] += x[i-1] end; x)
```

we can use the following simple, general and efficient statement:

```jl
map!(a, csum!) 
#  elapsed time: 0.027491752 seconds (256 bytes allocated)
```

Built-in alternatives are either slower or require manual inlining, for a specific data layout:

```jl
mapslices(csumoncopy, a, [1])
#  elapsed time: 0.85726391 seconds (404 MB allocated, 5.34% gc time)

f(a) = for i = 1:size(a,2)  a[:,i] = csumoncopy(a[:,i])  end
#  elapsed time: 0.110978216 seconds (144 MB allocated, 3.86% gc time)

f2(a) = for i = 1:size(a,2)  csum!(sub(a,:,i))  end
#  elapsed time: 0.071394038 seconds (160 MB allocated, 16.46% gc time)

function f3(a)
    for n = 1:size(a,2)
        for m = 2:size(a,1)  a[m,n] += a[m-1,n]  end
    end
end
#  elapsed time: 0.017072235 seconds (80 bytes allocated)

function f4(a)
    for n = 1:size(a,1):length(a)
        for m = 1:size(a,1)-1  a[n+m] += a[n+m-1]  end
    end
end
#  elapsed time: 0.013347679 seconds (80 bytes allocated)
```

With the exact same syntax we can easily parallelize our code using the local workers via shared memory or Julia's inter-process serialization, both on the local host or all machines:

```jl
shmap!(a, csum!)      # local processes, shared memory
lmap!(a, csum!)       # local processes
pmap!(a, csum!)       # all available processes
```

For each of these variants there are optimized functions available for in-place operation on the input array, in-place operation on a new output array, or fallback options for functions which do not work in-place. For details, see the section on [map and Friends](#computing).


## Documentation

Please see the [overview](#overview) below for one-line descriptions of each function. More details and examples can then be found in the following sections (work in progress)

* [Length and size](#lensize)
* [Data access](#accessors)
* [Data Layout](#dataflow)
* [Pipeline syntax](#pipeline)
* [Efficient views](#views)
* [Computing: map and friends](#computing)
* [Output](#output)
* [I/O](#io)
* [Helpers](#helpers)
* [Unit tests](#testmacros)

### <a name="overview"></a>Overview

###### Length and Size [[details]](#lensize)

```jl
len(a)                              # length
siz(a)                              # lsize, ndims x 1
siz3(a)                             # lsize, 3 x 1
```

###### Data Access [[details]](#accessors)

```jl
at(a, i)                            # item i
setat!(a, i, value)                 # set item i to value
fst(a)                              # first item
snd(a)                              # second item
third(a)                            # third item
last(a)                             # last item
part(a, ind)                        # items at indices ind
trimmedpart(a, ind)                 # items at ind, no error if a is too short
take(a, n)                          # the first up to n elements
takelast(a, n)                      # the last up to elements
drop(a,n)                           # a, except for the first n elements
droplast(a,n)                       # a, except for the last n elements
partition(a, n)                     # partition into n parts
partsoflen(a, n)                    # partition into parts of length n
extract(a, field, default)          # 
@getfield(a, x)                     # get key x of dict or field x of composite type instance
```

###### Data Layout [[details]](#dataflow)

```jl
row(a)                              # reshape into row vector
col(a)                              # reshape into column vector
reshape(a, siz)                     # reshape into size in ndim x 1 vector siz
split(a, x or f)                    # split a where item == x or f(item) == true                         
concat(a...)                        # same as flatten([a...])
subtoind(sub, a)                    # transform ndims x npoints sub to linear ind for a
indtosub(ind, a)                    # transform linear ind to ndims x len(ind) sub for a
stack(a)                            # concat along the n + 1st dim of the items in a
flatten(a)                          # reduce the nestedness of a
unstack(a)                          # split the dense array a into array of items
riffle(a, x)                        # insert x between the items of a
matrix(a)                           # reshape items of a to column vectors
unmatrix(a, example)                # reshape the column vector items in a according to example
lines(a)                            # split the text a into array of lines
unlines(a)                          # concat a with newlines 
unzip(a)                            # unzip items in a
findsub(a)                          # return sub for the non-zero entries in array a
randsample(a, n)                    # draw n items from a with repetition
```

###### Pipeline Syntax [[details]](#pipeline)

```jl
r = @p f1 a b | f2 c | f3 e f       # pipeline macro, equals f3(f2(f1(a,b),c),e,f)
```

###### Efficient Views [[details]](#views)

```jl
view(a,i)                           # lightweight view of item i of a
view(a,i,v)                         # lightweight view of item i of a, reusing v
next!(v)                            # make v point to the i + 1th item of a
trytoview(a,v)                      # for dense array, use view, otherwise part
trytoview(a,v,i)                    # for dense array, use view reusing v, otherwise part
```
 
###### Computing: map and Friends [[details]](#computing)

```jl
map(a, f)                           # apply f to each item
map!(a, f!)                         # apply f! to each item in-place
map!r(a, f)                         # apply f to each item, overwriting a                         
map2!(a, f, f!)                     # apply f to fst(a), f! to other items
map2!(a, r, f!)                     # apply f!(resultitem, item) to each item
shmap(a, f)                         # parallel map f to shared array a, accross procs(a)
shmap!(a, f!)                       # inplace shmap f!, overwriting a, accross procs(a)
shmap!r(a, f)                       # apply f to each item, overwriting a, accross procs(a)                         
shmap2!(a, f, f!)                   # apply f to fst(a), f! to other items, accross procs(a)
shmap2!(a, r, f!)                   # apply f!(resultitem, item), accross procs(a)
pmap(a, f)                          # parallel map of f accross all workers
lmap(a, f)                          # parallel map of f accross local workers
mapmap(a, f)                        # shorthand for map(a, x->map(x,f))
work(a, f)                          # apply f to each item, no result value
any(a, f)                           # is any f(item) true
anyequal(a, x)                      # is any item == x
all(a, f)                           # are all f(item) true
allequal(a, x)                      # are all items == x
sort(a, f; kargs...)                # sort a accorting to f(item)
```

###### Output [[details]](#output)

```jl
showinfo
tee
makeliteral
```

###### I/O [[details]](#io)

```jl
read
write
existsfile
mkdir 
filenames
filepaths
dirnames
dirpaths
readmat
writemat
@snapshot
```

###### Helpers [[details]](#helpers)

```jl
zerossiz(s, typ)                    # zeros(s...), default typ is Float64
shzerossiz(s, typ)                  # shared zerossiz
shzeros([typ,] s...)                # shared zeros
onessiz(s, typ)                     # ones(s...), default typ is Float64
shonessiz(s, typ)                   # shared onessiz
shones([typ,] s...)                 # shared ones
randsiz(s, typ)                     # rand(s...), default typ is Float64
shrandnsiz(s, typ)                  # shared randsiz
shrand([typ,] s...)                 # shared rand
randnsiz(s, typ)                    # randn(s...), default typ is Float64
shrandnsiz(s, typ)                  # shared randnsiz
shrandn([typ,] s...)                # shared randn
zeroel(a)                           # zero(eltype(a))
oneel                               # one(eltype(a))
@dict a b c ...                     # Dict("a" => a, "b" => b, "c" => c, ...)
+
* 
repeat(a, n)                        # repeat a n times
nop()                               # no-op
id(a...)                            # returns a...
istrue(a or f)                      # is a or result of f true
isfalse(a or f)                     # !istrue
not                                 # alias for !
or                                  # alias for ||
and                                 # alias for &&
plus                                # alias for .+
minus                               # alias for .-
times                               # alias for .*
divby                               # alias for ./
```

###### Unit Tests [[details]](#testmacros)

```jl
@test_equal a b                     # test a and b for equality, show detailed info if not
@assert_equal a b                   # like test_equal, then throws error
@test_almostequal a b maxdiff       # like test_equal, but allows up to maxdiff difference
```


### <a name="lensize"></a>Length and Size


##### len(a)

`len` returns the length of a collection.

```jl
len(1)              =>  1
len(1:10)           => 10
len("abc")          =>  3
len(["a",1])        =>  2
len(ones(2,3))      =>  3
len(ones(2,3,4))    =>  4
```

##### siz(a)

`siz` returns the size of an item. Items always have at least 2 dimensions. For arrays `siz(a) == col(size(a))`.

```jl
siz(1)              =>  [1 1]'
siz(1:5)            =>  [1 5]'
siz("abc")          =>  [1 3]'
siz(["a",1])        =>  [2 1]'
siz(["a" 1])        =>  [1 2]'
siz(["a" 1]')       =>  [2 1]'
siz(ones(2,3))      =>  [2 3]'
siz(ones(2,3,4))    =>  [2 3 4]'
```

##### siz3(a)
`siz3` works for arrays with `ndims<=3` and always returns a `3 x 1` vector. This can help in using the same code for 2D and 3D data.
```jl
siz3(ones(1))       => [1 1 1]'
siz3(ones(1,2))     => [1 2 1]'
siz3(ones(1,2,3))   => [1 2 3]'
```


### <a name="accessors"></a>Data Access

##### at(a, i)

`at` allows to acces a single item from a collection.

```jl
at(3:5, 2)                  =>  4
at("abc",3)                 =>  'c'
at([1 2; 3 4],1)            =>  [1 3]'
at(ones(2,3,4),3)           =>  ones(2,3)
```

##### setat!(a, i, value)
`setat!` allows to modify items in a collection. It return the collection.
```jl
a = [1 2 3; 4 5 6]
setat!(a, 2, [0, 1])        => [1 0 3; 4 1 6]
a = ["a", 0, "c"]
setat!(a, 2, "b")           => ["a","b","c"]
```

##### fst(a), snd(a), third(a), last(a)
```jl
fst(a)      =>  at(a,1)
snd(a)      =>  at(a,2)
third(a)    =>  at(a,3)
last(a)     =>  at(a,len(a))
```

##### part(a, ind)

```jl
part(1:10, 3:5)         =>  3:5
part("abc", 2:3)        =>  "bc"
part(1:10, [3,5,8])     =>  [3,5,8]
part("abc", [3,1,2,2])  =>  "cabb"
a = [1 2 3; 4 5 6]
part(a, 2:3)            =>  [2 3; 5 6]
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

##### @getfield
```jl

```

### <a name="dataflow"></a>Data Layout

##### row
```jl

```

##### col
```jl

```

##### reshape
```jl

```

##### split
```jl

```

##### concat
```jl

```

##### subtoind
```jl

```

##### indtosub
```jl

```

##### stack
```jl

```

##### flatten
```jl

```

##### unstack
```jl

```

##### riffle
```jl

```

##### matrix
```jl

```

##### unmatrix
```jl

```

##### lines
```jl

```

##### unlines
```jl

```

##### unzip
```jl

```

##### findsub
```jl

```

##### randsample
```jl

```

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
@p id (1:10) | show
```

### <a name="views"></a>Efficient Views

typealias View Array

##### View
```jl

```

##### view
```jl

```

##### next!
```jl

```
 
##### trytoview
```jl

```

##### trytoview
```jl

```

### <a name="computing"></a>Computing: map and Friends

##### map
 ```jl

 ```

##### map!
 ```jl

 ```

##### map!r
 ```jl

 ```

##### map2!
 ```jl

 ```

##### mapmap
 ```jl

 ```

##### work
 ```jl

 ```

##### pmapon
 ```jl

 ```

##### pmapover
 ```jl

 ```

##### share
 ```jl

 ```

##### sort
 ```jl

 ```

### <a name="output"></a>Output

##### tee
```jl

```

##### showinfo
```jl

```

##### makeliteral
```jl

```

### <a name="io"></a>I/O

##### read
```jl

```

##### write
```jl

```

##### existsfile
```jl

```

##### mkdir 
```jl

```

##### filenames
```jl

```

##### filepaths
```jl

```

##### dirnames
```jl

```

##### dirpaths
```jl

```

##### readmat
```jl

```

##### writemat
```jl

```

##### @snapshot
```jl

```

### <a name="helpers"></a>Helpers

##### zerossiz
```jl

```

##### onessiz
```jl

```

##### randsiz
```jl

```

##### randnsiz
```jl

```

##### zeroel
```jl

```

##### oneel
```jl

```

##### +
```jl

```

##### * 
```jl

```

##### repeat
```jl

```

##### nop
```jl

```

##### id
```jl

```

##### istrue
```jl

```

##### isfalse
```jl

```

##### not
```jl

```

##### or
```jl

```

##### and
```jl

```

##### any
```jl

```

##### @dict
```jl

```

##### plus
```jl

```

##### minus
```jl

```


##### times
```jl

```

##### divby
```jl

```

### <a name="testmacros"></a>Unit Tests

##### @test_equal
```jl

```

##### @test_almostequal
```jl

```

