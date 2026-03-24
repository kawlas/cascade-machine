#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path


def load_payload(path: str):
    with Path(path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def flatten_prices(value):
    if isinstance(value, dict):
        result = []
        for nested in value.values():
            result.extend(flatten_prices(nested))
        return result
    if value in (None, ""):
        return []
    return [str(value)]


def is_zero_cost(model):
    values = flatten_prices(model.get("pricing") or model.get("prices") or {})
    if not values:
        return False
    return all(re.fullmatch(r"0+(\.0+)?", item) for item in values)


def coerce_context(model):
    keys = [
        "context_length",
        "context_window",
        "max_context_length",
        "input_token_limit",
        "inputTokenLimit",
        "max_input_tokens",
        "outputTokenLimit",
    ]
    for key in keys:
        if key in model and model[key]:
            return str(model[key])
    architecture = model.get("architecture") or {}
    for key in ("context_length", "input_modalities"):
        if key in architecture and architecture[key]:
            return str(architecture[key])
    top_provider = model.get("top_provider") or {}
    if top_provider.get("context_length"):
        return str(top_provider["context_length"])
    return ""


def format_record(provider, display_model, aider_model, tier, context, api_base, key_var):
    fields = [provider, display_model, aider_model, tier, context, api_base, key_var]
    return "\t".join(fields)


def parse_openrouter(provider, tier, api_base, key_var, payload):
    records = []
    for model in payload.get("data", []):
        model_id = model.get("id")
        if not model_id:
            continue
        model_tier = "free" if is_zero_cost(model) or model_id.endswith(":free") else tier
        records.append(
            format_record(
                provider,
                f"{provider}/{model_id}",
                f"openrouter/{model_id}",
                model_tier,
                coerce_context(model),
                api_base,
                key_var,
            )
        )
    return records


def parse_openai_like(provider, tier, api_base, key_var, payload):
    prefix = provider if provider in {"groq", "cerebras", "xai"} else "openai"
    records = []
    for model in payload.get("data", []):
        model_id = model.get("id")
        if not model_id:
            continue
        records.append(
            format_record(
                provider,
                f"{provider}/{model_id}",
                f"{prefix}/{model_id}",
                tier,
                coerce_context(model),
                api_base,
                key_var,
            )
        )
    return records


def parse_xai(provider, tier, api_base, key_var, payload):
    records = []
    for model in payload.get("data", []):
        model_id = model.get("id")
        if not model_id:
            continue
        model_tier = "free" if is_zero_cost(model) else tier
        records.append(
            format_record(
                provider,
                f"{provider}/{model_id}",
                f"xai/{model_id}",
                model_tier,
                coerce_context(model),
                api_base,
                key_var,
            )
        )
    return records


def parse_gemini(provider, tier, api_base, key_var, payload):
    records = []
    for model in payload.get("models", []):
        name = model.get("name", "")
        if not name.startswith("models/"):
            continue
        methods = model.get("supportedGenerationMethods") or []
        if "generateContent" not in methods:
            continue
        model_id = name.split("/", 1)[1]
        records.append(
            format_record(
                provider,
                f"{provider}/{model_id}",
                f"gemini/{model_id}",
                tier,
                coerce_context(model),
                api_base,
                key_var,
            )
        )
    return records


def parse_payload(provider, kind, tier, api_base, key_var, payload):
    if kind == "openrouter":
        return parse_openrouter(provider, tier, api_base, key_var, payload)
    if kind == "gemini":
        return parse_gemini(provider, tier, api_base, key_var, payload)
    if kind == "xai":
        return parse_xai(provider, tier, api_base, key_var, payload)
    return parse_openai_like(provider, tier, api_base, key_var, payload)


def main():
    provider, kind, tier, api_base, key_var, payload_path = sys.argv[1:7]
    payload = load_payload(payload_path)
    for record in parse_payload(provider, kind, tier, api_base, key_var, payload):
        print(record)


if __name__ == "__main__":
    main()
