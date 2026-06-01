# Security Policy

## Sensitive Data

Do not commit:

- `.env` files
- database credentials
- VPN, SSH, or tunnel settings containing secrets
- SAP HANA JDBC binaries unless redistribution is explicitly allowed
- generated archives that may include local paths or customer-specific notes

Use `.env.example` as a template and keep real values in your local `.env`.

## Reporting

Open a private report with the maintainer if you find a credential leak or a
security-sensitive issue. Do not paste real credentials into public issues.
