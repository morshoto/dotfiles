#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Any

import yaml


def load_config(config_path: Path) -> dict[str, Any]:
    try:
        return yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    except FileNotFoundError as exc:
        raise SystemExit(f"Missing config: {config_path}") from exc


def resolve_profile(config: dict[str, Any], profile_name: str | None) -> tuple[str, dict[str, Any]]:
    if profile_name is None:
        profile_name = config.get("profile")

    if not profile_name:
        raise SystemExit("No profile specified and no top-level `profile:` found in kaggle.yml")

    profiles = config.get("profiles") or {}
    if profile_name not in profiles:
        raise SystemExit(f"Profile not found in kaggle.yml: {profile_name}")

    return profile_name, profiles[profile_name]


def clean_workdir(workdir: Path) -> None:
    workdir.mkdir(parents=True, exist_ok=True)
    for entry in workdir.iterdir():
        if entry.is_dir():
            shutil.rmtree(entry)
        else:
            entry.unlink()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="kaggle.yml")
    parser.add_argument("--profile", default=None)
    parser.add_argument("--workdir", default="kaggle_workdir")
    args = parser.parse_args()

    config_path = Path(args.config)
    config = load_config(config_path)
    profile_name, profile = resolve_profile(config, args.profile)

    config_dir = config_path.resolve().parent
    notebook = (config_dir / Path(profile["notebook"])).resolve()
    if not notebook.exists():
        raise SystemExit(f"Notebook not found: {notebook}")

    kernel = profile.get("kernel") or {}
    sources = profile.get("sources") or {}
    submit = profile.get("submit") or {}

    required_kernel_keys = ["id", "title", "code_file"]
    missing_kernel_keys = [key for key in required_kernel_keys if not kernel.get(key)]
    if missing_kernel_keys:
        raise SystemExit(f"Missing kernel keys in profile {profile_name}: {', '.join(missing_kernel_keys)}")

    workdir = Path(args.workdir)
    clean_workdir(workdir)

    code_file = Path(kernel["code_file"])
    target_notebook = workdir / code_file
    target_notebook.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(notebook, target_notebook)

    metadata: dict[str, Any] = {
        "id": kernel["id"],
        "title": kernel["title"],
        "code_file": kernel["code_file"],
        "language": kernel.get("language", "python"),
        "kernel_type": kernel.get("kernel_type", "notebook"),
        "is_private": kernel.get("is_private", True),
        "enable_gpu": kernel.get("enable_gpu", False),
        "enable_internet": kernel.get("enable_internet", False),
        "competition_sources": sources.get("competition_sources", []),
        "dataset_sources": sources.get("dataset_sources", []),
        "kernel_sources": sources.get("kernel_sources", []),
        "model_sources": sources.get("model_sources", []),
    }

    if kernel.get("accelerator") is not None:
        metadata["accelerator"] = kernel["accelerator"]

    (workdir / "kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    summary = {
        "profile": profile_name,
        "notebook": str(notebook),
        "workdir": str(workdir.resolve()),
        "kernel_id": kernel["id"],
        "code_file": kernel["code_file"],
        "submit": submit,
    }
    print(json.dumps(summary, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
