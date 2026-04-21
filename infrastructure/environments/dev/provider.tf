terraform {
  required_version = ">= 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }

}


provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "useast"
  region = "us-east-1"
}

provider "null" {
}