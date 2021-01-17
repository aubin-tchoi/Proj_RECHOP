using PyPlot: pygui
pygui(true)
using Plots
pyplot()

include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")

include("route.jl")
include("solution.jl")

include("plot.jl")
include("feasibility.jl")
include("cost.jl")

include("write.jl")



instance_petite = lire_instance(joinpath("..", "sujet", "petite.csv"))

solution_petite = lire_solution(joinpath("..", "sujet", "meta_solution.txt"))

cost(solution_petite, instance_petite, verbose=true)

write_sol_to_file(solution_petite, joinpath("..", "sujet", "petite_copy.txt"))

println("The solution is feasible for petite.csv: ", feasibility(solution_petite, instance_petite))




#EUROPE
instance_europe = lire_instance(joinpath("..", "instance", "europe.csv"))
