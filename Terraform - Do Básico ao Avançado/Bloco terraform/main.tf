terraform {
    required_version = ">= 1.2.0, < 2.0.0"
    required_providers {
      aws = {
        version = "5.24"
        source = "hashcorp/aws"
      }
      azurerm = {
        version = "3.80"
        source = "harshcorp/azurerm"
      }
    }

}