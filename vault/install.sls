{% from "vault/map.jinja" import vault with context %}

vault-packages:
  pkg.installed:
    - names:
      - unzip
      - curl
      {% if vault.secure_download %}
      {% if grains['os'] == 'CentOS' or grains['os'] == 'Amazon' %}
      - gnupg2
      - perl-Digest-SHA
      {% elif grains['os'] == 'Ubuntu' %}
      - gnupg
      - libdigest-sha-perl
      {% endif %}
      {% endif %}


vault-bin-dir:
  file.directory:
    - name: /usr/local/bin
    - makedirs: True

# Create vault user
vault-user:
  group.present:
    - name: {{ vault.group }}
  user.present:
    - name: {{ vault.user }}
    - createhome: false
    - system: true
    - groups:
      - {{ vault.group }}
    - require:
      - group: {{ vault.group }}


vault-download:
  file.managed:
    - name: /tmp/vault_{{ vault.version }}_linux_{{ vault.arch }}.zip
    - source: https://{{ vault.download_host }}/vault/{{ vault.version }}/vault_{{ vault.version }}_linux_{{ vault.arch }}.zip
    - source_hash: https://releases.hashicorp.com/vault/{{ vault.version }}/vault_{{ vault.version }}_SHA256SUMS
    - unless: test -f /usr/local/bin/vault-{{ vault.version }}

# Install vault

{% if vault.secure_download %}
vault-sig:
  cmd.run:
    - name: curl --silent -L https://releases.hashicorp.com/vault/{{ vault.version }}/vault_{{ vault.version }}_SHA256SUMS.sig -o /tmp/vault_{{ vault.version }}_SHA256SUMS.sig
    - creates: /tmp/vault_{{ vault.version }}_SHA256SUMS.sig

vault-key-download:
  file.managed:
    - name: /tmp/hashicorp.asc
    - source: salt://vault/files/hashicorp.asc.jinja
    - template: jinja

vault-key-import:
  cmd.run:
    - name: gpg --import /tmp/hashicorp.asc
    - unless: gpg --list-keys {{ vault.hashicorp_key_id }}
    - requires:
      - file: vault-key-download
      - cmd: vault-packages

vault-sig-verify:
  cmd.run:
    - name: gpg --verify /tmp/vault_{{ vault.version }}_SHA256SUMS.sig /tmp/vault_{{ vault.version }}_SHA256SUMS
    - require:
      - file: vault-download
      - cmd: vault-key-import

{% endif %}

vault-extract:
  cmd.wait:
    - name: unzip /tmp/vault_{{ vault.version }}_linux_{{ vault.arch }}.zip -d /tmp
    - watch:
      - file: vault-download

vault-install:
  file.rename:
    - name: /usr/local/bin/vault-{{ vault.version }}
    - source: /tmp/vault
    - require:
      - file: /usr/local/bin
    - watch:
      - cmd: vault-extract

vault-clean:
  file.absent:
    - name: /tmp/vault_{{ vault.version }}_linux_{{ vault.arch }}.zip
    - watch:
      - file: vault-install

vault-link:
  file.symlink:
    - target: vault-{{ vault.version }}
    - name: /usr/local/bin/vault
    - watch:
      - file: vault-install

vault-setcap:
  cmd.run:
    - name: "setcap cap_ipc_lock=+ep /usr/local/bin/vault-{{ vault.version }}"
    - watch:
      - file: vault-install
