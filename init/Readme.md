Voici la procédure détaillée pour initialiser Terraform avec AWS depuis ton poste local en utilisant l'utilisateur admin "pylejeune" :

---

### 1. **Installation des prérequis**
Avant de commencer, installe les outils nécessaires :

#### a) **Installer AWS CLI**
L'AWS CLI est essentiel pour configurer ton environnement et interagir avec AWS.

- **Windows** : Télécharge et installe [AWS CLI](https://awscli.amazonaws.com/AWSCLIV2.msi).
- **MacOS** : Utilise Homebrew :
  ```sh
  brew install awscli
  ```
- **Linux** : Télécharge et installe avec :
  ```sh
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```

Vérifie l'installation :
```sh
aws --version
```

#### b) **Installer Terraform**
- **Windows** : Télécharge [Terraform](https://developer.hashicorp.com/terraform/downloads) et ajoute-le au PATH.
- **MacOS** :
  ```sh
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
  ```
- **Linux** :
  ```sh
  sudo apt update && sudo apt install -y terraform
  ```

Vérifie l'installation :
```sh
terraform version
```

---

### 2. **Configurer AWS CLI avec l’utilisateur "pylejeune"**
Tu dois utiliser tes clés d’accès AWS pour configurer l’authentification.

Exécute :
```sh
aws configure
```
Renseigne les informations demandées :
- **AWS Access Key ID** : (`clé d’accès de pylejeune`)
- **AWS Secret Access Key** : (`clé secrète de pylejeune`)
- **Default region** : (`ex: eu-west-1`)
- **Output format** : (`json` par défaut)

Vérifie que la configuration est bien prise en compte :
```sh
aws sts get-caller-identity
```
Si tout est bien configuré, tu verras l'ARN de ton utilisateur AWS.

---

### 3. **Initialisation d’un projet Terraform**
Crée un répertoire de travail pour ton projet :
```sh
mkdir terraform-aws && cd terraform-aws
```
Dans ce répertoire, crée un fichier `main.tf` :
```sh
touch main.tf
```
Ajoute ce code pour déclarer un provider AWS :
```hcl
provider "aws" {
  region = "eu-west-1"
}
```
Puis, initialise Terraform :
```sh
terraform init
```

Si tout fonctionne, Terraform téléchargera les plugins nécessaires.

---

### 4. **Créer une première ressource (Exemple : S3 Bucket)**
Ajoute dans `main.tf` :
```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "mon-premier-bucket-terraform-123456"
}
```
Applique les changements :
```sh
terraform apply
```
Confirme avec `yes`.

Vérifie dans AWS si le bucket a bien été créé.

---

### 5. **Nettoyer les ressources**
Si tu veux supprimer les ressources créées :
```sh
terraform destroy
```
Confirme avec `yes`.

---

Tu es maintenant prêt à utiliser Terraform avec AWS ! 🚀