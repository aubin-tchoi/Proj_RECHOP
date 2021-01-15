include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("route.jl")
include("solution.jl")
include("write.jl")

##### Fonction de parsing de sous-instance #########################
function write_instance(instance::Instance, path::String)::Bool
    open(path, "w") do file
        write(
            file,
            "J $(instance.J) U $(instance.U) F $(instance.F) E $(instance.E) L $(instance.L) Gamma $(instance.γ) CCam $(instance.ccam) CStop $(instance.cstop)\n",
        )
        for e in instance.emballages
            write(file, "e $(e.e-1) l $(e.l)\n")
        end
        for u in instance.usines
            write(file, "u $(u.u-1) v $(u.v-1) coor $(u.coor[1]) $(u.coor[2]) ce")
            for e in instance.emballages
                write(file, " e $(e.e-1) cr $(u.cs[e.e]) b $(u.s0[e.e])")
            end
            write(file, " lib")
            for j = 1:instance.J
                write(file, " j $(j-1)")
                for e in instance.emballages
                    write(file, " e $(e.e-1) b $(u.b⁺[e.e,j]) r $(u.r[e.e,j])")
                end
            end
            write(file, "\n")
        end
        for f in instance.fournisseurs
            write(file, "f $(f.f-1) v $(f.v-1) coor $(f.coor[1]) $(f.coor[2]) ce")
            for e in instance.emballages
                write(
                    file,
                    " e $(e.e-1) cr $(f.cs[e.e]) cexc $(f.cexc[e.e]) b $(f.s0[e.e])",
                )
            end
            write(file, " dem")
            for j = 1:instance.J
                write(file, " j $(j-1)")
                for e in instance.emballages
                    write(file, " e $(e.e-1) b $(f.b⁻[e.e,j]) r $(f.r[e.e,j])")
                end
            end
            write(file, "\n")
        end
        for v1 in instance.usines
            for v2 in instance.usines
                write(file, "a $(v1.v-1) $(v2.v-1) d $(instance.graphe.d[v1.v,v2.v])\n")
            end
            for v2 in instance.fournisseurs
                write(file, "a $(v1.v-1) $(v2.v-1) d $(instance.graphe.d[v1.v,v2.v])\n")
            end
        end
        for v1 in instance.fournisseurs
            for v2 in instance.usines
                write(file, "a $(v1.v-1) $(v2.v-1) d $(instance.graphe.d[v1.v,v2.v])\n")
            end
            for v2 in instance.fournisseurs
                write(file, "a $(v1.v-1) $(v2.v-1) d $(instance.graphe.d[v1.v,v2.v])\n")
            end
        end

    end
    return true
end

##### Fonction de découpage de l'instance #########################################
function decoupage_instance(instance::Instance, Nbr_regions_x::Int64, Nbr_regions_y::Int64, X::Array, Y::Array)
    min_x = typemax(Int)
    min_y = typemax(Int)
    max_x = typemin(Int)
    max_y = typemin(Int)

    for f in instance.fournisseurs
        if max_x < f.coor[1]
            max_x = f.coor[1]
        elseif min_x > f.coor[1]
            min_x = f.coor[1]
        end

        if max_y < f.coor[2]
            max_y = f.coor[2]
        elseif min_y > f.coor[2]
            min_y = f.coor[2]
        end
    end

    x_range_region = (max_x - min_x) / Nbr_regions_x
    y_range_region = (max_y - min_y) / Nbr_regions_y

    for x = 1:Nbr_regions_x
        for y = 1:Nbr_regions_y
            F_temp = []
            U_temp = []
            for f in instance.fournisseurs
                if f.coor[1] >= min_x + x_range_region * (x - 1) &&
                   f.coor[1] <= min_x + x_range_region * (x) &&
                   f.coor[2] >= min_y + y_range_region * (y - 1) &&
                   f.coor[2] <= min_y + y_range_region * (y)
                    push!(F_temp, f)
                end
            end
            for u in instance.usines
                if u.coor[1] >= min_x + x_range_region * (x - 1) &&
                   u.coor[1] <= min_x + x_range_region * (x) &&
                   u.coor[2] >= min_y + y_range_region * (y - 1) &&
                   u.coor[2] <= min_y + y_range_region * (y)
                    push!(U_temp, u)
                end
            end
            println(" ")
            println("\n Fournisseurs de la région (", x, ",", y, ") : ", length(F_temp))

            if length(F_temp) == 0
                continue
            end

            U_new = []
            F_new = []
            iterateur = 1
            for u in U_temp
                push!(
                    U_new,
                    Usine(
                        u = iterateur,
                        v = iterateur,
                        coor = u.coor,
                        cs = u.cs,
                        s0 = u.s0,
                        b⁺ = u.b⁺,
                        r = u.r,
                    ),
                )
                iterateur += 1
            end
            iterateur = 1
            for f in F_temp
                push!(
                    F_new,
                    Fournisseur(
                        f = iterateur,
                        v = length(U_new) + iterateur,
                        coor = f.coor,
                        cs = f.cs,
                        cexc = f.cexc,
                        s0 = f.s0,
                        b⁻ = f.b⁻,
                        r = f.r,
                    ),
                )
                iterateur += 1
            end

            V_temp = vcat(U_temp, F_temp)
            G_new = SimpleDiGraph(length(U_new) + length(F_new))
            d_new = zeros(Int, length(U_new) + length(F_new), length(U_new) + length(F_new))
            for i = 1:length(U_new)+length(F_new)
                for j = 1:length(U_new)+length(F_new)
                    d_new[i, j] = instance.graphe.d[V_temp[i].v, V_temp[j].v]
                end
            end

            instance_temp = Instance(
                J = instance.J,
                U = length(U_new),
                F = length(F_new),
                E = instance.E,
                L = instance.L,
                γ = instance.γ,
                ccam = instance.ccam,
                cstop = instance.cstop,
                emballages = instance.emballages,
                usines = U_new,
                fournisseurs = F_new,
                graphe = Graphe(G = G_new, d = d_new),
            )

            name_file = "sous-instance_" * string(x) * "_" * string(y) * ".csv"
            write_instance(instance_temp, name_file)

            name_file_2 =
                "correspondance_fournisseurs_" * string(x) * "_" * string(y) * ".csv"
            open(name_file_2, "w") do file
                for f in F_temp
                    write(file, "$(f.f) ")
                end
            end

            push!(X, x)
            push!(Y, y)

        end
    end
