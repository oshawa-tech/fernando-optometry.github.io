PROJECT := fernando-optometry-site
SITE    := https://$(PROJECT).web.app
FIREBASE := firebase --project $(PROJECT) --non-interactive

.PHONY: help deploy preview serve check login

help:
	@echo "make deploy   - deploy the site to $(SITE)"
	@echo "make preview  - deploy to a temporary preview URL (expires in 7 days)"
	@echo "make serve    - serve the site locally on port 5000"
	@echo "make check    - check that the live site is up and hidden files are not served"
	@echo "make login    - log in to Firebase (works over ssh)"

deploy:
	$(FIREBASE) deploy --only hosting
	@$(MAKE) --no-print-directory check

preview:
	$(FIREBASE) hosting:channel:deploy preview --expires 7d

serve:
	$(FIREBASE) serve --only hosting --host 0.0.0.0 --port 5000

check:
	@for p in / /faq/ /services/eye-exams/; do \
	  code=$$(curl -s -o /dev/null -w '%{http_code}' $(SITE)$$p); \
	  echo "$$code $$p"; [ "$$code" = 200 ] || exit 1; \
	done
	@for p in /.git/HEAD /firebase.json /Makefile; do \
	  code=$$(curl -s -o /dev/null -w '%{http_code}' $(SITE)$$p); \
	  echo "$$code $$p"; [ "$$code" = 404 ] || { echo "ERROR: $$p is publicly served"; exit 1; }; \
	done

login:
	firebase login --no-localhost
