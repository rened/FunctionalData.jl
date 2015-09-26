export read, write, existsfile, mkdir 
export filenames, filepaths, dirnames, dirpaths
export readmat, writemat
# using MAT

existsfile(filename::AbstractString) = (s = stat(filename); s.inode!=0)

#import Base.mkdir
#function amkdir(a)
#    if a[1]=='/'
#        start = '/';
#    else
#        start = "";
#    end
#
#    if !existsfile(a)
#        parts = split(a,'/');
#        n = len(parts);
#        for i = 1:n
#      @show riffle(parts[1:i],'/')
#        d = [start join(riffle(parts[1:i],'/'))];
#            if !(existsfile(d))
#                Base.mkdir(d)
#            end
#        end
#    end
#end

import Base.read
function read(filename::AbstractString)
    io = open(filename)
    finalizer(io,close)
    r = readall(io)
    close(io)
    return r
end

#function readlines(filename::AbstractString)
#    lines(read(filename))
#end

import Base.write
write(data::AbstractString, filename::AbstractString) = write(data, filename, "w")
function write(data::AbstractString, filename::AbstractString, mode)
    io = open(filename, mode)
    finalizer(io,close)
    write(io,data)
    close(io)
end

function filedirnames(path = pwd(); selector = isdir, hidden = false, withpath = false)
    # @show path selector hidden withpath
    files = readdir(path)
    r = filter(x->selector(joinpath(path,x)) && (hidden || x[1]!='.'), files)
    # @show r
    r = sort(r)
    r = withpath ? map(r, x->joinpath(path,x)) : r
    map(r, utf8)
end
dirnames(path = pwd(); kargs...) = filedirnames(path; selector = isdir, kargs...)
dirpaths(path = pwd(); kargs...) = dirnames(path; withpath = true, kargs...)
filenames(path = pwd(); kargs...) = filedirnames(path; selector = x->!isdir(x), kargs...)
filepaths(path = pwd(); kargs...) = filenames(path; withpath = true, kargs...)

function readmat(filename)
    return matread(filename)
end

readmat(filename,variables) = readmat(filename, variables...)

function readmat(filename,variables...)
    r = Any[]
    mat = matopen(filename)
    try
        for v in variables
            r[v] = read(mat, v)
        end
    finally
        close(mat)
    end
end


