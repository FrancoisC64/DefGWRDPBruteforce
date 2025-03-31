# Activer TLS 1.2 pour éviter les erreurs SSL/TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Récupérer les événements 302 de la passerelle RDP
$events = Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-Gateway/Operational" | Where-Object { $_.Id -eq 302 }

# Initialiser une liste pour stocker les informations des connexions
$connections = @()
$frenchIPs = @()
# Créer les dossiers si inexistants
$scriptFolder = "C:\_support\Scripts"
$logFolder = "C:\_support\Scripts\Logs"
$jsonFile = "C:\_support\Scripts\ips.json"
if (!(Test-Path $scriptFolder)) { New-Item -ItemType Directory -Path $scriptFolder -Force }
if (!(Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder -Force }

# Extraire l'adresse IP, la date de connexion et l'utilisateur
foreach ($event in $events) {
    if ($event.Message -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
        $ip = $matches[0]
        $date = $event.TimeCreated
        if ($event.Message -match 'User:\s+(\S+)') {
            $user = $matches[1]
        } else {
            $user = "Inconnu"
        }
        
        $connections += [PSCustomObject]@{
            IP = $ip
            Date = $date
            Utilisateur = $user
        }
    }
}

# Supprimer les doublons
$uniqueConnections = $connections | Sort-Object IP -Unique

# Vérifier la géolocalisation des IPs via l'API GeoIP de MaxMind
#foreach ($conn in $uniqueConnections) {
#    $url = "https://freegeoip.app/json/$($conn.IP)"
#    try {
#        $response = Invoke-RestMethod -Uri $url -Method Get
#        if ($response.country_name -ne "France") {
#            Write-Output "IP: $($conn.IP) - Pays: $($response.country_name), Ville: $($response.city), Région: $($response.region_name) - Date: $($conn.Date) - Utilisateur: $($conn.Utilisateur)"
#        } else {
#            $frenchIPs += $conn.IP
#        }
#    } catch {
#        Write-Output "Impossible d'obtenir la géolocalisation pour l'IP: $($conn.IP)"
#    }
#}

# Obtenir l'IP publique du serveur
# Télécharger le contenu de la page
$pageContent = Invoke-WebRequest -Uri "http://monip.org" -UseBasicParsing

# Extraire l'adresse IP avec une expression régulière
if ($pageContent.Content -match "IP\s*:\s*([\d\.]+)") {
    $serverIP = $matches[1]
} else {
    Write-Output "Impossible de récupérer l'adresse IP publique."
    $serverIP = $null
}


# Créer les dossiers si inexistants
$scriptFolder = "C:\_support\Scripts"
$logFolder = "C:\_support\Scripts\Logs"
if (!(Test-Path $scriptFolder)) { New-Item -ItemType Directory -Path $scriptFolder -Force }
if (!(Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder -Force }

# Télécharger le script depuis GitHub
$scriptURL = "https://raw.githubusercontent.com/FrancoisC64/DefGWRDPBruteforce/refs/heads/main/Def_Bruteforce.ps1"
$scriptPath = "$scriptFolder\Def_Bruteforce.ps1"
Invoke-WebRequest -Uri $scriptURL -OutFile $scriptPath

# Modifier le fichier Def_Bruteforce.ps1 en remplaçant les IPs françaises
if (Test-Path $scriptPath) {
# Extraire uniquement les adresses IP uniques
$allowedIPs = @()
$allowedIPs += $uniqueConnections.IP
$allowedIPs += $serverIP
# Créer un objet PowerShell avec la structure JSON
$jsonData = @{ allowedIPs = $allowedIPs } | ConvertTo-Json -Depth 1
# Écrire l'objet JSON dans un fichier
$jsonData | Set-Content -Path $jsonFile -Encoding UTF8
# Afficher un message de confirmation
Write-Output "Le fichier JSON a été créé : $jsonFile"
}
