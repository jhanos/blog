---
title: "Déployer dans Kubernetes en mode GitOps"
date: 2022-12-21
draft: false
author: Jhanos
featuredImage: argo.png
publishDate: 2022-12-21
lang: fr

---



# ArgoCD

## Version courte

[ArgoCD](https://argoproj.github.io/) est un outil GitOps qui se spécialise dans le déploiement dans Kubernetes.

Pour prendre un exemple très simple :

1. Je définis mon environnement dans Git sous forme de code (exemple : des fichiers de déploiement Kubernetes)
2. ArgoCD détecte ce changement
3. ArgoCD applique ce changement dans l'environnement cible.

![Argo Schema](argobrief.png)


ArgoCD vient de récemment franchir un nouveau stade de maturité, il vient de passer au stade "Graduated" dans la CNCF ce qui témoigne de sa maturité.

Argo se déploie à l'intérieur d'un cluster Kubernetes et fournit une interface Web.

Voici ses fonctionnalités principales :
- Affiche l'état de chaque projet 
- Le delta entre l'état souhaité de l'application et l'état réel sous forme de graphique
- On peut facilement appliquer le nouvel état et/ou revenir en arrière

## Version longue
### Continous Deployment

Il existe un grand nombre d'outils pour faire du déploiement continu, la [landscape de la CD foundation](https://landscape.cd.foundation/) permet d'avoir une vue globale.
[ArgoCD](https://argoproj.github.io/) est un outil qui se spécialise dans le déploiement dans Kubernetes.

Il vient récemment de passer au niveau maximum de maturité (graduated) dans la CNCF, ce qui implique :
- un audit de sécurité indépendant
- des contributeurs venant de plusieurs organisations
- un process de versionning et de patch de failles de sécurité
- un nombre suffisant de contributeurs et de commit
- un usage en production chez 3 clients indépendants

C'est aussi le cas de [Flux](https://fluxcd.io/) (son principal concurrent) que je présenterais dans un prochain article.

### L'approche GitOps


{{< admonition note >}}
Le [projet OpenGitOps](https://opengitops.dev/) définit le GitOps selon 4 axes principaux :
1. Declarative: Le systeme (en GitOps) doit décrire l'état cible de manière déclarative.
2. Versioned and Immutable: L'état souhaité doit être stocké de manière versionnée, immuable et contenir l'intégralité de l'historique.
3. Automatically Pulled: Les agents doivent récupérer l'état souhaité depuis la source.
4. Continuously Reconciled: Les agents doivent détecter les changements entre l'état désiré du système et l'état réel du système.
{{< /admonition >}}

Prenons un exemple avec ArgoCD et un déploiement dans Kubernetes :
1. Declarative: Je crée les fichiers yaml qui décrivent mon application dans Kubernetes pour mon environnement de qualif.
2. Versioned and Immutable: Je stocke ces fichiers dans une repository git (GitLab ou GitHub) et je crée des tags pour mes différentes versions.
3. Automatically Pulled: L'agent ArgoCD va scruter toutes les deux minutes (par défaut) mon repository git pour détecter un changement
4. Continuously Reconciled: L'agent ArgoCD va comparer l'état souhaité de mon environnement avec l'état réel dans le cluster Kubernetes et appliquer automatiquement ou non le changement.


### Installation

ArgoCD se déploie uniquement dans un cluster **Kubernetes**.
Il possède deux modes de déploiement :
- un mode simple pour des tests ou un usage en dev
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
- un mode haute disponibilité pour un usage en production


### Fonctionnalités

### Fonctionnalités avancées
trusted delivery

### Sécurité

### Quelques inconvénients



### Conclusion

