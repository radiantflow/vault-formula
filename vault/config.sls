{% from "vault/map.jinja" import vault with context %}

{%- if vault.server == true %}
vault-config-dir:
  file.directory:
    - name: /etc/vault/config.d
    - user: vault
    - group: vault
    - makedirs: true

{%- if vault.self_signed_cert.enabled %}
vault-install-cert-gen:
  file.managed:
    - name: /usr/local/bin/self-cert-gen.sh
    - source: salt://vault/files/cert-gen.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

vault-run-cert-gen:
  cmd.run:
    - name: bash /usr/local/bin/cert-gen.sh {{ vault.self_signed_cert.hostname }} {{ vault.self_signed_cert.password }}
    - cwd: /etc/vault/certs
    - require:
      - file: vault-install-cert-gen

{% do vault.config.listener.tcp.update({
  'tls_cert_file': vault.self_signed_cert.hostname + '.pem',
  'tls_key_file': vault.self_signed_cert.hostname + '-nopass.key'
}) %}
{% endif %}

vault-config:
  file.managed:
    - name: /etc/vault/config.d/config.json
    {%- if vault.service != False %}
    - watch_in:
       - service: vault
    {%- endif %}
    - user: vault
    - group: vault
    - require:
      - user: vault
    - contents: |
        {{ vault.config | json }}



{% endif -%}