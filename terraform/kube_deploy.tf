terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  config_path = "./.kube/config"
}

resource "kubernetes_namespace" "rhombus-ns" {
  metadata {
    name = "rhombus-ns"
  }
}

resource "kubernetes_deployment" "rhombus-deploy" {
  metadata {
    name      = "rhombus"
    namespace = kubernetes_namespace.rhombus-ns.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "rhombus"
      }
    }
    template {
      metadata {
        labels = {
          app = "rhombus"
        }
      }
      spec {
        container {
          image = "dgofman/rhombus:master"
          name  = "rhombus-website"
          port {
            container_port = 80
          }
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service" "rhombus-svc" {
  metadata {
    name      = "rhombus-svc"
    namespace = kubernetes_namespace.rhombus-ns.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.rhombus-deploy.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
    }
  }
  wait_for_load_balancer = true
}

output "URL" {
  value = "http://${kubernetes_service.rhombus-svc.status.0.load_balancer.0.ingress.0.hostname}"
}