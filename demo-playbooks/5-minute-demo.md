# 5-Minute Demo Walkthrough

Perfect for quick customer or colleague demos.

## Pre-Demo Setup (Run 30 mins before demo)

1. Have two browser windows open
   - Window 1: Managing Tenant Portal
   - Window 2: Customer Tenant Portal

2. Have template files ready
3. Have PowerShell open in background (optional, for showing commands)

## Demo Script (Exactly 5 minutes)

### Minute 0: Introduction (30 seconds)

**Say:**
> "I'm going to show you Azure Lighthouse - cross-tenant management. This is the managing tenant (Contoso), and I'm delegating this customer subscription to manage it here."

**Show:**
- Point to managing tenant in browser
- Point to customer tenant in second browser

### Minute 0:30 - Deploy Delegation (2 minutes)

**Say:**
> "I'm going to deploy this ARM template to the customer subscription. It creates a delegation that gives me access to manage their resources."

**Run command:**
```powershell
New-AzSubscriptionDeployment `
    -Name "LighthouseDemo" `
    -Location "eastus" `
    -TemplateFile "templates\delegationTemplate.json"
```

**While deploying, talk about:**
- No marketplace offer needed
- Template-based = instant deployment
- Customized with my tenant ID and admins

### Minute 2:30 - Show Results in Portal (1 minute)

**Refresh Managing Tenant Portal:**
1. Go to Azure Lighthouse
2. Click "Customers"
3. Click "Delegations"
4. **✓ Customer subscription appears!**

**Say:**
> "Look - the customer's subscription now appears in my Azure Lighthouse dashboard. I can see exactly what access I have. This customer gave me Contributor role for management."

### Minute 3:30 - Access Customer Resources (1 minute)

**Still in Managing Tenant:**
1. Go to "All services"
2. Search "Virtual Machines"
3. **✓ Customer's VMs appear in dropdown!**

**Say:**
> "Now I can see and manage the customer's resources directly - without logging into their tenant, without them creating accounts for me. I work from my tenant, they stay in theirs."

### Minute 4:30 - Show Customer View (30 seconds)

**Switch to Customer Tenant Portal:**
1. Search "Service providers"
2. Click "Service provider offers"
3. **✓ My delegation listed!**

**Say:**
> "From the customer's side, they can see exactly who has access. If they ever want to revoke my access, one click and I'm out. They're in control."

### Minute 5:00 - Wrap Up

**Say:**
> "That's Azure Lighthouse in a nutshell:
> - No marketplace needed, just a template
> - Instant cross-tenant management
> - Customer stays in control
> - Perfect for managed services, enterprise multi-tenant scenarios, or internal IT governance."

**Next steps:**
- "Let me show you policy enforcement..."
- "Want to see how I centralize security operations?"
- "Questions?"

---

## Follow-Up Talking Points (if asked)

### Q: How is this different from classic subscription transfer?
**A:** "With Lighthouse, the customer keeps ownership. I just get permissions. If I'm fired, the customer isn't stuck - they just revoke access."

### Q: What if the managing tenant is compromised?
**A:** "Customer can remove delegation anytime. Also, you apply strict role-based access. I might have Contributor, but not Owner. Policies enforce compliance."

### Q: How much does this cost?
**A:** "Azure Lighthouse itself is free. You pay for Azure resources you deploy."

### Q: Can we delegate management groups?
**A:** "Not directly, but we can use Azure Policy to auto-delegate all subscriptions in a management group. I can show you that."

---

## If Demo Fails

**Deployment still running?**
- Say: "Deployments can take 1-2 minutes. Let me show you the portal while it completes..."
- Switch to customer portal or show documentation

**Can't see customer subscription?**
- Say: "Sometimes there's a small delay. Let me refresh..." (Ctrl+Shift+R)
- If still not there: "Let me check the deployment status..." (show logs)

**Portal search not working?**
- Say: "Let me navigate directly to Azure Lighthouse..." (navigate by URL)

---

## Slides to Have Ready

Optional: If doing formal demo, have these slides:

1. **Title:** Azure Lighthouse - Cross-Tenant Management
2. **Problem:** How do you manage customer subscriptions?
3. **Solution:** Azure Lighthouse architecture diagram
4. **Demo:** [This walkthrough]
5. **Features:** Table of capabilities
6. **Q&A**

---

## Time Breakdown

| Section | Time | Notes |
|---------|------|-------|
| Intro | 0:30 | Set context |
| Deploy | 2:00 | Run template |
| Results | 1:00 | Show portal |
| Access | 1:00 | Show resources |
| Customer View | 0:30 | Show revoke option |
| Wrap up | 0:00 | Done! |
| **Total** | **5:00** | |

---

## Customization by Audience

### For Executives
- Focus: Cost savings, automation, security
- Skip: Technical details about roles/permissions

### For IT Admins
- Focus: Policy enforcement, compliance, audit
- Skip: High-level benefits

### For Partners/MSPs
- Focus: Multi-customer management, scalability
- Skip: Limitations

---

**Pro tip:** Record this demo once and use for training/onboarding!
