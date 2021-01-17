# Proj_RECHOP

Ce projet est destiné à répondre à un problème industriel de logistique proposé par Renault sous forme d'instances que l'on trouve dans le sous-dossier `instances` du dossier `Work`.

#### Présentation du problème

Le problème consiste à trouver les routes empruntées par des camions de livraison afin de distribuer des emballages depuis des usines et des sites de lavage vers des fournisseurs. Vous trouverez plus de détail dans le fichier `miniprojet2020-2021.pdf` que vous trouverez dans le dossier `sujet`.

Une difficulté du problème réside dans le grand nombre de données à prendre en compte; le problème se résoud sur un horizon de temps prédéfini, pour différents types d'emballages, sur une instance de la taille de l'Europe ..

#### Résolution du problème

Le code est décomposé en de nombreux fichiers que vous trouverez dans le dossier `Work`.
Les algorithmes utilisés pour résoudre le problème sont rassemblés dans les fichiers `flow.jl`, `dispatch.jl` et `upgrade.jl`. Ils sont appliqués à l'instance choisie dans le fichier `main.jl` lors de l'exécution de ce même fichier.

L'approche adoptée est décrite dans le rapport que vous trouverez au nom de `Projet_RECHOP.pdf`, il s'agit d'une approche à premier abord simpliste puisqu'elle consiste à ne laisser fournir qu'un seul fournisseur à chaque camion, mais elle a l'avantage d'être rapide à l'exécution et d'ainsi rapidement obtenir d'assez bons résultats, ce qui laisse ensuite place à des algorithmes d'amélioration locale des solutions obtenues afin de pouvoir recombiner les camions et permettre des routes plus complètes.

Les solutions du problème sur l'instance `europe.csv` sont présentés dans les fichiers `solution.txt` et `solution2.txt`. Le fichier `totalCost.txt` apporte quelques détails supplémentaires concernant la répartition de différentes contributions au coût total associé à la solution obtenue.