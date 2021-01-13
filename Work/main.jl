########################### Formation de clusters par région ######################


#INCLUDES
include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")
include("clusters.jl")
include("plne.jl")

instance = lire_instance("Work/instances/maroc.csv")

######################### Variables ###############################
taille_max_clusters = 4                       #Hors usine #attention petite.csv n'a que 3 fournisseurs et il faut taille_clusters<=instance.F
#global Nbr_clusters = ceil(Int, instance.F / taille_max_clusters)    #min = part_ent_sup(instance.F/taille_clusters) le coût d'introduction d'une nouvelle route est 150* plus importante que le coût kilométrique. Il est donc probable qu'il soit plus intéressant de prendre le nbr de route minimum qui à ce que chaque camion parcours plus de distance.
Nbr_regions_x = 8
Nbr_regions_y = 3
Time_max_optimization = 1        #in sec


clusters = makeClusters(instance, Nbr_regions_x, Nbr_regions_y)

println("CLUSTERS OK")
plne_sol = solve_plne(instance, formatClusters(instance, clusters), 300) 

