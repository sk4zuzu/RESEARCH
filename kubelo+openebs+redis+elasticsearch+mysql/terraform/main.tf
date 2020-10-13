locals {
  redis_values_yaml = <<-EOT
    usePassword: false
    cluster:
      enabled: false
    master:
      replicas: 1
      persistence:
        enabled: true
        storageClass: openebs-jiva-default
        size: 4Gi
      disableCommands: []
    slave:
      replicas: 0
      persistence:
        enabled: false
      disableCommands: []
    sentinel:
      enabled: false
    metrics:
      enabled: false
    volumePermissions:
      enabled: false
  EOT
  mysql_values_yaml = <<-EOT
    root:
      password: root
    db:
      user: kek
      password: kek
      name: kek
    master:
      replicas: 1
      persistence:
        enabled: true
        storageClass: openebs-jiva-default
        size: 4Gi
    slave:
      replicas: 0
    replication:
      enabled: false
    metrics:
      enabled: false
    volumePermissions:
      enabled: false
  EOT
  elasticsearch_values_yaml = <<-EOT
    master:
      replicas: 1
      persistence:
        enabled: true
        storageClass: openebs-jiva-default
        size: 4Gi
    data:
      replicas: 1
      persistence:
        enabled: true
        storageClass: openebs-jiva-default
        size: 4Gi
    ingest:
      enabled: false
    curator:
      enabled: false
    metrics:
      enabled: false
    sysctlImage:
      enabled: true
    volumePermissions:
      enabled: false
  EOT
}

terraform {
  backend "local" {}
}

resource "kubernetes_namespace" "openebs" {
  metadata {
    name = "openebs"
  }
}

resource "helm_release" "openebs" {
  depends_on = [ kubernetes_namespace.openebs ]
  name       = "openebs"
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  version    = "2.0.0"
  namespace  = "openebs"
}

resource "kubernetes_namespace" "db" {
  metadata {
    name = "db"
  }
}

resource "helm_release" "redis" {
  depends_on = [ kubernetes_namespace.db
               , helm_release.openebs ]
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "10.8.1"
  namespace  = "db"
  values     = [ local.redis_values_yaml ]
}

resource "helm_release" "mysql" {
  depends_on = [ kubernetes_namespace.db
               , helm_release.openebs ]
  name       = "mysql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = "6.14.8"
  namespace  = "db"
  values     = [ local.mysql_values_yaml ]
}

resource "helm_release" "elasticsearch" {
  depends_on = [ kubernetes_namespace.db
               , helm_release.openebs ]
  name       = "elasticsearch"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "elasticsearch"
  version    = "12.6.3"
  namespace  = "db"
  values     = [ local.elasticsearch_values_yaml ]
}
