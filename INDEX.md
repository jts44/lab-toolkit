---
title: Script index
description: One-line catalog of every script, generated from _data/scripts.yml.
---

# Script index

Generated from `_data/scripts.yml`. Edit that file, not this one.

{% for s in site.data.scripts %}- `{{ s.path }}`: **{{ s.title }}** ({{ site.audiences[s.audience] }})
{% endfor %}
