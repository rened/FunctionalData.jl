module FunctionalData
using Compat

assert(VERSION.minor == 3 || VERSION >= v"0.4.0-dev+4238")

include("lensize.jl")
include("accessors.jl")
include("views.jl")
include("basics.jl")
include("pipeline.jl")
include("dataflow.jl")
include("computing.jl")
include("io.jl")
include("output.jl")
include("testmacros.jl")

end
