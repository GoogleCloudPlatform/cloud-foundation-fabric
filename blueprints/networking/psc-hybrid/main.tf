/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Producer

module "vpc_producer" {
  source     = "../../../modules/net-vpc"
  project_id = var.project_id
  name       = "${var.prefix}-producer"
  subnets = [
    {
      ip_cidr_range      = var.producer["subnet_main"]
      name               = "${var.prefix}-main"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = var.producer["subnet_proxy"]
      name          = "${var.prefix}-proxy"
      region        = var.region
      active        = true
    }
  ]
  subnets_psc = [
    {
      ip_cidr_range = var.producer["subnet_psc"]
      name          = "${var.prefix}-psc"
      region        = var.region
    }
  ]
}

module "psc_producer" {
  source          = "./psc-producer"
  project_id      = var.project_id
  name            = var.prefix
  dest_ip_address = var.dest_ip_address
  dest_port       = var.dest_port
  network         = module.vpc_producer.network.id
  region          = var.region
  zone            = var.zone
  subnet          = module.vpc_producer.subnets["${var.region}/${var.prefix}-main"].id
  subnet_proxy    = module.vpc_producer.subnets_proxy_only["${var.region}/${var.prefix}-proxy"].id
  subnets_psc = [
    module.vpc_producer.subnets_psc["${var.region}/${var.prefix}-psc"].id
  ]
  accepted_limits = var.producer["accepted_limits"]
}

# Consumer

module "vpc_consumer" {
  source     = "../../../modules/net-vpc"
  project_id = var.project_id
  name       = "${var.prefix}-consumer"
  subnets = [
    {
      ip_cidr_range      = var.subnet_consumer
      name               = "${var.prefix}-consumer"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "psc_consumer" {
  source     = "./psc-consumer"
  project_id = var.project_id
  name       = "${var.prefix}-consumer"
  region     = var.region
  network    = module.vpc_consumer.network.id
  subnet     = module.vpc_consumer.subnets["${var.region}/${var.prefix}-consumer"].id
  sa_id      = module.psc_producer.service_attachment.id
}
