# terraform-akamai-redirects
A little Terraform project to create a very simple akamai config to do some redirects using Edge Redirector Cloudlet.

This will create a single Akamai Delivery configuration with a very simple config. Redirects are taking care off by the Edge Redirector Cloudlet.
Terraform script will automatically request Secure By Default certs and in this example using EdgeDNS to automatically create some CNAME records.

When testing this make sure to add your own CPcode in the config. We will add that as a variable in some later version.
