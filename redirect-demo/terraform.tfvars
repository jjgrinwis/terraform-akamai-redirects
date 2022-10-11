# property + edgehostname name basis
property_name = "redirects.pulumi.nl"

# simple map with just a key value pair
# a , or newline is enough to for each key value pair
hostname_redirect = {
  "testing.pulumi.nl" : "https://headers.grinwis.com"
  "testing3.pulumi.nl" : "https://headers.grinwis.com/nlannl"
}

# group to create resources in
group_name = "Ion Standard Beta Jam 1-3-16TWBVX"

# what user to inform when hostname has been created
email = "nobody@akamai.com"

# let's use FF network
domain_suffix = "edgesuite.net"

# edgeredirector policy name
policy_name = "grinwis_er_tf"
