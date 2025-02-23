Pour créer une instance EC2 avec une IP privée et permettre l'accès à son réseau local via un VPN depuis votre machine locale, vous pouvez utiliser Terraform pour provisionner les ressources nécessaires sur AWS. Voici un exemple de script Terraform qui réalise cela :

### 1. **Créer un VPC, un sous-réseau, et une passerelle Internet**

```hcl
provider "aws" {
  region = "us-west-2"  # Choisissez la région AWS de votre choix
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "my_subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my_route_table"
  }
}

resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}
```

### 2. **Créer une instance EC2 avec une IP privée**

```hcl
resource "aws_instance" "my_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Remplacez par l'AMI de votre choix
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet.id
  private_ip    = "10.0.1.10"  # IP privée de l'instance

  tags = {
    Name = "my_instance"
  }
}
```

### 3. **Créer un VPN Client pour accéder à l'instance EC2**

```hcl
resource "aws_ec2_client_vpn_endpoint" "my_vpn_endpoint" {
  description            = "Client VPN Endpoint"
  server_certificate_arn = aws_acm_certificate.my_cert.arn
  client_cidr_block      = "10.1.0.0/16"
  vpc_id                 = aws_vpc.my_vpc.id
  security_group_ids     = [aws_security_group.my_vpn_sg.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.my_cert.arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_acm_certificate" "my_cert" {
  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Name = "my_cert"
  }
}

resource "aws_security_group" "my_vpn_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_vpn_sg"
  }
}
```

### 4. **Configurer les autorisations et les routes VPN**

```hcl
resource "aws_ec2_client_vpn_network_association" "my_vpn_association" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my_vpn_endpoint.id
  subnet_id              = aws_subnet.my_subnet.id
}

resource "aws_ec2_client_vpn_authorization_rule" "my_vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my_vpn_endpoint.id
  target_network_cidr    = aws_vpc.my_vpc.cidr_block
  authorize_all_groups   = true
}
```

### 5. **Configurer le client VPN sur votre machine locale**

Une fois le VPN créé, vous devrez configurer le client VPN sur votre machine locale pour vous connecter au VPN AWS. Vous aurez besoin du fichier de configuration client généré par AWS, ainsi que des certificats nécessaires.

### 6. **Accéder à l'instance EC2 via le VPN**

Une fois connecté au VPN, vous pouvez accéder à l'instance EC2 via son IP privée (`10.0.1.10` dans cet exemple) depuis votre machine locale.

### 7. **Appliquer la configuration Terraform**

Pour appliquer cette configuration, exécutez les commandes suivantes :

```bash
terraform init
terraform apply
```

Cela va provisionner les ressources AWS nécessaires. Une fois terminé, vous pouvez vous connecter au VPN et accéder à votre instance EC2 via son IP privée.

### Remarques :
- **Certificats** : Vous devrez générer et gérer les certificats nécessaires pour le VPN. AWS ACM peut être utilisé pour cela.
- **Sécurité** : Assurez-vous de configurer correctement les groupes de sécurité et les règles d'accès pour sécuriser votre instance EC2 et votre VPN.
- **Coûts** : Les services AWS utilisés dans ce script peuvent engendrer des coûts. Assurez-vous de comprendre les tarifs avant de déployer cette infrastructure.

Ce script est un point de départ et peut nécessiter des ajustements en fonction de vos besoins spécifiques.

##
##
##

Voici un script Terraform qui :  
- Crée une instance EC2 avec une IP privée.  
- Met en place un VPN AWS (AWS Site-to-Site VPN) pour que ta machine locale puisse se connecter au réseau privé de l'instance.  
- Utilise AWS VPN Gateway et Customer Gateway pour établir la connexion VPN.  

**Prérequis** :  
- Une **Elastic IP** attachée à ton routeur VPN local (ou une IP publique fixe).  
- Des accès AWS avec les permissions nécessaires (IAM).  

### Ce que le script fait :
1. **VPC et Subnet** : Crée un VPC avec un sous-réseau privé.  
2. **Instance EC2** : Lance une instance avec une IP privée.  
3. **VPN Gateway & Customer Gateway** : Configure un VPN Site-to-Site entre AWS et ta machine locale.  
4. **Route Tables & Security Groups** : Configure les routes pour permettre l'accès à l'EC2 via le VPN.  

---

### **Script Terraform**
Crée un fichier `main.tf` avec ce contenu :  

```hcl
provider "aws" {
  region = "us-east-1" # Change selon ta région
}

# Création du VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Création du sous-réseau privé
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
}

# Security Group pour l'instance EC2 (autorise le trafic VPN)
resource "aws_security_group" "vpn_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Autorise le VPN
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Création de l'instance EC2 avec une IP privée
resource "aws_instance" "private_instance" {
  ami             = "ami-0c55b159cbfafe1f0" # Change selon ta région
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.vpn_sg.name]

  tags = {
    Name = "PrivateEC2"
  }
}

# Customer Gateway (ton routeur VPN local)
resource "aws_customer_gateway" "my_cgw" {
  bgp_asn    = 65000
  ip_address = "TON_IP_PUBLIQUE" # Remplace par l'IP publique de ton routeur VPN
  type       = "ipsec.1"
}

# VPN Gateway sur AWS
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.main.id
}

# Attache la VPN Gateway au VPC
resource "aws_vpn_gateway_attachment" "vpn_attach" {
  vpc_id        = aws_vpc.main.id
  vpn_gateway_id = aws_vpn_gateway.vgw.id
}

# Connexion VPN entre AWS et ton réseau local
resource "aws_vpn_connection" "vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.my_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true
}

# Route table pour rediriger le trafic du VPC vers le VPN
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "vpn_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "TON_RESEAU_LOCAL/24" # Ex: "192.168.1.0/24"
  gateway_id             = aws_vpn_gateway.vgw.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
```

---

### **Explication**
- L’instance EC2 est lancée **dans un sous-réseau privé**, donc pas d'IP publique.  
- Un VPN Site-to-Site est mis en place pour que ta machine locale accède au réseau AWS.  
- La route `TON_RESEAU_LOCAL/24` permet à ton LAN d'accéder à l'instance EC2.  
- La sécurité est gérée par les Security Groups et les routes VPN.  

---

### **Étapes suivantes**
1. **Modifier** `TON_IP_PUBLIQUE` par l’IP de ton routeur VPN.  
2. **Changer** `TON_RESEAU_LOCAL/24` par ton réseau privé (ex : `192.168.1.0/24`).  
3. **Exécuter Terraform** :
   ```sh
   terraform init
   terraform apply
   ```
4. **Configurer ton VPN** sur ton routeur local pour établir la connexion IPsec avec AWS.  
5. **Vérifier l'accès** à l'instance EC2 avec :  
   ```sh
   ssh -i ta_clé.pem ec2-user@10.0.1.X
   ```
