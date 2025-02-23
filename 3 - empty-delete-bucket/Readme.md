Pour vider un bucket S3 avec Terraform, voici une approche simple et efficace :

### 1. **Utiliser `aws_s3_bucket` avec `force_destroy`**
Si ton objectif est de supprimer le bucket en même temps que son contenu, la meilleure solution est d'activer `force_destroy` dans la ressource Terraform :

```hcl
resource "aws_s3_bucket" "example" {
  bucket        = "mon-bucket-example"
  force_destroy = true
}
```
⚠️ **Attention** : Cela supprimera définitivement toutes les données du bucket lorsque Terraform détruira la ressource.

---

### 2. **Vider un bucket existant sans le supprimer**
Si tu veux vider un bucket sans le supprimer, Terraform ne fournit pas de ressource native pour supprimer les objets. Il faut utiliser une **policy de cycle de vie** ou **un script externe**.

#### ✅ **Option 1 : Utiliser un `aws_s3_bucket_lifecycle_configuration` pour l'expiration des objets**
Cela permet de supprimer automatiquement tous les objets après un certain délai.

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id = "delete-all"
    status = "Enabled"

    expiration {
      days = 1 # Supprime tous les objets après 1 jour
    }
  }
}
```
⚠️ Les objets ne seront pas supprimés immédiatement.

---

#### ✅ **Option 2 : Utiliser `aws_s3_object` et Terraform pour supprimer les fichiers**
Si tu gères un nombre limité de fichiers dans le bucket, tu peux déclarer et supprimer les objets explicitement :

```hcl
resource "aws_s3_object" "example" {
  bucket = aws_s3_bucket.example.id
  key    = "mon-fichier.txt"
  source = "/dev/null"
}
```
Puis, en supprimant cette ressource, Terraform supprimera l'objet.

---

#### ✅ **Option 3 : Exécuter un script `aws s3 rm` via Terraform**
Si le bucket contient beaucoup de fichiers, tu peux utiliser un **provisioner local-exec** pour exécuter la commande AWS CLI :

```hcl
resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://mon-bucket-example --recursive"
  }
}
```

---

💡 **Conclusion :**  
- **Si tu supprimes le bucket**, active `force_destroy`.  
- **Si tu veux juste le vider**, utilise un **lifecycle rule**, une **suppression via Terraform**, ou **AWS CLI**.  

Tu veux une solution plus spécifique selon ton use case ? 🚀