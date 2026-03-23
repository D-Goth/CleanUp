# Black-Lab Windows CleanUp v2.0
**CleanUp** — Outil de nettoyage de Windows 10/11

Supprime le bloatware, désactive la télémétrie, Xbox, OneDrive, Copilot, Recall et les publicités intégrées à Windows — via une interface graphique simple.

---

## 🚀 Lancement

> ⚠️ **Droits administrateur obligatoires** — le script modifie le registre et des services système.

### Méthode recommandée
Double-clic sur `Launch.bat` — la demande UAC s'affiche, tu valides, c'est parti.

### Méthode alternative
**Clic droit** sur `Win11-CleanUp.ps1` → **"Exécuter avec PowerShell"**, puis valider l'UAC.

> ⚠️ **Encodage** — le fichier `.ps1` doit rester en **UTF-8 avec BOM**.

---

## 🧹 Fonctions disponibles

| Bouton | Ce que ça fait |
|---|---|
| **[ Xbox / Game Bar ]** | Désactive GameDVR, Game Bar, supprime les packages Xbox et désactive leurs services |
| **[ Bloatware ]** | Supprime ~30 applications préinstallées inutiles (Cortana, Teams, Solitaire, etc.) |
| **[ Télémétrie ]** | Coupe l'envoi de données à Microsoft (DiagTrack, WAPush, rapports d'erreurs...) |
| **[ OneDrive ]** *(rouge)* | Désinstalle OneDrive, supprime ses restes et bloque sa réinstallation |
| **[ Widgets ]** | Masque le bouton et désactive le service WebExperience |
| **[ Recherche Web ]** | Supprime Bing de la barre de recherche Windows |
| **[ Pubs / Suggestions ]** | Désactive toutes les pubs intégrées (Démarrer, Explorateur, écran de verrouillage) |
| **[ Copilot ]** | Désactive Copilot via GPO et supprime ses packages |
| **[ Recall (24H2+) ]** *(rouge)* | Désactive la fonctionnalité de capture d'écran continue de Microsoft |
| **>> NETTOYAGE COMPLET** | Exécute toutes les étapes dans l'ordre, avec barre de progression |
| **>> Redémarrer** | Redémarre le PC pour appliquer tous les changements |

---

## 🛡️ Sécurité

- Un **point de restauration système** est automatiquement créé au début du nettoyage complet
- Les boutons en **rouge** (OneDrive, Recall) signalent des actions plus agressives / moins réversibles
- Un message d'avertissement s'affiche dans les logs au démarrage

> Pour restaurer Windows à son état d'avant : `Panneau de configuration → Récupération → Ouvrir la Restauration du système`

---

## 📋 Applications supprimées par le Bloatware cleaner

- Clipchamp, Cortana, BingNews, BingWeather
- GetHelp, Getstarted, Messaging, OfficeHub
- Solitaire, MixedReality Portal, OneNote
- Outlook (nouveau), People, PowerAutomate, Todo
- DevHome, Alarmes, Caméra, Courrier/Calendrier
- FeedbackHub, Maps, Enregistreur vocal
- Groove Music, Films & TV, Téléphone
- Microsoft Teams (intégré + nouvelle version)
- Copilot, Windows Copilot Provider

> `Microsoft.Windows.Photos` n'est **pas** dans la liste — l'appli Photos native est conservée.

---

## ⚙️ Compatibilité

| OS | Support |
|---|---|
| Windows 11 (toutes versions) | ✅ Complet |
| Windows 11 24H2+ | ✅ + désactivation Recall |
| Windows 10 | ✅ Partiel (Recall/Copilot absents, reste fonctionnel) |

---

## 📁 Structure du projet

```
📦 Win11-Debloater/
├── Win11-CleanUp.ps1   ← Script principal (UTF-8 BOM)
├── Launch.bat          ← Lanceur double-clic
└── README.md           ← Ce fichier
```

---

## 👤 Auteur

**D-Goth** — [Black-Lab.fr](https://black-lab.fr)
Version 2.0
