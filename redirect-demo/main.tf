# Terraform script to create some hostnames only to be used for some redirects
# A basic config using Secure By Default (SBD) certs and the Edge Redirector Cloudlet
# EdgeDNS used to create the CNAME records for the SBD DV certs.

terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
      # let's just the latest version of the TF provider
      #version = "1.9.1"
    }
  }
}

# for cloud usage these vars have been defined in terraform cloud as a set
# Configure the Akamai Terraform Provider to use betajam credentials
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "betajam"
}

# just use group_name to lookup our contract_id and group_id
# this will simplify our variables file as this contains contract and group id
# use "akamai property groups list" to find all your groups
data "akamai_contract" "contract" {
  group_name = var.group_name
}

locals {
  # using ION as our default product in case wrong product type has been provided as input var.
  # our failsave method just because we can. ;-)
  default_product = "prd_Fresca"

  # convert the list of maps to a map of maps with entry.hostname as key of the map
  # this map of maps will be fed into our EdgeDNS module to create the CNAME records.
  dv_records = { for entry in resource.akamai_property.aka_property.hostnames[*].cert_status[0]: entry.hostname => entry }
}

# create our dynamic redirect resource based on our var.hostnames_redirect var
# very simple redirect rules
data "akamai_cloudlets_edge_redirector_match_rule" "er_match_rules" {
  dynamic "match_rules" {
    for_each = var.hostname_redirect
    content {
      match_url                 = match_rules.key
      name                      = "${match_rules.key}_rule"
      redirect_url              = match_rules.value
      status_code               = 301
      use_incoming_query_string = false
      use_relative_url          = "none"
    }
  }
}

# this Edge Redirector policy was pre-created in Akamai Control Center.
# to retrieve active rules: 'akamai cloudlets retrieve --policy <policy_name>'
# we imported our existing policy using 'terraform import akamai_cloudlets_policy.edge_redirector grinwis_er'
# with 'terraform show' you can find exact layout of the redirect policy
resource "akamai_cloudlets_policy" "edge_redirector" {
  name          = var.policy_name
  cloudlet_code = "ER"
  description   = "Terraform managed ER policy"
  group_id      = data.akamai_contract.contract.group_id
  match_rules   = data.akamai_cloudlets_edge_redirector_match_rule.er_match_rules.json
}

# activate our cloudlet policy on staging just for test.
# we need to wait for our property to be available.
resource "akamai_cloudlets_policy_activation" "staging" {
  policy_id             = resource.akamai_cloudlets_policy.edge_redirector.id
  network               = "staging"
  version               = resource.akamai_cloudlets_policy.edge_redirector.version
  associated_properties = [resource.akamai_property.aka_property.name]
}

# as the config will be pretty static, let's not use a generic module.
# we're going to use all required rules in this tf file.
# create our edge hostname resource
resource "akamai_edge_hostname" "aka_edge" {
  # use our default value in case product is wrong.
  product_id  = lookup(var.aka_products, lower(var.product_name), local.default_product)
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  ip_behavior = var.ip_behavior

  # use the first item in your list to be used as the edgehostname and property name
  # this Akamai Edge Hostname will be used by all hostnames to simplify the setup
  edge_hostname = "${var.property_name}.${var.domain_suffix}"
}

resource "akamai_property" "aka_property" {
  name        = var.property_name
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  product_id  = lookup(var.aka_products, var.product_name, local.default_product)

  # create a dynamic hostnames resource block for our different hostnames
  # had some hard time to make this work but this was helpfull:
  # https://www.terraform.io/language/expressions/dynamic-blocks
  dynamic "hostnames" {
    for_each = var.hostname_redirect
    content {
      # a bit strange but using dynamic_var.key did the trick
      cname_from = hostnames.key
      cname_to   = resource.akamai_edge_hostname.aka_edge.edge_hostname

      # for this demo using secure by default
      cert_provisioning_type = "DEFAULT"
    }
  }

  # our pretty static rules file. Only dynamic part is the cloudlet id and name
  # we could use the akamai_template but trying standard templatefile() for a change.
  # it depends on a cloudlet id so that should be created first.
  # looks like we can only create non-shared policies via TF.
  rules = templatefile("akamai_config/config.tftpl", { cloudlet_id = resource.akamai_cloudlets_policy.edge_redirector.id, cloudlet_name = jsonencode(var.policy_name) })
}

# let's activate this property on staging
# staging will always use latest version but when useing on production a version number should be provided.
resource "akamai_property_activation" "aka_staging" {
  property_id = resource.akamai_property.aka_property.id
  contact     = [var.email]
  version     = resource.akamai_property.aka_property.latest_version
  network     = "STAGING"
  note        = "Action triggered by Terraform."
}

# if you your DNS provider has a Terraform module just use it here to create the CNAME records
# let's create our DV records using a module with with different credentials.
# Terraform has some limitations regarding using count and for_each with a module and separate provider configs
# Providers cannot be configured within modules using count, for_each or depends_on
# so just feeding our edgehostname create dv strings into our edgedns_cname module as a test for secure_by_default
module "edgedns_cname" {
  source = "../modules/services/edgedns_cname"
  
  # feed a list of hostnames, our key, into this module as our host list.
  hostnames = keys(var.hostname_redirect)

  # our secure by default converted dv_keys output, lets feed into our edgedns module
  dv_records = local.dv_records
}
