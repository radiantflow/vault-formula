{% from slspath+"/map.jinja" import vault with context %}

include:
  - {{ slspath }}.install
  - {{ slspath }}.config
  - {{ slspath }}.service

