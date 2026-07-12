# tf-ntnx-pc-deploy

## Overview

A Terraform/OpenTofu module for Day-1 Prism Central automation on Nutanix:
deploy a Prism Central VM onto a Prism Element cluster and register Prism
Element cluster(s) to it.

> **Provider endpoint:** this module connects to the **Prism Element (PE)
> cluster VIP**, not a Prism Central endpoint — Prism Central does not exist yet
> when it runs.

Additional Terraform Module documentation is available in the [module directory](module/README.md)
