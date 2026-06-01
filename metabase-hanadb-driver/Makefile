SHELL := /bin/bash

.PHONY: doctor bootstrap compose-config stack-up stack-down stack-logs smoke driver-build ngdbc-stub hana-jdbc-smoke plugin-bundle

doctor:
	./scripts/doctor.sh

bootstrap:
	./scripts/bootstrap-metabase.sh

compose-config:
	docker compose config --quiet

stack-up:
	docker compose up -d

stack-down:
	docker compose down

stack-logs:
	docker compose logs -f

smoke:
	./scripts/smoke.sh

driver-build:
	./scripts/build-driver.sh

ngdbc-stub:
	./scripts/build-ngdbc-stub.sh

hana-jdbc-smoke:
	./scripts/smoke-hana-jdbc.sh

plugin-bundle:
	./scripts/package-plugin-bundle.sh
