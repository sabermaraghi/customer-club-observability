.PHONY: help up up-demo up-probe down ps smoke docs-pdf

help:
	@echo "Targets:"
	@echo "  make up         # platform only"
	@echo "  make up-demo    # platform + synthetic OTLP"
	@echo "  make up-probe   # platform + demo + app blackbox probes"
	@echo "  make down"
	@echo "  make ps"
	@echo "  make smoke"
	@echo "  make docs-pdf"

up:
	./cc-obs.sh up

up-demo:
	./cc-obs.sh up --demo

up-probe:
	./cc-obs.sh up --demo --probe-apps

down:
	./cc-obs.sh down

ps:
	./cc-obs.sh ps

smoke:
	./cc-obs.sh smoke

docs-pdf:
	./docs/render-container-pdf.sh
