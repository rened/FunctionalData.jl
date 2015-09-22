isdefined(:__precompile__) && __precompile__()

module FunctionalData

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
