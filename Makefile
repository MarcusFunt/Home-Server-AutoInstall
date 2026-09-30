.PHONY: check lint syntax dependencies deploy verify-host compose-config secrets-check

check: lint syntax compose-config secrets-check

lint:
	yamllint -c .yamllint .
	ansible-lint ansible/playbooks/site.yml
	shellcheck scripts/*.sh

syntax:
	ansible-playbook --syntax-check --inventory ansible/inventory/hosts.yml ansible/playbooks/site.yml

dependencies:
	ansible-galaxy role install --role-file ansible/requirements.yml --roles-path ansible/vendor/roles
	ansible-galaxy collection install --requirements-file ansible/requirements.yml --collections-path ansible/vendor/collections

compose-config:
	bash scripts/validate-compose.sh

secrets-check:
	bash scripts/check-secrets.sh

deploy:
	bash scripts/deploy.sh

verify-host:
	sudo bash scripts/verify-host.sh
