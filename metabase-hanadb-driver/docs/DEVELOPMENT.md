# Development Notes

## Build Model

Metabase community drivers are built inside a Metabase source checkout. The
helper scripts keep that checkout in `.worktrees/metabase`, copy `driver/` into
`modules/drivers/hanadb`, register the local module, and call Metabase's
`bin/build-driver.sh`.

## Driver Name

- Internal driver keyword: `:hanadb`
- Plugin JAR name: `hanadb.metabase-driver.jar`
- Display name in Metabase: `SAP HANA`

## JDBC Dependency

The driver expects SAP's JDBC implementation class:

```text
com.sap.db.jdbc.Driver
```

Place the real `ngdbc.jar` in the Metabase plugins directory next to the
Metabase driver JAR. The repository does not ship that file.

## Smoke Tests

`scripts/smoke-hana-jdbc.sh` verifies direct JDBC connectivity before debugging
Metabase UI behavior. Use it to separate network, credential, and certificate
issues from Metabase plugin issues.
