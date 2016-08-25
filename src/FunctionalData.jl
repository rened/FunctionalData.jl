__precompile__()

module FunctionalData

FD = FunctionalData
export FD

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
