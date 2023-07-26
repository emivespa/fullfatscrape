ifneq (,$(wildcard ./.env))
    include .env
    export
endif

default: ;

subs:
	./script.sh

bulk: subs
	mkdir -p $@
	rm -rf ./* $@
	node lines

.PHONY: curl
curl:
	find bulk -type f | while read -r file; do \
		curl -XPOST \
			--data-binary @./$$file \
			-H 'Content-Type: application/json' \
			-u '$(OPENSEARCH_USER):$(OPENSEARCH_PASSWORD)' \
			-- '$(OPENSEARCH_DOMAIN)/_bulk/?filter_path=result,took' ; \
			sleep 30 ; \
		done

.PHONY: 1-delete
1-delete:
	curl -XDELETE \
	-u '$(OPENSEARCH_USER):$(OPENSEARCH_PASSWORD)' \
	-- '$(OPENSEARCH_DOMAIN)/$(OPENSEARCH_INDEX)'

.PHONY: test-opensearch
test-opensearch:
	curl \
		-u '$(OPENSEARCH_USER):$(OPENSEARCH_PASSWORD)' \
		-w "%{http_code}\n" \
		-- '$(OPENSEARCH_DOMAIN)'
# -- '$(OPENSEARCH_DOMAIN)/_search/?q=libro'
