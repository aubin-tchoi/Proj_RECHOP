include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")

petite_instance = lire_instance(joinpath("..", "instances", "petite.csv"))     #pour l'instant parse petite.csv

Base.show(petite_instance)
