PROJECT := fernando-optometry-site
SITE    := https://$(PROJECT).web.app
FIREBASE := firebase --project $(PROJECT) --non-interactive
DOMAIN  := https://fernandooptometry.com

.PHONY: help deploy preview serve check login sitemap

help:
	@echo "make deploy   - regenerate the sitemap and deploy the site to $(SITE)"
	@echo "make sitemap  - regenerate sitemap.xml from the HTML pages"
	@echo "make preview  - deploy to a temporary preview URL (expires in 7 days)"
	@echo "make serve    - serve the site locally on port 5000"
	@echo "make check    - check that the live site is up and hidden files are not served"
	@echo "make login    - log in to Firebase (works over ssh)"

deploy: sitemap
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

# Every index.html becomes a URL; lastmod is the date of the page's last commit.
sitemap:
	@{ \
	  echo '<?xml version="1.0" encoding="UTF-8"?>'; \
	  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'; \
	  for f in $$(git ls-files '*index.html' | sort); do \
	    path=$${f%index.html}; \
	    date=$$(git log -1 --format=%cs -- $$f); \
	    echo "  <url><loc>$(DOMAIN)/$$path</loc><lastmod>$${date:-$$(date +%F)}</lastmod></url>"; \
	  done; \
	  echo '</urlset>'; \
	} > sitemap.xml
	@echo "sitemap.xml: $$(grep -c '<url>' sitemap.xml) URLs"
