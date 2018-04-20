{%- from slspath+"/map.jinja" import vault with context -%}

vault-init-file:
  file.managed:
    {%- if salt['test.provider']('service') == 'systemd' %}
    - source: salt://{{ slspath }}/files/vault.service.jinja
    - name: /etc/systemd/system/vault.service
    - template: jinja
    - mode: 0644
    {%- elif salt['test.provider']('service') == 'upstart' %}
    - source: salt://{{ slspath }}/files/vault.upstart.jinja
    - name: /etc/init/vault.conf
    - template: jinja
    - mode: 0644
    {%- endif %}

{%- if vault.service %}

vault-service:
  service.running:
    - name: vault
    - enable: True
    - watch:
      - file: vault-init-file

{%- endif %}
