include("dimensions.jl")
include("emballage.jl")
include("usine.jl")
include("fournisseur.jl")
include("graphe.jl")
include("instance.jl")
include("solution.jl")
include("write.jl")

petite_instance = lire_instance(joinpath("..", "instances", "europe.csv"))     #pour l'instant parse petite.csv

Base.show(petite_instance)


#Variables
Ensemble_Routes = Array{Route,1}(undef,0)

S_emballages_disponibles_usines = Array{Int64}(undef,petite_instance.U,petite_instance.E)
S_emballages_disponibles_fournisseurs = Array{Int64}(undef,petite_instance.F,petite_instance.E)


#Initialisation
for u in 1:petite_instance.U
    for e in 1:petite_instance.E
        S_emballages_disponibles_usines[u,e] = petite_instance.usines[u].s0[e]
    end
end
for f in 1:petite_instance.F
    for e in 1:petite_instance.E
        S_emballages_disponibles_fournisseurs[f,e] = petite_instance.fournisseurs[f].s0[e]
    end
end


#Heuristique: chaque jour, pour chaque fournisseur et pour chaque emballage, on utilise un camion. Si 1 n'est pas suffisant on en utilise autant qu'il faut.
#on commence par utiliser les ressources de la 1ere usine (index 0 dans l'instance, 1 dans Julia) puis la suivante si besoin etc...
#Les routes sont donc de taille 1 (un seul fournisseur) et ne contiennent qu'un type d'emballage. On cherche à toujours avoir pile le stock nécessaire
#pour la journée suivante (pas toujours possible sur europe d'où le [ u==nbUsines --> break ] ).
#On remarque qu'il n'y a jamais besoin de transporter le dernier jour (quelque soit l'heuristique a priori)
for j in 1:(petite_instance.J-1)

    for u in 1:petite_instance.U                #dynamique des emballages usines matin
        for e in 1:petite_instance.E
            S_emballages_disponibles_usines[u,e] += petite_instance.usines[u].b⁺[e,j]
        end
    end


    for f in 1:petite_instance.F               #dynamique des emballages fournisseurs soir (sans intervention usines)
        for e in 1:petite_instance.E
            S_emballages_disponibles_fournisseurs[f,e] -= petite_instance.fournisseurs[f].b⁻[e,j]
            S_emballages_disponibles_fournisseurs[f,e] = max(S_emballages_disponibles_fournisseurs[f,e],0)
        end
    end


    for f in 1:petite_instance.F               #application de l'heuristique
        for e in 1:petite_instance.E

                    u = 0                    #on va chercher les ressources des usines dans l'ordre
                    while S_emballages_disponibles_fournisseurs[f,e] < petite_instance.fournisseurs[f].b⁻[e,j+1]
                        q = 0                    #quantité envoyé par cette route
                        Q = []
                        u += 1
                        while S_emballages_disponibles_usines[u,e] > 0                           #dynamique
                            S_emballages_disponibles_usines[u,e] -= 1
                            S_emballages_disponibles_fournisseurs[f,e] += 1
                            q += 1

                            if S_emballages_disponibles_fournisseurs[f,e] == petite_instance.fournisseurs[f].b⁻[e,j+1]
                                break
                            end
                        end

                        for E in 1:petite_instance.E                #Création de la route associée
                            push!(Q, 0)
                            if E==e
                                Q[length(Q)] = q
                            end
                        end
                        push!(Ensemble_Routes, Route(r = length(Ensemble_Routes)+1, j = j, x = 1, u = u, F = 1, stops = [RouteStop(f = f, Q = Q)]))

                        if u==petite_instance.U
                            break
                        end


                    end

        end
    end


#Parsing de la solution
meta_solution = Solution(R = length(Ensemble_Routes), routes = Ensemble_Routes)
write_sol_to_file(meta_solution, joinpath("..","meta_solution_europe.txt"))

end
