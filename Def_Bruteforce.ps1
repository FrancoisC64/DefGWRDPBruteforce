# Script PowerShell pour bloquer des adresses IP distantes sur le pare-feu Windows
# Ce script est déclenché par la génération d'un événement du journal de sécurité 4625 (échec de connexion).
# Il récupère la date et l'heure de l'événement, lit le dernier fichier de log IIS, 
# identifie l'adresse IP publique distante associée à la ligne contenant "POST" et bloque cette adresse IP via le pare-feu Windows,
# sauf si l'adresse IP provient d'une liste d'adresses autorisées.

# Définir le chemin du fichier de log IIS
$logFilePath = "C:\inetpub\logs\LogFiles\W3SVC1\*.log"

# Définir la liste des adresses IP autorisées
$allowedIPs = @("") # Ajoutez ici les adresses IP autorisées

# Définir le chemin du fichier de journalisation
$logFolderPath = "C:\_Support\Scripts\Logs"

# Vérifier et créer le dossier de logs si nécessaire
if (!(Test-Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath -Force | Out-Null
}

# Fonction pour journaliser les messages
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $date = Get-Date -Format "yyyy-MM-dd"
    $logFilePathLog = "$logFolderPath\log-$date.log"
    Add-Content -Path $logFilePathLog -Value "$timestamp - $message"
}

# Fonction vérification IP privée
function IsPrivateIP($ip) {
    return $ip.StartsWith("10.") -or $ip.StartsWith("192.168.") -or $ip.StartsWith("172.16.")
}

# Vérifier et importer les modules nécessaires
$modules = @("Microsoft.PowerShell.Management", "NetSecurity", "Microsoft.PowerShell.Utility")
$modules | ForEach-Object {
    if (-not (Get-Module -ListAvailable -Name $_)) {
        try {
            Import-Module $_ -ErrorAction Stop
            Write-Log "Module $_ importé avec succès."
        } catch {
            Write-Log "Erreur lors de l'importation du module $_ : $_"
            exit
        }
    }
}

# Fonction pour bloquer une adresse IP via le pare-feu Windows
function Block-IP {
    param (
        [string]$ipAddress
    )
    try {
        if (-not (Get-NetFirewallRule | Where-Object { $_.DisplayName -eq "Block $ipAddress" })) {
            New-NetFirewallRule -DisplayName "Block $ipAddress" -Direction Inbound -Action Block -RemoteAddress $ipAddress -Profile Any
            Write-Log "L'adresse IP $ipAddress a été bloquée."
        } else {
            Write-Log "L'adresse IP $ipAddress est déjà bloquée."
        }
    } catch {
        Write-Log "Erreur lors du blocage de l'adresse IP $ipAddress : $_"
    }
}

# Récupérer le dernier événement 4625 du journal de sécurité
try {
    $event = Get-WinEvent -LogName Security | Where-Object { $_.Id -eq 4625 } | Select-Object -First 1
    $xml = [xml]$event.ToXml()
    $eventTimeUTC = [DateTime]$xml.Event.System.TimeCreated.SystemTime
    $eventTimeUTCString = $eventTimeUTC.ToString("yyyy-MM-dd HH:mm:ss")
    $startTime = $eventTimeUTC.AddSeconds(-1).ToString("yyyy-MM-dd HH:mm:ss")
    $endTime = $eventTimeUTC.AddSeconds(1).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Log "evenement : $endTime"
} catch {
    Write-Log "Erreur lors de la récupÃ©ration de l'evenement 4625 : $_"
    exit
}

# Attendre que le fichier de log IIS soit mis à jour
$maxWaitTime = 60
$elapsedTime = 0
$logFileUpdated = $false

while ($elapsedTime -lt $maxWaitTime) {
    $logFile = Get-ChildItem -Path $logFilePath | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($logFile.LastWriteTime -ge $eventTimeUTC1) {
        $logFileUpdated = $true
        break
    }
    Start-Sleep -Seconds 1
    $elapsedTime++
}

if (-not $logFileUpdated) {
    Write-Log "Le fichier de log IIS n'a pas été mis à jour à temps."
    exit
}

# Lire le dernier fichier de log IIS
try {
    $logContent = Get-Content $logFile.FullName -ErrorAction Stop
} catch {
    Write-Log "Erreur lors de la lecture du fichier de log IIS : $_"
    exit
}

# Rechercher l'adresse IP publique associée à un POST correspondant à l'événement 4625
$ipAddresses = $logContent | Where-Object {
    ($_ -match "(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})") -and
    ($matches[1] -ge $startTime) -and
    ($matches[1] -le $endTime) -and
    ($_ -match "POST")
} | ForEach-Object {
    Write-Log $ipAddresses
    if ($_ -match "443.*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})") {
        $matches[1]
    }
}

if ($ipAddresses.Count -gt 1) {
    $ipAddress = $ipAddresses[0]
    Write-Log "Attention : Plusieurs IP détectées, seule la première sera bloquée : $ipAddress"
} else {
    $ipAddress = $ipAddresses
}
if ($ipAddress -ne $null){
Write-Log "IP récupérée : $ipAddress"
}

# Vérifier si l'adresse IP est dans la liste des adresses autorisées
if ($allowedIPs -notcontains $ipAddress -and $ipAddress -ne $null -and -not (IsPrivateIP $ipAddress)) {
    Block-IP -ipAddress $ipAddress
} else {
    if ($ipAddress -eq $null) {
        Write-Log "Aucune IP trouvée correspondant à l'événement $endTime."
    } else {
        Write-Log "L'adresse IP $ipAddress est autorisée."
    }
}
