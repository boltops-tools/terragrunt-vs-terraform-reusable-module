## Overview

These example projects explain how terragrunt and terraform/terraspace handle creating reusable modules differently. It provides the necessary context to answer this community post:

* [Migrating from terragrunt - Root modules?](https://community.boltops.com/t/migrating-from-terragrunt-root-modules/627)

This may also helps folks migrating from terragrunt to terraspace and using the same original state files.

Though a greenfield terraspace project is a lot cleaner, it's not always possible.
You may also want to consider migrating by copy each module's state file being migrated. This allows you to get rid of legacy artifacts. However, this approach is sometimes not possible.

## Files Summary

Here's a summary of the files in this repo. Please read the **entire** README and come back to this to be most useful.

Name | Description | Terraform Resource Name
---|---|---
[terragrunt-project/dev/demo](terragrunt-project/dev/demo) | The "dev demo" terragrunt project that creates a random pet. Terragrunt creates "flattened" resource names. The key file in this folder is [terragrunt.hcl](terragrunt-project/dev/demo/terragrunt.hcl). | random_pet.pet1
[terraspace-project/app/stacks/demo](terraspace-project/app/stacks/demo) | The "demo" terraspace stack that creates a random pet using the `module` keyword. Since this project uses the terraform `module` keyword it'll create a hierarchical resource name. The key file in this folder is [main.tf](terraspace-project/app/stacks/demo/main.tf). | module.pet1.random_pet.pet
[terraspace-project-flat/app/stacks/demo](terraspace-project-flat/app/stacks/demo) | The "demo" terraspace stack creates a random pet directly. This creates the same "flattened" terragrunt resource name structure. And is the key to allowing you to use the **same statefiles**.  The key file in this folder is [main.tf](terraspace-project-flat/app/stacks/demo/main.tf).  | random_pet.pet1

Notes:

* Both terraspace project examples, make use of Terrafile to source in the modules.
* You can use the `module source` field if you're using `terraform module` keyword to reuse modules.
* But for the flattened structure that creates a "flattened" resource name like Terragrunt, you have to use Terrafile to reuse module code.

## Reusing Modules with Terragrunt vs Terraform Looks the Same

To reuse terraform modules, Terragrunt uses a custom HCL syntax with the `terraform` keyword:

dev/demo/terragrunt.hcl

```terraform
terraform {
  source = "git::https://github.com/tongueroo/pet.git"
}
```

Terraform/terraspace uses the `module` keyword that looks very similar:

```terraform
module "example" {
  source = "github.com/hashicorp/example"
}
```

## But Reusing Modules with Terragrunt vs Terraform Creates Very Different Resource Name Structures

Though the terragrunt custom `terraform` keyword and terraform native `module` keyword code look very similar, they behave quite differently.

* The terragrunt `terraform` keyword sources the module in a flattened manner.
* Whereas the terraform `module` keyword adds another hierarchical namespace to the created resource.

## Resource Name Structure: Terragrunt Flattened

The terragrunt `terraform` keyword creates a flattened resource name structure. For example, given these files:

dev/demo/terragrunt.hcl

```terraform
terraform {
  source = "git::https://github.com/tongueroo/pet.git"
}
```

dev/demo/main.tf

```terraform
resource "random_pet" "pet1" {
  length = 2
}
```

Running:

    $ terragrunt apply
    ...
    # random_pet.pet1 will be created
    ...

The key is to notice that the resource name is:

    random_pet.pet1

<details>
 <summary>Click to see full output</summary>

    $ terragrunt apply

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # random_pet.pet1 will be created
      + resource "random_pet" "pet1" {
          + id        = (known after apply)
          + length    = 2
          + separator = "-"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value: yes

    random_pet.pet1: Creating...
    random_pet.pet1: Creation complete after 0s [id=exciting-kit]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    $
</details>

So terragrunt downloads the reusable module code from `https://github.com/tongueroo/pet.git` as if you had written the source code in the same `dev/demo/main.tf` file. It's "flattened".

## Resource Name Structure: Terraform Hierarchical

The terraform/terraspace module keyword creates a hierarchical resource name structure. For example, given these files:

app/modules/demo/main.tf

```terraform
module "pet1" {
  source     = "../../modules/pet"
}
```

vendor/modules/pet/main.tf

```terraform
resource "random_pet" "pet" {
  length = 2
}
```

Terrafile

```ruby
mod "pet", source: "git@github.com:tongueroo/pet"
```

Running

    $ terraspace bundle   # to build vendor/modules/pet
    $ terraspace up demo
    ...
    # module.pet1.random_pet.pet will be created
    ...

The key is to notice that the resource name is:

    module.pet1.random_pet.pet will be created

<details>
 <summary>Click to see full output</summary>

    $ terraspace up demo
    Building .terraspace-cache/us-west-2/dev/stacks/demo
    Built in .terraspace-cache/us-west-2/dev/stacks/demo
    Current directory: .terraspace-cache/us-west-2/dev/stacks/demo
    => terraform apply -input=false

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # module.pet1.random_pet.pet will be created
      + resource "random_pet" "pet" {
          + id        = (known after apply)
          + length    = 2
          + separator = "-"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
      Enter a value: yes

    module.pet1.random_pet.pet: Creating...
    module.pet1.random_pet.pet: Creation complete after 0s [id=useful-stingray]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    Time took: 1m 4s
    $
</details>

Produces this resource name: `module.pet1.random_pet.pet`

## Resource Name Structure: Terraform "Flattened"

It is key to understand that `terraform module` keyword will create a hierarchical resource name no matter what. So if you want to produce the same "flattened" resource name structure like terragrunt, do not use the module keyword. Examples:

app/stacks/demo/main.tf

```terraform
resource "random_pet" "pet" {
  length = 2
}
```

Terrafile

```ruby
mod "demo", source: "git@github.com:tongueroo/pet", export_to: "app/stacks"
```

seed/tfvars/stacks/demo/dev.tfvars

    length = 1

Running

    $ terraspace up demo
    ...
    # random_pet.pet1 will be created
    ...

The key is to notice that the resource name is:

    random_pet.pet1

This is the **same** flattened structure that the terragrunt `terraform` customized keyword produces: `random_pet.pet1`

<details>
 <summary>Click to see full output</summary>

    $ terraspace up demo
    Building .terraspace-cache/us-west-2/dev/stacks/demo
    Built in .terraspace-cache/us-west-2/dev/stacks/demo
    Current directory: .terraspace-cache/us-west-2/dev/stacks/demo
    => terraform apply -input=false

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # random_pet.pet1 will be created
      + resource "random_pet" "pet1" {
          + id        = (known after apply)
          + length    = 1
          + separator = "-"
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
      Enter a value: yes

    random_pet.pet1: Creating...
    random_pet.pet1: Creation complete after 0s [id=hermit]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    Time took: 4s
    $
</details>

This demonstrates that the mirrored tfvars structure is also possible with Terraspace. We're using seed here that jives more with the way Terragrunt works. Think it's clearer to put the tfvars files `app/modules/demo/tfvars` though. However, you have options.

## Concluding Thoughts: Pros and Cons

The devil is in the details, we have to go pretty deep into the weeds to see the differences here.

* The advantage with Terragrunt's custom HCL syntax is that it produces a nice flattened resource name structure. This is nicer because it's "simpler". You don't have to "daisy-chain" variable inputs as much.
* The advantage of terraform's `module` keyword is that it's native. It's already built-in. The native module syntax also creates a hierarchical resource name. This nicer because it's more "organized".

Think that sometimes a custom syntax is worth it, it depends on the value add. DSLs are worth it when they provide enough pros. Now that the terraform `module` keyword is available though, think it's no longer worth it. The terragrunt custom HCL syntax conflates things.
