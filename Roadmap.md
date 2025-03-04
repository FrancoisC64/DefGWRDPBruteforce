# Roadmap de Développement et d'Amélioration

## Objectif
Améliorer le script de défense contre les attaques par brute force sur les passerelles RDS en corrigeant les erreurs existantes et en optimisant son fonctionnement.

## Problèmes Identifiés
### 1. Format incorrect de la liste des IP autorisées dans le script d'installation
- **Problème** : La liste des IP autorisées (variable `$allowedips`) n'est pas correctement formatée. Il manque des guillemets au début et à la fin de la collection.
- **Impact** : Le script ne fonctionne pas correctement et peut empêcher l'ajout des IP autorisées.

### 2. Problème de création de la tâche planifiée avec un fichier de réponse XML
- **Problème** : La création de la tâche planifiée à l'aide d'un fichier de réponse XML ne fonctionne pas correctement.
- **Impact** : La tâche planifiée n'est pas ajoutée correctement, empêchant l'exécution automatique du script.

## Plan de Correction et d'Amélioration

### Étape 1 : Correction du Format de `$allowedips`
- Ajouter les guillemets nécessaires pour s'assurer que la collection d'adresses IP est bien formée.
- Tester la modification pour vérifier que le format est correctement interprété par le script.

### Étape 2 : Correction de la Création de la Tâche Planifiée
- Vérifier la syntaxe et la compatibilité du fichier de réponse XML avec `schtasks`.
- S'assurer que les permissions et les chemins utilisés dans le fichier XML sont corrects.
- Tester la création de la tâche planifiée en mode manuel et automatique.

### Étape 3 : Vérification et Validation du Script d'Installation
- Exécuter des tests sur différentes configurations pour s'assurer que la liste des IP est bien prise en compte.
- Ajouter des logs pour afficher la liste des IP autorisées et détecter d'éventuelles erreurs de syntaxe.

### Étape 4 : Automatisation des Vérifications
- Intégrer un mécanisme de validation des entrées pour éviter les erreurs de format dans `$allowedips`.
- Ajouter un message d'erreur explicite si le format de la liste des IP est incorrect.
- Ajouter une vérification après la création de la tâche planifiée pour confirmer son existence et son bon fonctionnement.

### Étape 5 : Documentation et Bonnes Pratiques
- Mettre à jour la documentation du script pour préciser le format attendu de la liste des IP.
- Fournir un exemple correct pour éviter les erreurs lors des futures mises à jour.
- Documenter la configuration correcte du fichier de réponse XML pour la tâche planifiée.

### Étape 6 : Tests et Déploiement
- Effectuer des tests en environnement contrôlé avant le déploiement en production.
- S'assurer que toutes les corrections sont prises en compte et que le script fonctionne sans erreur.

## Suivi et Évolution
- Prévoir une révision périodique du script pour anticiper d'autres éventuelles erreurs.
- Documenter toute modification apportée pour faciliter la maintenance future.

