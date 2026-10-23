# Azure Lighthouse Demo Repository

Complete hands-on guide and automation for setting up cross-tenant management with Azure Lighthouse. This repository contains everything needed to demo and deploy Azure Lighthouse between two Azure tenants.

## 📋 What's Included

- **ARM Templates** - Ready-to-use delegation templates
- **PowerShell Scripts** - Automation for setup and validation
- **Configuration Examples** - Common scenarios (policy, Defender, cost management)
- **Documentation** - Step-by-step guides and architectural patterns

## 🚀 Quick Start

### For Service Providers (Managing Tenant)

1. Review the [Setup Guide](docs/SETUP.md)
2. Customize [delegationTemplate.json](templates/delegationTemplate.json) with your tenant/principal IDs
3. Provide template to customer

### For Customers (Customer Tenant)

1. Register resource provider
2. Deploy the template provided by service provider
3. Verify delegation

See [Quick Start Guide](docs/QUICK_START.md) for detailed steps.

## 📂 Repository Structure

```
azure-lighthouse-demo/
├── README.md                          # This file - navigation hub
├── .gitignore                         # Git ignore rules
├── docs/
│   ├── QUICK_START.md                # Get running in 5 minutes
│   ├── SETUP.md                      # Complete 16-step guide (all phases)
│   ├── AUTO_DELEGATION_POLICY.md     # Auto-delegate subscriptions with Azure Policy
│   ├── MANAGING_TENANT_OPERATIONS.md # 6 operational domains with implementations
│   ├── TROUBLESHOOTING.md            # Common issues & solutions
│   └── ARCHITECTURE.md               # Technical deep-dive (coming soon)
├── templates/
│   ├── delegationTemplate.json       # Main ARM template for delegation
│   ├── delegationTemplate.parameters.json
│   └── README.md                     # Customization & role reference guide
├── scripts/
│   ├── setup-managing-tenant.ps1     # Gather principal IDs from managing tenant
│   ├── setup-customer-tenant.ps1     # Register resource provider on customer
│   ├── verify-delegation.ps1         # Test delegation is working
│   ├── remove-delegation.ps1         # Safely remove delegation (coming soon)
│   └── README.md                     # Script usage guide & troubleshooting
├── examples/
│   ├── policy-enforcement/
│   │   └── README.md                 # Policy deployment & remediation
│   ├── security-operations/
│   │   └── README.md                 # Defender & Sentinel setup (coming soon)
│   ├── cost-management/
│   │   └── README.md                 # Cost analysis (coming soon)
│   ├── resource-graph-queries/
│   │   ├── README.md                 # 20 Resource Graph (KQL) queries for tag-based discovery
│   │   └── query-helper-functions.ps1 # PowerShell helper functions
│   └── fabric-gateway/
│       └── README.md                 # Fabric + Gateway (coming soon)
├── demo-playbooks/
│   ├── 5-minute-demo.md             # Quick demo walkthrough script
│   ├── 30-minute-demo.md            # Detailed demo (coming soon)
│   ├── 60-minute-demo.md            # Full customer presentation (coming soon)
│   └── customer-presentation.md     # Presentation outline (coming soon)
└── images/                           # Diagrams & screenshots (coming soon)
```

## 🎯 Common Scenarios

### Scenario 1: Basic Delegation (5 min)
- Deploy template
- Verify access
- See customer resources

**Guide:** [Quick Start](docs/QUICK_START.md)

### Scenario 2: Policy Enforcement (15 min)
- Deploy policies to customer subscriptions
- Show policy compliance
- Remediate non-compliant resources

**Guide:** [Policy Examples](examples/policy-enforcement/)

### Scenario 3: Security Operations (20 min)
- Enable Defender for Cloud centrally
- Consolidate Sentinel incidents
- Show unified security dashboard


### Scenario 4: Cost Management (10 min)
- Query costs across customers
- Show billing aggregation
- Set up budgets and alerts

**Guide:** [Cost Management](examples/cost-management/)

### Scenario 5: Infrastructure Discovery (15 min)
- Query resources with Resource Graph
- Generate IaC with GitHub Copilot
- Deploy standardized infrastructure

**Guide:** [Resource Graph Queries](examples/resource-graph-queries/)

## 🔑 Key Features

✅ **No Marketplace Offer Required** - Uses ARM templates for instant deployment  
✅ **Fully Automated** - PowerShell scripts handle setup and validation  
✅ **Production Ready** - Based on Microsoft best practices  
✅ **Multi-Tenant Support** - Manage multiple customer subscriptions  
✅ **Comprehensive Documentation** - Every step explained  
✅ **Demo Ready** - Pre-built scenarios for customer presentations  

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP.md](docs/SETUP.md) | Complete 16-step setup guide |
| [QUICK_START.md](docs/QUICK_START.md) | Get running in 5 minutes |
| [MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md) | 6 use-cases for managing tenant |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues & solutions |

