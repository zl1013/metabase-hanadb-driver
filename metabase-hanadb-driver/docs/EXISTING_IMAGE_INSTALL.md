# Install On An Existing Metabase Docker Image

Use this path when the offline server already has the Metabase Docker image and
you only need to add the SAP HANA driver files.

## What You Need

- `hanadb.metabase-driver.jar`
- `ngdbc.jar`
- a host directory that will be bind-mounted into the container as `/plugins`

This repo packages those files with:

```bash
export HANA_NGDBC_JAR=/path/to/ngdbc.jar
bash scripts/package-plugin-bundle.sh
```

That creates:

- `dist/plugin-bundle/`
- `dist/metabase-hanadb-plugin-bundle.tar.gz`

## On The Offline Server

1. Copy `metabase-hanadb-plugin-bundle.tar.gz` to the server and unpack it.

```bash
tar -xzf metabase-hanadb-plugin-bundle.tar.gz
cd plugin-bundle
```

2. Install the plugin files into a host plugins directory.

```bash
./install-existing-image-plugin.sh /opt/metabase/plugins
```

3. Recreate the Metabase container so that directory is mounted as `/plugins`.

If you run with `docker run`, the important part is:

```bash
-e MB_PLUGINS_DIR=/plugins \
-v /opt/metabase/plugins:/plugins
```

If you run with Docker Compose, merge in `docker-compose.plugins.yml`.

Example:

```bash
docker compose -f your-current-compose.yml -f docker-compose.plugins.yml up -d
```

## Example Docker Run

```bash
docker run -d -p 3000:3000 \
  -e MB_PLUGINS_DIR=/plugins \
  -v /opt/metabase/plugins:/plugins \
  --name metabase \
  metabase/metabase:latest
```

Adjust the rest of your environment variables, app-db settings, and volumes to
match your current deployment.

## Important Note

`docker save` is for Docker images, not loose plugin JAR files. If the server
already has the correct Metabase image, the lighter path is to transfer only
the plugin bundle archive and mount it into `/plugins`. Use a full custom image
bundle only when the target image itself also needs to be delivered offline.

## Verification

After restart:

1. Check container logs.
2. Confirm the SAP HANA driver appears in the database connection list.
3. If it does not appear, verify both JARs are present in the mounted plugins
   directory and that the directory is writable by Docker.
