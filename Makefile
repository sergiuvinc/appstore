# only random once obviously ;)
python=venv/bin/python
pip=venv/bin/pip
pycodestyle=venv/bin/pycodestyle
pyresttest=venv/bin/pyresttest
mypy=venv/bin/mypy
manage=$(python) $(CURDIR)/manage.py
db=sqlite

.PHONY: lint
lint:
	$(pycodestyle) $(CURDIR)/nextcloudappstore --exclude=migrations
	$(mypy) --silent-imports --disallow-untyped-defs $(CURDIR)/nextcloudappstore/core/api/v1/release
	$(mypy) --silent-imports --disallow-untyped-defs $(CURDIR)/nextcloudappstore/core/certificate

.PHONY: test
test: lint
	$(manage) test --settings nextcloudappstore.settings.development

.PHONY: resetup
resetup:
	rm -f db.sqlite3
	$(manage) migrate --settings nextcloudappstore.settings.development
	@echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | $(manage) shell --settings nextcloudappstore.settings.development
	@echo "from django.contrib.auth.models import User; from allauth.account.models import EmailAddress; EmailAddress.objects.create(user=User.objects.get(username='admin'), email='admin@example.com', verified=True, primary=True)" | $(manage) shell --settings nextcloudappstore.settings.development
	$(manage) loaddata $(CURDIR)/nextcloudappstore/**/fixtures/*.json --settings nextcloudappstore.settings.development

.PHONY: initmigrations
initmigrations:
	rm -f $(CURDIR)/nextcloudappstore/**/migrations/0*.py
	$(manage) makemigrations --settings nextcloudappstore.settings.development

# Only for local setup, do not use in production
.PHONY: dev-setup
dev-setup:
	pyvenv venv
	$(pip) install -r $(CURDIR)/requirements/development.txt
	$(pip) install -r $(CURDIR)/requirements/base.txt
	cp $(CURDIR)/scripts/development/settings/base.py $(CURDIR)/nextcloudappstore/settings/development.py
	cat $(CURDIR)/scripts/development/settings/$(db).py >> $(CURDIR)/nextcloudappstore/settings/development.py
	$(manage) migrate --settings nextcloudappstore.settings.development
	$(manage) loaddata $(CURDIR)/nextcloudappstore/**/fixtures/*.json --settings nextcloudappstore.settings.development
	@echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | $(manage) shell --settings nextcloudappstore.settings.development
	@echo "from django.contrib.auth.models import User; from allauth.account.models import EmailAddress; EmailAddress.objects.create(user=User.objects.get(username='admin'), email='admin@example.com', verified=True, primary=True)" | $(manage) shell --settings nextcloudappstore.settings.development

# Only for local setup, do not use in production
.PHONY: travis-setup
travis-setup:
	$(pip) install -r $(CURDIR)/requirements/production.txt
	make db-setup

.PHONY: docs
docs:
	@echo "hi"
	$(MAKE) -C $(CURDIR)/docs/ html