end

####################### Résolution Optimale en temps limité de création de clusters sur instance globale, taille clusters fixée ##############
using JuMP, Gurobi

function Solution_Optimale(instance::Instance)
    model = Model(with_optimizer(Gurobi.Optimizer, TimeLimit = Time_max_optimization))

    @variable(model, Clusters_matrix[1:Nbr_clusters, 1:instance.F], Bin)

    for i = 1:Nbr_clusters
        @constraint(
            model,
            sum(Clusters_matrix[i, j] for j = 1:instance.F) <= taille_max_clusters
        )
        @constraint(model, sum(Clusters_matrix[i, j] for j = 1:instance.F) >= 1)
    end

    for j = 1:instance.F
        @constraint(model, sum(Clusters_matrix[i, j] for i = 1:Nbr_clusters) >= 1)
    end


    #la fonction coût calcule la somme des distance entre tous les fournisseurs (donc pour 4 fournisseurs, il y a 3*4 distance de calculées, même si certaines sont les mêmes)
    #on ajoute également une pénalisation de 150*2*le nombre de clusters (plus il y a de clusters, plus on devra créer de route) (toutes les distances sont comptées 2 fois)
    #on rajoute un facteur 2 a ce dernier terme en supposant grossierement qu'en moyenne on enverra 2 camion par clusters tous les jours (à peu près correct pour les 'petits' clusters)
    @objective(
        model,
        Min,
        sum(
            sum(
                first(
                    transpose(vcat(
                        zeros(instance.U + j - 1, 1),
                        Clusters_matrix[i, j],
                        zeros(instance.F - j),
                    )) *
                    instance.graphe.d *
                    vcat(
                        zeros(instance.U, 1),
                        Clusters_matrix[i, 1:j-1],
                        zeros(1, 1),
                        Clusters_matrix[i, j+1:instance.F],
                    ),
                ) for j = 1:instance.F
            ) for i = 1:Nbr_clusters
        ) + 150 * Nbr_clusters * 2 * 2
    )

    JuMP.optimize!(model)

    for i = 1:Nbr_clusters
        for j = 1:instance.F
            Clusters_fournisseurs_temp[i,j] = JuMP.value(Clusters_matrix[i,j])
        end
    end


    return JuMP.objective_value(model)
    print(" ")
end
##############################################################################################



function makeClusters(instance::Instance, Nbr_regions_x::Int64, Nbr_regions_y::Int64)
    ### Création des clusters ###

    Base.show(instance)

    Clusters_matrix_complete = Array{Array{Int64,2},1}(undef, 0)
    X = []
    Y = []

    decoupage_instance(instance, Nbr_regions_x, Nbr_regions_y, X, Y)

    for i = 1:length(X)
        x = X[i]
        y = Y[i]
        name_file = "sous-instance_" * string(x) * "_" * string(y) * ".csv"
        instance_temp = lire_instance(name_file)

        global Nbr_clusters = ceil(Int, instance_temp.F / taille_max_clusters)
        global Clusters_fournisseurs_temp = zeros(Nbr_clusters, instance_temp.F)

        println(Solution_Optimale(instance_temp))

        name_file_2 = "correspondance_fournisseurs_" * string(x) * "_" * string(y) * ".csv"
        correspondance_fournisseurs_text = open(name_file_2) do file
            readlines(file)
        end
        correspondance_vect_text = split(correspondance_fournisseurs_text[1])
        correspondance_fournisseurs = []
        for f in correspondance_vect_text
            push!(correspondance_fournisseurs, parse(Int, f))
        end

        for i = 1:Nbr_clusters
            cluster_temp_index_complet = zeros(Int64, 1, instance.F)
            for j in 1:instance_temp.F
                if Clusters_fournisseurs_temp[i,j] == 1
                    cluster_temp_index_complet[correspondance_fournisseurs[j]] = 1
                end
            end
            push!(Clusters_matrix_complete, cluster_temp_index_complet)
        end
    end

    #println(Solution_Optimale(instance))
    #println(Clusters_fournisseurs)

    return Clusters_matrix_complete
end