## 🛠️ Scripts

All scripts include error handling and verbose logging.

```powershell
# Setup managing tenant (list users, groups, service principals)
.\scripts\setup-managing-tenant.ps1 -TenantId "<TENANT_A_ID>"

# Setup customer tenant (register resource provider)
.\scripts\setup-customer-tenant.ps1 -TenantId "<TENANT_B_ID>" -SubscriptionId "<SUB_ID>"

# Verify delegation is working
.\scripts\verify-delegation.ps1 -SubscriptionId "<CUSTOMER_SUB_ID>"

# Remove delegation cleanly
.\scripts\remove-delegation.ps1 -SubscriptionId "<CUSTOMER_SUB_ID>"
```

## 📋 Prerequisites

- Two Azure subscriptions (one for each tenant)
- Azure CLI or PowerShell 7.0+
- Owner/Global Admin access to both tenants
- Git (optional, for cloning repo)

## 🚦 Roles Required

| Operation | Required Role | Role ID |
|-----------|--------------|---------|
| Create delegation | - | - |
| Policy enforcement | Resource Policy Contributor | `36243c78-bf99-498c-9df9-86d9f8d28608` |
| Defender/Sentinel | Contributor | `b24988ac-6180-42a0-ab88-20f7382dd24c` |
| Remove delegation | Managed Services Reg. Assignment Delete | `91c1777a-f3dc-4fae-b103-61d183457e46` |

## 📊 Demo Scenarios

### 5-Minute Demo
1. Create delegation via template
2. Show customer subscription in managing tenant
3. List resources in customer subscription

### 30-Minute Demo
1. Setup & verify delegation (10 min)
2. Deploy policy and show enforcement (8 min)
3. Query resources with Resource Graph (7 min)
4. Show cost aggregation (5 min)

### Full Customer Presentation (60 min)
1. Architecture walkthrough (10 min)
2. Live delegation demo (15 min)
3. Policy enforcement (10 min)
4. Security operations - Defender/Sentinel (15 min)
5. Cost management & optimization (10 min)

See [Demo Playbooks](demo-playbooks/) for detailed scripts.

## 🔐 Security Best Practices

✅ Use **Security groups** instead of individual users  
✅ Apply **least privilege principle** - only assign needed roles  
✅ Include **Managed Services Registration Assignment Delete Role** for cleanup  
✅ **Never commit secrets** to the repo (use Azure Key Vault)  
✅ Use **service principals** for automation  
✅ **Audit all delegations** regularly  

## ⚠️ Limitations to Know

- ❌ Management groups cannot be delegated directly (use Azure Policy workaround)
- ❌ Owner role is not supported for delegations
- ❌ Cannot view policy compliance details in customer tenant
- ❌ Data plane access (e.g., Key Vault secrets, storage data) not supported
- ✅ **Workarounds provided** for all limitations

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for details.

## 🤝 Contributing

Found an issue or want to add a scenario? 

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-scenario`)
3. Commit changes (`git commit -m 'Add scenario'`)
4. Push to branch (`git push origin feature/new-scenario`)
5. Open a Pull Request

## 📚 Additional Resources

- [Microsoft Learn - Azure Lighthouse](https://learn.microsoft.com/azure/lighthouse/)
- [Azure Lighthouse Samples](https://github.com/Azure/Azure-Lighthouse-samples)
- [Microsoft Docs - Tenants, Users, and Roles](https://learn.microsoft.com/azure/lighthouse/concepts/tenants-users-roles)
- [Azure Lighthouse Limitations](https://learn.microsoft.com/azure/lighthouse/concepts/cross-tenant-management-experience#current-limitations)

## 📝 License

This repository is provided as-is for demonstration purposes. Adapt freely for your needs.

## 🆘 Support

For issues with:
- **Azure Lighthouse concepts** - See [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Deployment errors** - See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Script issues** - Check [scripts/README.md](scripts/README.md)
- **Examples/scenarios** - See specific example READMEs

## 📞 Getting Help

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [Microsoft Learn docs](https://learn.microsoft.com/azure/lighthouse/)
3. Search existing [GitHub issues](../../issues)
4. Open a [new issue](../../issues/new) with details

---

**Ready to get started?** → [Quick Start Guide](docs/QUICK_START.md)

**Want full details?** → [Complete Setup Guide](docs/SETUP.md)

**Running a demo?** → [Demo Playbooks](demo-playbooks/)
