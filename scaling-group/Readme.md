Pour tester la montée en charge (scaling) de votre infrastructure AWS avec Auto Scaling, vous pouvez utiliser un outil comme **Apache Benchmark (`ab`)**. `ab` est un outil en ligne de commande qui permet de simuler une charge sur un serveur web en envoyant un grand nombre de requêtes HTTP.

Voici comment vous pouvez utiliser `ab` pour tester la montée en charge de vos instances EC2 dans un groupe Auto Scaling.

---

### 1. Prérequis

- **Installer Apache Benchmark** : Si vous ne l'avez pas déjà, installez `ab` sur votre machine locale.
  - Sur Ubuntu/Debian :
    ```bash
    sudo apt install apache2-utils
    ```
  - Sur CentOS/RHEL :
    ```bash
    sudo yum install httpd-tools
    ```

- **Récupérer l'URL de votre application** : Assurez-vous d'avoir l'URL publique de votre application WordPress (par exemple, l'IP publique ou le DNS d'une des instances EC2).

---

### 2. Tester la montée en charge avec `ab`

Voici un exemple de commande `ab` pour simuler une charge sur votre serveur :

```bash
ab -n 10000 -c 100 http://<votre-ip-publique>/
```

#### Explication des paramètres :
- **`-n 10000`** : Envoie 10 000 requêtes au total.
- **`-c 100`** : Simule 100 utilisateurs concurrents.
- **`http://<votre-ip-publique>/`** : Remplacez `<votre-ip-publique>` par l'IP publique de votre instance EC2 ou l'URL de votre application.

---

### 3. Observer le comportement de l'Auto Scaling Group

Pendant que `ab` envoie des requêtes, surveillez le comportement de votre groupe Auto Scaling dans la console AWS ou via Terraform.

#### Dans la console AWS :
1. Allez dans **EC2 > Auto Scaling Groups**.
2. Sélectionnez votre groupe Auto Scaling.
3. Observez le nombre d'instances en cours d'exécution. Si la charge augmente, l'Auto Scaling Group devrait lancer de nouvelles instances pour gérer la demande.

#### Avec Terraform :
Vous pouvez vérifier l'état des ressources avec la commande suivante :
```bash
terraform refresh
terraform output
```

---

### 4. Configurer des politiques de scaling (optionnel)

Pour que l'Auto Scaling Group réagisse automatiquement à la charge, vous pouvez ajouter des **politiques de scaling** basées sur des métriques CloudWatch (comme l'utilisation du CPU).

#### Exemple de politique de scaling avec Terraform :

```hcl
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "high-cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 70  # Seuil d'utilisation du CPU à 70%
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
```

#### Explication :
- **`aws_autoscaling_policy`** : Définit une politique pour ajouter une instance si la charge augmente.
- **`aws_cloudwatch_metric_alarm`** : Déclenche la politique de scaling si l'utilisation du CPU dépasse 70% pendant deux périodes de 120 secondes.

---

### 5. Analyser les résultats

Une fois le test terminé, `ab` affichera un rapport avec des statistiques telles que :
- **Requests per second** : Nombre de requêtes traitées par seconde.
- **Time per request** : Temps moyen pour traiter une requête.
- **Failed requests** : Nombre de requêtes ayant échoué.

Exemple de sortie :
```
Concurrency Level:      100
Time taken for tests:   10.123 seconds
Complete requests:      10000
Failed requests:        0
Requests per second:    987.65 [#/sec] (mean)
Time per request:       101.230 [ms] (mean)
```

---

### 6. Nettoyer les ressources

Après le test, n'oubliez pas de détruire les ressources pour éviter des coûts inutiles :

```bash
terraform destroy
```

---

### Conclusion

En utilisant `ab`, vous pouvez simuler une charge sur votre application WordPress et observer comment votre groupe Auto Scaling réagit. Si vous avez configuré des politiques de scaling, de nouvelles instances devraient être lancées automatiquement pour gérer la charge accrue. Cela vous permet de valider que votre infrastructure est capable de monter en charge de manière dynamique.


Pour que le **Load Balancer** fonctionne correctement avec l'**Auto Scaling Group**, il est essentiel de configurer les paramètres de manière cohérente et optimale. Les conflits entre les **timeouts**, **intervals**, et **thresholds** peuvent entraîner des problèmes de santé des instances, des mises à l'échelle inappropriées, ou des temps d'indisponibilité. Voici les meilleures pratiques pour configurer ces paramètres.

---

### 1. **Health Check du Target Group**

Le **Health Check** du Target Group est utilisé par le Load Balancer pour déterminer si une instance est saine et peut recevoir du trafic. Voici les paramètres recommandés :

