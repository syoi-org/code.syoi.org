# SYOI Code Server

code.syoi.org is a online coding IDE provided for current and past SYOI students. It provides a VS Code like text
editing interface and a terminal for running simple programs.

## Getting started

### Creating an account

The platform is free of charge for all current SYOI members. Please create a pull request (PR) adding a single line in
`users.csv`.

```csv
my_user_name,github_primary_email
```

Please wait your PR to be accepted. It will take a few days to create your account after your PR is accepted. You will
receive a PM from @STommydx after your account is ready to use.

### Connecting to server

Your code-server instance is available at `https://code.syoi.org/your-user-name`. You will need to login your GitHub
account for authentication.

## Technical Details

### Architecture

Each user has a unique `code-server` instance running as systemd service on a single virtual machine. The services are
tied to the corresponding UNIX account of the users for isolation. A reverse proxy is set up to direct ingress HTTP
traffic to the different `code-server` instances. The site is fronted by Cloudflare where Cloudflare tunnel establish a
connection from Cloudflare proxy to the HTTP reverse proxy in the server.

### Repository

This repository is a Terraform project that is responsible for setting up all resources need for the site. That would
include cloudflare records, ACL and virtual machines in hypervisor.
