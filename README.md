# Blocage automatique d'adresses IP avec Windows Firewall

## Description

Ce script PowerShell permet de bloquer automatiquement les adresses IP distantes responsables d'échecs d'authentification (événements 4625) en utilisant le pare-feu Windows. Il analyse également les journaux IIS pour identifier les requêtes suspectes.

## Prérequis

- Windows Server avec IIS et le pare-feu Windows activé
- Droits administrateurs pour exécuter le script
- PowerShell 5.1 ou supérieur
- Accès au journal des événements de sécurité

## Installation

1. **Exécuter le script d'installation `installDefBruteForce.ps1`** Actuelement le script échoue sur deux point voir roadmap.md
   
   Ce script automatise la configuration en réalisant les étapes suivantes :
   - Récupère les événements 302 du journal de la passerelle RDP pour identifier les connexions distantes.
   - Utilise une API GeoIP pour identifier les connexions hors de France.
   - Ajoute l'IP publique du serveur et les IPs françaises détectées à la liste blanche.
   - Télécharge et met à jour le script de blocage avec la liste d'IPs autorisées.
   - Crée une tâche planifiée pour surveiller les événements 4625 (échecs de connexion) et exécuter le script de blocage.
   
   Pour exécuter le script :
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process
   .\installDefBruteForce.ps1
   ```

2. **Vérification et ajustement**
   - Assurez-vous que le script de blocage est bien téléchargé et que la liste des IPs autorisées est correcte.
   - Vérifiez que la tâche planifiée `MonitorFailedLogins` est bien créée et active.

## Utilisation

Une fois installé, le script de blocage s'exécute automatiquement lorsqu'un échec d'authentification est détecté.

### Vérifier les logs d'exécution
Les journaux sont enregistrés dans :
```
C:\_Support\Scripts\Logs
```
Vous pouvez les consulter avec :
```powershell
Get-Content C:\_Support\Scripts\Logs\log-$(Get-Date -Format "yyyy-MM-dd").log
```

## Sécurité

- Ne pas exécuter le script avec des droits administrateurs permanents si ce n'est pas nécessaire.
- Vérifiez régulièrement la liste des IPs bloquées pour éviter les faux positifs.
- Testez le script dans un environnement de pré-production avant de le déployer en production.

## Désinstallation

Pour supprimer la tâche planifiée et désactiver le script :
```powershell
Unregister-ScheduledTask -TaskName "MonitorFailedLogins" -Confirm:$false
```

## Auteurs
Ce script a été développé pour automatiser la protection contre les attaques par force brute sur Windows Server.

