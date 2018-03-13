## FunctionalData

[![Build Status](https://travis-ci.org/rened/FunctionalData.jl.png)](https://travis-ci.org/rened/FunctionalData.jl)
[![Build Status](http://pkg.julialang.org/badges/FunctionalData_0.4.svg)](http://pkg.julialang.org/?pkg=FunctionalData&ver=0.4)
[![Build Status](http://pkg.julialang.org/badges/FunctionalData_0.5.svg)](http://pkg.julialang.org/?pkg=FunctionalData&ver=0.5)
[![Build Status](http://pkg.julialang.org/badges/FunctionalData_0.6.svg)](http://pkg.julialang.org/?pkg=FunctionalData&ver=0.6)


`FunctionalData` is a package for fast and expressive data modification. 

Built around a simple memory layout convention, it provides a small set of general purpose [functional constructs](doc/dataflow.md) as well as routines for [efficient computation](doc/computing.md) with dense numerical arrays.

Optionally, it supplies a [syntax](doc/pipeline.md) for clean, concise code:
 
```jl
wordcount(filename) = @p read filename String | lines | map split | flatten | length
```
 
#### Memory Layout 

Indexing is simplified for dense n-dimensional arrays, which are viewed as collections of (n-1)-dimensional items. 

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

Using a custom `View` type based on this memory layout assumption, the provided `map` operations can be considerably faster than built-ins. Given our data and desired operation:

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

For each of these variants there are optimized functions available for in-place operation on the input array, in-place operation on a new output array, or fallback options for functions which do not work in-place. For details, see the section on [map and Friends](doc/computing.md).

## News

#### 0.0.9

* version requirement for 0.4 build
* `map` and `mapmap` for `Dict`
* fix `typed`

#### 0.0.7 / 0.0.8

* fixed `repeat` for numeric arrays
* made `test_equal` more robust
* reworked `map` and `view` for `Array{T,1}` / scalar return values
* fix `partsoflen`, `concat`
* add `takelast(a)`, `unequal`, `sortpermrev`, `filter`
* fix `map` for `Dict`


#### 0.0.6

* added `localworkers` and `hostpids`
* added `hmap` and variants, which map tasks to the first pid of each machine
* removed `makeliteral`, as the built-in `repr` does the same
* sped up `matrix`
* added map2, map3, map4, map5
* fixed unzip
* added flip, flipdims
* added extract, removed @getfield

## Documentation

Please see the [overview](doc/overview.md) below for one-line descriptions of each function. More details and examples can then be found in the following sections (work in progress)

* [Length and size](doc/lensize.md)
* [Data access](doc/accessors.md)
* [Data Layout](doc/dataflow.md)
* [Pipeline syntax](doc/pipeline.md)
* [Efficient views](doc/computing.md#views)
* [Computing: map and friends](doc/computing.md#computing)
* [Output](doc/output.md)
* [I/O](doc/io.md)
* [Helpers](doc/helpers.md)
* [Unit tests](doc/testmacros.md)

### <a name="overview"></a>Overview

###### Length and Size [[details]](doc/lensize.md)

```jl
len(a)                              # length
siz(a)                              # lsize, ndims x 1
siz3(a)                             # lsize, 3 x 1
```

###### Data Access [[details]](doc/accessors.md)

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
takelast(a,n=1)                     # the last up to elements
drop(a,n)                           # a, except for the first n elements
droplast(a,n=1)                     # a, except for the last n elements
partition(a, n)                     # partition into n parts
partsoflen(a, n)                    # partition into parts of length n
extract(a, field, default)          # get key x of dict or field x of composite type instance
```

###### Data Layout [[details]](doc/dataflow.md)

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
unzip(a)                            # unzip items
findsub(a)                          # return sub for the non-zero entries
randsample(a, n)                    # draw n items from a with repetition
randperm(a)                         # randomly permute order of items
flip(a)                             # reverse the order of items
flipdims(a,d1,d2)                   # flip dims d1 and d2
```

###### Pipeline Syntax [[details]](doc/pipeline.md)

```jl
r = @p f1 a b | f2 | f3 c           # pipeline macro, equals f3(f2(f1(a,b)),c)
r = @p f1 a | f2 b _ | f3 e         # equals f3(f2(b,f1(a)),c)
```

###### Efficient Views [[details]](doc/computing.md)

```jl
view(a,i)                           # lightweight view of item i of a
view(a,i,v)                         # lightweight view of item i of a, reusing v
next!(v)                            # make v point to the i + 1th item of a
trytoview(a,v)                      # for dense array, use view, otherwise part
trytoview(a,v,i)                    # for dense array, use view reusing v, otherwise part
```
 
###### Computing: map and Friends [[details]](doc/computing.md#computing)

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
map2(a,b,f), map3, map4, map5       # map over a and b invoking f(x,y)
work(a, f)                          # apply f to each item, no result value
pwork, lwork, shwork, workwork      # like the corresponding map variants
any(a, f)                           # is any f(item) true
anyequal(a, x)                      # is any item == x
all(a, f)                           # are all f(item) true
allequal(a, x)                      # are all items == x
unequal(a,b)                        # shortcut for !isequal(a,b)
sort(a, f; kargs...)                # sort a accorting to f(item)
uniq(a[, f])                        # unique elements of a or uniq(a,map(a,f))
table(f, a...)                      # like [f(m,n) for m in a[1], n in a[2]], for any length of a
ptable, ltable                      # parallel table using all workers, local workes
tableany, ptableany, ltableany      # like table, but does not flatten result
```

###### Output [[details]](doc/output.md)

```jl
showinfo
tee
```

###### I/O [[details]](doc/io.md)

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
```

###### Helpers [[details]](doc/helpers.md)

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

###### Unit Tests [[details]](doc/testmacros.md)

```jl
@test_equal a b                     # test a and b for equality, show detailed info if not
@assert_equal a b                   # like test_equal, then throws error
@test_almostequal a b maxdiff       # like test_equal, but allows up to maxdiff difference
```





