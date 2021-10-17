terraform {
  backend "gcs" {
    bucket = "iskprinter-tf-state-prod"
    prefix = "application"
  }
}

provider "kubernetes" {}

module "secrets" {
  source                             = "./modules/secrets"
  api_client_credentials_secret_name = var.api_client_credentials_secret_name
  api_client_id                      = var.api_client_id
  api_client_secret_base64           = var.api_client_secret_base64
  mongodb_connection_secret_name     = var.mongodb_connection_secret_name
  mongodb_connection_url_base64      = var.mongodb_connection_url_base64
  namespace                          = var.namespace
}

module "api" {
  source                                   = "./modules/api"
  api_client_credentials_secret_key_id     = module.secrets.api_client_credentials_secret_key_id
  api_client_credentials_secret_key_secret = module.secrets.api_client_credentials_secret_key_secret
  api_client_credentials_secret_name       = module.secrets.api_client_credentials_secret_name
  image                                    = var.image_api
  mongodb_connection_secret_key_url        = module.secrets.mongodb_connection_secret_key_url
  mongodb_connection_secret_name           = module.secrets.mongodb_connection_secret_name
  namespace                                = var.namespace
}

module "frontend" {
  source         = "./modules/frontend"
  namespace      = var.namespace
  image          = var.image_frontend
}

module "ingress" {
  source                       = "./modules/ingress"
  api_service_name             = module.api.service_name
  api_service_port             = module.api.service_port
  frontend_service_name        = module.frontend.service_name
  frontend_service_port        = module.frontend.service_port
  gcp_project                  = var.gcp_project
  google_dns_managed_zone_name = var.google_dns_managed_zone_name
  namespace                    = var.namespace
}

module "weekly_download" {
  source                            = "./modules/weekly_download"
  image                             = var.image_weekly_download
  namespace                         = var.namespace
  mongodb_connection_secret_name    = module.secrets.mongodb_connection_secret_name
  mongodb_connection_secret_key_url = module.secrets.mongodb_connection_secret_key_url
}