#### Paramètres recommandés :
- **Path** : `/` (ou un endpoint spécifique dédié au health check, comme `/health`).
- **Protocol** : `HTTP` (ou `HTTPS` si votre application utilise SSL).
- **Port** : `traffic-port` (utilise le même port que celui configuré pour le Target Group).
- **Healthy threshold** : `3` (nombre de checks réussis pour considérer une instance comme saine).
- **Unhealthy threshold** : `3` (nombre de checks échoués pour considérer une instance comme défaillante).
- **Timeout** : `5` secondes (temps d'attente pour la réponse du health check).
- **Interval** : `30` secondes (intervalle entre les checks).
- **Success code** : `200` (code HTTP attendu pour un health check réussi).

#### Exemple de configuration Terraform :

```hcl
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}
```

---

### 2. **Politiques de Scaling de l'Auto Scaling Group**

Les politiques de scaling déterminent quand et comment l'Auto Scaling Group doit ajouter ou supprimer des instances. Voici les paramètres recommandés :

#### Paramètres recommandés :
- **Metric** : Utilisez `CPUUtilization` ou `RequestCountPerTarget` (selon votre application).
- **Target value** : Par exemple, `70` pour `CPUUtilization` (ajuste la capacité pour maintenir une utilisation moyenne du CPU à 70%).
- **Scale-out cooldown** : `300` secondes (5 minutes) pour éviter des mises à l'échelle trop fréquentes.
- **Scale-in cooldown** : `300` secondes (5 minutes) pour éviter des réductions de capacité trop fréquentes.

#### Exemple de politique de scaling Terraform :

```hcl
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "high-cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 70
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name                = "low-cpu"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 30
  alarm_actions             = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}
```

---

### 3. **Cooldown Period**

Le **cooldown period** est le temps d'attente après une action de scaling avant qu'une autre action ne soit déclenchée. Cela évite des fluctuations trop rapides dans le nombre d'instances.

#### Recommandations :
- **Scale-out cooldown** : `300` secondes (5 minutes).
- **Scale-in cooldown** : `300` secondes (5 minutes).

---

### 4. **Health Check Grace Period**

Le **Health Check Grace Period** est le temps d'attente après le lancement d'une nouvelle instance avant que le health check ne commence. Cela permet à l'application de démarrer complètement.

#### Recommandation :
- **Health Check Grace Period** : `300` secondes (5 minutes).

#### Exemple de configuration Terraform :

```hcl
resource "aws_autoscaling_group" "web" {
  name_prefix          = "web-asg-"
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  health_check_type   = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }
}
```

---

### 5. **Synchronisation des Timeouts et Intervals**

Assurez-vous que les **timeouts** et **intervals** du health check du Target Group sont cohérents avec les autres paramètres :

- **Health Check Timeout** : Doit être inférieur à l'**interval**.
- **Health Check Interval** : Doit être suffisamment long pour permettre à l'application de répondre, mais pas trop long pour détecter rapidement les défaillances.
- **Cooldown Period** : Doit être supérieur à l'intervalle du health check pour éviter des actions de scaling trop fréquentes.

#### Exemple de synchronisation :
- Health Check Timeout : `5` secondes.
- Health Check Interval : `30` secondes.
- Cooldown Period : `300` secondes.

---

### 6. **Utilisation de métriques personnalisées (optionnel)**

Si les métriques par défaut (comme `CPUUtilization`) ne suffisent pas, vous pouvez utiliser des métriques personnalisées pour déclencher le scaling. Par exemple, vous pouvez surveiller le nombre de requêtes par seconde (`RequestCountPerTarget`) ou la latence.

#### Exemple de métrique personnalisée :

```hcl
resource "aws_cloudwatch_metric_alarm" "high_requests" {
  alarm_name                = "high-requests"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "RequestCountPerTarget"
  namespace                 = "AWS/ApplicationELB"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 1000  # 1000 requêtes par seconde par instance
  alarm_actions             = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.web.arn_suffix
    LoadBalancer = aws_lb.web.arn_suffix
  }
}
```

---

### 7. **Résumé des meilleures pratiques**

1. **Health Check du Target Group** :
   - Path : `/` ou `/health`.
   - Interval : `30` secondes.
   - Timeout : `5` secondes.
   - Healthy/Unhealthy Threshold : `3`.

2. **Politiques de Scaling** :
   - Cooldown : `300` secondes.
   - Metric : `CPUUtilization` ou `RequestCountPerTarget`.
   - Target Value : `70` pour `CPUUtilization`.

3. **Health Check Grace Period** : `300` secondes.

4. **Synchronisation des Timeouts et Intervals** :
   - Health Check Timeout < Health Check Interval < Cooldown Period.

5. **Surveillance** : Utilisez CloudWatch pour surveiller les métriques et ajuster les seuils si nécessaire.

En suivant ces bonnes pratiques, vous éviterez les conflits entre les paramètres et assurerez un fonctionnement optimal du Load Balancer et de l'Auto Scaling Group.