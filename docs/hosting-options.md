# HE Toolkit Dashboard Hosting Options

This note summarises possible hosting routes for the HE Toolkit Dashboard. It is intentionally high level and does not include credentials, tokens, or environment-specific deployment settings.

## shinyapps.io

- Security: managed hosting with HTTPS; suitable for demos and lower-risk deployments.
- Performance: easy to start, but scaling and memory limits depend on plan.
- Maintenance: low operational burden.
- Cost: subscription-based; cost increases with usage.
- Fit: good for prototypes, stakeholder demos, and short-term external access.

## Posit Connect

- Security: stronger enterprise controls, authentication, permissions, and audit options.
- Performance: better suited to managed production Shiny workloads.
- Maintenance: moderate; requires server administration or managed service support.
- Cost: commercial licensing and infrastructure cost.
- Fit: strong candidate for production use where governance and access control matter.

## Internal Server Deployment

- Security: can remain inside the client or organisation network.
- Performance: depends on internal server resources and R/Shiny Server setup.
- Maintenance: requires local IT support for R packages, patching, backups, and monitoring.
- Cost: uses existing infrastructure if available, but has staff maintenance cost.
- Fit: suitable when data must remain inside an internal network.

## Docker Deployment

- Security: reproducible runtime, easier dependency isolation, and clearer deployment boundaries.
- Performance: depends on host/container orchestration.
- Maintenance: requires Docker image maintenance and patching.
- Cost: flexible; can run on internal servers or cloud infrastructure.
- Fit: good for repeatable production deployments and controlled dependency management.

## Cloud VM Deployment

- Security: flexible but requires careful firewall, HTTPS, identity, logging, and patch management.
- Performance: scalable by choosing VM size, storage, and network options.
- Maintenance: higher operational burden than managed Shiny platforms.
- Cost: pay-as-you-go infrastructure cost.
- Fit: useful when the team needs full control and can manage cloud operations.

## Initial Recommendation

For client demos, shinyapps.io or a temporary Posit Connect deployment is the lowest-friction route. For production, Posit Connect or Docker on an internal/server-managed environment is likely safer because the dashboard may process uploaded ecology, flow, WQ, and RHS data.
