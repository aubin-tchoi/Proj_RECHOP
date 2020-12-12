# Proj_RECHOP

Code Julia Dalle:

VERIFICATION (test des solutions):
-cost.jl: fonctions de calculs de  coûts (séparément, et somme)
-feasibility: fonctions de vérifications des contraintes (vérification sur solution)
-route.jl: structure route, fonction de parsing des routes + autres
-plot.jl: du plot à foison
-graphe.jl: ? (je sais pas ce que ça fait, mais y en a besoin pour parser les instances donc faut pas l'oublier)
-solution.jl: structure solution ( ce qui est parsé en écriture dans write.jl), fonction de parsing en lecture d'une solution, fonction compute_stocks


LECTURE DE L'INSTANCE:
-dimensions.jl: fonction de parsing de la premiere ligne (nb jours, usines, fournisseurs,...)
-emballage.jl: strucutre emballage, fonction de parsing emballages
-fournisseur.jl: structure fournisseur, fonction de parsing fournisseurs
-usine.jl: structure usine, fonction de parsing usines
-instance.jl: structure instance, fonction de parsing des instances (utilise les fonctions des autres .jl et les applique pour parser en lecture les données)


ECRITURE DE LA SOLUTION (à partir des routes cf. la structure route):
-write.jl: plein de fonctions qui permettent de parser en éciture la solution (si on les utilise bien), mais un peu fouillie (ça sera sûrement plus simple de refaire notre propre parseur)



Je pense qu'on peut se servir des codes de lecture pour gagner pas mal de temps sur le parsing, en plus ça nous fixe la syntaxe des paramètres. En théorie on devrait pas avoir besoin des codes de vérification (mais on pourrait se servir de la structure route, et on pourrait utiliser les coûts pour construire des heuristiques). Et pour l'écriture de la solution je trouve le code pas très clair et sûrement plus rapide de le refaire nous même en s'en inspirant (quitte à reprendre la structure solution). 

J'ai créé un dossier Codes où on peut commencer notre projet. J'y ai mis les jl de Dalle que je pense qu'on peut utiliser (cf juste au-dessus). J'ai créé un code julia corps_projet.jl qui a vocation à contenir le corps de notre code (celui dans lequel on ne fait qu'appeler les fonctions des différents .jl organisés): l'équivalent du notebook de Dalle). (J'ai juste include les jl et executé la lecture de l'instance + affichage pour l'instant).


//////////////////////////////////////////////////////

NV VARIABLES:
petite_instance = lire_instance(joinpath("..", "instances", "europe.csv"))                #parsing de guillaume, base de tout le reste

Ensemble_Routes = Array{Route,1}(undef,0)                        #ensemble de routes qu'on établit pour résoudre le pb (ce qui sera passé à la fin) donc initialement vide

S_emballages_disponibles_usines = Array{Int64}(undef,petite_instance.U,petite_instance.E)               #vecteur s_euj pour le jour courant
S_emballages_disponibles_fournisseurs = Array{Int64}(undef,petite_instance.F,petite_instance.E)         #vecteur s_efj pour le jour courant



J'ai réussi à tester une solution et obtenir son coup avec le code Julia mais pas avec le code C++.
J'ai créé un fichier Julia (Test_Solution.jl dans le dossier code_Julia) qui teste la solution (plus simple que d'utiliser le notebook) mais j'ai pas réutilisé toutes les features de ploting de guillaume (on peut les rajouter si besoin, suffit de c/c son code).
J'ai fait implémenté une heuristique ultraaa simple dans corps_projet.jl . Ca fournit une sol admissible mais après l'avoir testée ça donne un coût éclaté au sol (pire que si on ne fait aucune route). (642 sur petite.csv et xxx Ca tourne pas !!)
Dans ce code vous pouvez choper les variables et tout ce que j'ai fait (très pratique pour comprendre les structures implémentées par guillaume), notamment le parsing: j'avais écrit la dernière fois que leur parsing était fumé mais en fait il est très bien, du coup j'utilise aussi write.jl et solution.jl .

