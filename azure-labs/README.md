Both IaC implementations (Bicep and Terraform) deploy the same architecture so you can compare syntax, structure, and design approaches across tools.

---

## Labs Overview

### **01 – Resource Group & Basics**
Foundational deployment demonstrating:
- Resource groups  
- Basic parameter usage  
- Deployment structure  
- Bicep/Terraform parity  

Useful as a warm‑up before more complex labs.

---

### **02 – Networking Foundations**
Builds a secure virtual network layout:
- Virtual networks  
- Subnets  
- Network security groups  
- IP addressing conventions  
- Separation of hub and workload segments  

Forms the base for later labs that require private networking.

---

### **03 – Storage & SAS Security**
Demonstrates secure storage account patterns:
- Private storage account  
- Private endpoint integration  
- Blob container access control  
- SAS token generation (service SAS)  
- Network isolation and validation steps  

Shows how to safely expose storage resources without public access.

---

### **04 – VMSS Autoscaling**
Deploys a load‑balanced Virtual Machine Scale Set:
- VMSS (Ubuntu 22.04)  
- Azure Load Balancer (Standard SKU)  
- Health probe + LB rule  
- Autoscale rules based on CPU  
- Secure VNet integration  

Illustrates how to build scalable compute patterns using native autoscaling.

---

## Repository Goals

This repository is designed to help you:

- Understand Azure resource architecture through small, focused labs  
- Compare **Bicep** and **Terraform** implementations side‑by‑side  
- Build repeatable infrastructure patterns suitable for production  
- Learn secure defaults and modern Azure best practices  
- Develop IaC fluency across multiple tools  

Each lab is intentionally minimal but realistic, avoiding unnecessary complexity while still demonstrating correct Azure patterns.

---

## Conventions

### **Naming**
Resources follow deterministic naming patterns to avoid collisions and ensure readability.

### **Security**
All labs follow secure defaults:
- HTTPS‑only  
- TLS 1.2+  
- Private networking where appropriate  
- No public access unless explicitly required 

---

## Prerequisites

- Azure CLI  
- Terraform (latest stable)  
- Azure subscription  
- Basic familiarity with IaC concepts  

## Future Labs (Planned)

- Application Gateway + WAF  
- AKS cluster with node pools  
- Key Vault + Managed Identity  
- Private DNS Zones  
- Event Hub + Consumer Group  
- Log Analytics + Diagnostics  

---

## Notes

This repository is designed for learning, experimentation, and demonstrating Azure infrastructure competency. It intentionally avoids unnecessary abstraction or module complexity so you can focus on understanding the underlying Azure resources.
