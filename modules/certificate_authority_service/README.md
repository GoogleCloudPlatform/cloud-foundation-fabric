# Certificate Authority Service (CAS)

The module allows you to create one or more CAs and an optional CA pool.

## Examples

### Basic CA infrastructure

This is enough to create a test CA pool and a self-signed root CA.

```terraform
name       = "test-cas"
project_id = var.project_id
```

### Customize the location

By default, the location is `europe-west1`. You can anyway customize this with the `location` variable.

```terraform
name       = "test-cas"
project_id = var.project_id
location   = "us-east4"
```

### Create custom CAs

You can create multiple, custom CAs.

```terraform
name       = "test-cas"
project_id = var.project_id
ca_configs = {
	root_ca_1 = {
		key_spec_algorithm = "RSA_PKCS1_4096_SHA256"
		key_usage = {
			client_auth = true
			server_auth = true
		}
	}
	root_ca_2 = {
		subject = {
			common_name  = "test2.example.com"
			organization = "Example"
		}
	}
}
```

### Reference an existing CA pool

```terraform
name           = "test-cas"
project_id     = var.project_id
ca_pool_config = {
	ca_pool_id = var.ca_pool_id
}
```
