#!/usr/bin/env python3
"""Render kong.tmpl.yml -> kong.yml โดยแทน ${VAR} ด้วย env (เหมือน envsubst
แต่พึ่ง python ที่มีติดเครื่องแน่ ๆ) — pattern เดียวกับ Helm/Kustomize ในงานจริง"""
import os, re, sys, pathlib

tmpl = pathlib.Path("kong/kong.tmpl.yml").read_text()


def replace(m):
    name = m.group(1)
    val = os.environ.get(name)
    if val is None:
        sys.exit(f"missing env var: {name}")
    return val


out = re.sub(r"\$\{(\w+)\}", replace, tmpl)
pathlib.Path("kong/kong.yml").write_text(out)
print("rendered kong/kong.yml")
