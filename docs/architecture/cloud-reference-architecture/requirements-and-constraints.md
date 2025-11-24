# Requirements and Constraints

## Functional Requirements

| ID     | Description                                                                                  |
|--------|----------------------------------------------------------------------------------------------|
| FR-01  | The landing zone must provide secure hosting for workloads using the Hub-Spoke architecture. |
| FR-02  | All workloads must be reachable from on-premises through ExpressRoute using private IPs.     |
| FR-03  | Logging and monitoring must be centralized using Log Analytics and Azure Monitor.            |
| FR-04  | Workloads must be deployed using Infrastructure-as-Code (Bicep) via Azure DevOps pipelines. |
| FR-05  | All platform services must integrate with Entra ID for authentication and RBAC.              |

---

## Non-Functional Requirements


| Category            | Requirement Description                                                                 |
|---------------------|------------------------------------------------------------------------------------------|
| Availability        | Workloads must meet a minimum availability of **99.95%** and use zone-redundant services where possible (ZRS, AZ-enabled). |
| Performance         | Network latency between Hub and Spoke VNets must remain below **5 ms**; storage IOPS must meet workload-specific requirements. |
| Security            | Zero Trust enforced; private endpoints mandatory; encryption-at-rest and in-transit required; Defender for Cloud enabled. |
| Compliance          | Architecture must comply with **BIO2, ISO27001, NIST SP 800-53**, and GDPR data residency requirements (EU regions only). |
| Data Classification | All resources must be tagged according to the organization's classification: Public, Internal, Confidential, or Restricted. |
| RPO                 | RPO must be **≤ 15 minutes** for critical systems; **≤ 24 hours** for non-critical workloads. |
| RTO                 | RTO must be **≤ 4 hours** for critical workloads; **≤ 48 hours** for non-critical workloads. |

---

## Assumptions

| ID   | Assumption Description                                                                       |
|------|-----------------------------------------------------------------------------------------------|
| A-01 | ExpressRoute connectivity between on-premises and Azure is already operational and monitored. |
| A-02 | Centralized identity management (Entra ID + Conditional Access) is available and maintained.  |
| A-03 | Azure Landing Zones management group structure is already deployed and governed.             |
| A-04 | Platform teams provide shared services such as DNS, Firewall, Sentinel, and Log Analytics.    |

---

## Constraints

| ID   | Constraint Description                                                                       |
|------|-----------------------------------------------------------------------------------------------|
| C-01 | Only approved Azure regions may be used (e.g., West Europe, North Europe).                    |
| C-02 | No public IPs are permitted in workload spokes; only the Hub may expose controlled public endpoints. |
| C-03 | All data must remain within EU boundaries due to GDPR and organizational policy.              |
| C-04 | Only Platform-approved SKUs are allowed (e.g., Firewall Premium, specific VM families).       |
| C-05 | Workloads must use Private DNS Resolver for name resolution; custom DNS servers are not allowed in spokes. |

---