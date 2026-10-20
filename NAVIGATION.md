# Quick Navigation Guide

Use this page to quickly find what you need.

## 🎯 I Want To...

### 🚀 Get Started Fast (5-30 minutes)
- **See it working in 5 minutes:** [5-minute-demo.md](demo-playbooks/5-minute-demo.md)
- **Minimal quick start:** [QUICK_START.md](docs/QUICK_START.md)
- **Understand the basics:** [README.md](README.md)

### 📖 Learn & Implement (2-4 hours)
- **Complete setup guide:** [SETUP.md](docs/SETUP.md) ← Start here for full implementation
- **Customize my template:** [templates/README.md](templates/README.md)
- **Use PowerShell scripts:** [scripts/README.md](scripts/README.md)

### 🔧 Operate Lighthouse
- **Learn all 6 operational domains:** [MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md)
  - Policy enforcement
  - Defender & Sentinel
  - Resource Graph for IaC
  - Fabric with gateway
  - Cost management
  - App modernization

### 🐛 Fix Issues
- **Troubleshoot problems:** [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Error reference & solutions:** Same file above

### 🏗️ Understand Architecture
- **How Lighthouse works:** [README.md](README.md) - "What is Azure Lighthouse?"
- **Technical deep-dive:** [ARCHITECTURE.md](docs/ARCHITECTURE.md) (coming soon)

### 📊 Run in My Environment
- **Policy enforcement examples:** [examples/policy-enforcement/README.md](examples/policy-enforcement/README.md)
- **Security operations:** [examples/security-operations/README.md](examples/security-operations/README.md) (coming soon)
- **Cost management:** [examples/cost-management/README.md](examples/cost-management/README.md) (coming soon)

---

## 📚 File Navigation by Purpose

### For Quick Reference
- **[README.md](README.md)** - Main hub, prerequisites, role IDs, features
- **[Quick Navigation (this file)](.github/NAVIGATION.md)**
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Project breakdown and statistics

### For Getting Started
1. **[README.md](README.md)** ← Start here (5 min)
2. **[QUICK_START.md](docs/QUICK_START.md)** ← For quick POC (5 min)
3. **[SETUP.md](docs/SETUP.md)** ← For real implementation (2-4 hrs)

### For Demos & Presentations
- **[5-minute-demo.md](demo-playbooks/5-minute-demo.md)** ← Use this script
- **[30-minute-demo.md](demo-playbooks/30-minute-demo.md)** (coming soon)
- **[60-minute-demo.md](demo-playbooks/60-minute-demo.md)** (coming soon)

### For Implementation
- **[templates/delegationTemplate.json](templates/delegationTemplate.json)** - Main template
- **[templates/README.md](templates/README.md)** - How to customize it
- **[scripts/setup-managing-tenant.ps1](scripts/setup-managing-tenant.ps1)** - Get principal IDs
- **[scripts/setup-customer-tenant.ps1](scripts/setup-customer-tenant.ps1)** - Prepare customer
- **[scripts/verify-delegation.ps1](scripts/verify-delegation.ps1)** - Test it works
- **[scripts/README.md](scripts/README.md)** - Script reference

### For Operations
- **[MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md)** - 6 domains
  - Policy enforcement
  - Defender & Sentinel centralization
  - Resource Graph for IaC with Copilot
  - Fabric with gateway
  - Cost management
  - App modernization

### For Troubleshooting
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Issues and solutions
- **[scripts/README.md](scripts/README.md)** - Script troubleshooting

---

## 🗺️ File Structure

```
azure-lighthouse-demo/
├── README.md                          ← Overview & main hub
├── NAVIGATION.md                      ← This file
├── PROJECT_SUMMARY.md                 ← Project breakdown
├── .gitignore
│
├── docs/
│   ├── QUICK_START.md                 ← 5-min setup
│   ├── SETUP.md                       ← Full 16-step guide
│   ├── MANAGING_TENANT_OPERATIONS.md  ← 6 operational domains
│   ├── TROUBLESHOOTING.md             ← Issues & solutions
│   └── ARCHITECTURE.md                ← Technical deep-dive (coming)
│
├── templates/
│   ├── delegationTemplate.json        ← Main ARM template
│   ├── delegationTemplate.parameters.json
│   └── README.md                      ← Customization guide
│
├── scripts/
│   ├── setup-managing-tenant.ps1      ← Get principal IDs
│   ├── setup-customer-tenant.ps1      ← Register provider
│   ├── verify-delegation.ps1          ← Test delegation
│   ├── remove-delegation.ps1          ← Remove delegation (coming)
│   └── README.md                      ← Usage guide
│
├── examples/
│   ├── policy-enforcement/README.md   ← Policy examples
│   ├── security-operations/README.md  ← Defender/Sentinel (coming)
│   ├── cost-management/README.md      ← Cost analysis (coming)
│   ├── resource-graph-queries/        ← KQL queries (coming)
│   └── fabric-gateway/README.md       ← Fabric setup (coming)
│
└── demo-playbooks/
    ├── 5-minute-demo.md               ← Quick demo script
    ├── 30-minute-demo.md              ← Detailed demo (coming)
    ├── 60-minute-demo.md              ← Full presentation (coming)
    └── customer-presentation.md       ← Slide outline (coming)
```

---

## ⏱️ Time Estimates

| Task | Time | Link |
|------|------|------|
| Understand what Lighthouse is | 5 min | [README.md](README.md) |
| Run a demo | 5-10 min | [5-minute-demo.md](demo-playbooks/5-minute-demo.md) |
| Quick POC setup | 15-30 min | [QUICK_START.md](docs/QUICK_START.md) |
| Full implementation | 2-4 hrs | [SETUP.md](docs/SETUP.md) |
| Learn all operations | 30-45 min | [MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md) |
| Fix an issue | 5-15 min | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |

---

## 🎯 Common Workflows

### Workflow 1: Quick Demo (30 min)
1. Read: [README.md](README.md) (5 min)
2. Follow: [5-minute-demo.md](demo-playbooks/5-minute-demo.md) (5 min execution)
3. Walk through: [QUICK_START.md](docs/QUICK_START.md) (10 min)
4. Answer questions: [README.md - Common Scenarios](README.md#common-scenarios)

### Workflow 2: Complete Implementation (4 hours)
1. Prerequisites: [README.md - Prerequisites](README.md#prerequisites)
2. Customize: [templates/README.md](templates/README.md)
3. Setup: [SETUP.md](docs/SETUP.md) (follow all 16 steps)
4. Scripts: Run [scripts/](scripts/) in order
5. Verify: [scripts/verify-delegation.ps1](scripts/verify-delegation.ps1)
6. Troubleshoot if needed: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### Workflow 3: Operations Setup (1-2 hours)
1. Delegation complete? Confirm with [scripts/verify-delegation.ps1](scripts/verify-delegation.ps1)
2. Choose your use-case: [MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md)
3. Follow implementation steps for that domain
4. Refer to examples in [examples/](examples/)
5. Troubleshoot: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### Workflow 4: Troubleshooting (Variable)
1. Check: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for your error
2. Follow: Solution steps
3. Still stuck? Re-read: [SETUP.md](docs/SETUP.md) relevant section
4. Check logs: Run scripts with `-Verbose` flag
5. Review: Activity Log in Azure Portal

---

## 🔗 Quick Links

| What | Link |
|------|------|
| **Main Hub** | [README.md](README.md) |
| **Quick Start** | [QUICK_START.md](docs/QUICK_START.md) |
| **Full Setup** | [SETUP.md](docs/SETUP.md) |
| **Demo Script** | [5-minute-demo.md](demo-playbooks/5-minute-demo.md) |
| **Operations** | [MANAGING_TENANT_OPERATIONS.md](docs/MANAGING_TENANT_OPERATIONS.md) |
| **Troubleshooting** | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| **Templates** | [templates/](templates/) |
| **Scripts** | [scripts/](scripts/) |
| **Examples** | [examples/](examples/) |

---

## 💡 Tips

- **Start with README.md** if you're new to Lighthouse
- **Use QUICK_START.md** if you just want to see it work
- **Follow SETUP.md step-by-step** for production implementation
- **Run scripts with -Verbose** if you hit issues
- **Check TROUBLESHOOTING.md** for common problems
- **Refer to MANAGING_TENANT_OPERATIONS.md** for day-2 operations

---

**Last Updated:** [Current session]  
**Status:** ✅ Complete and ready to use
