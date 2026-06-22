#!/usr/bin/env python3
import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys

try:
    import yaml
except ImportError:
    print("PyYAML is required to parse Garden config files", file=sys.stderr)
    raise SystemExit(1)


PROJECT_FILE_NAMES = (
    "garden.yml",
    "garden.yaml",
    "project.garden.yml",
    "project.garden.yaml",
)
MAX_DEPTH = 2


def load_documents(path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return list(yaml.safe_load_all(handle))
    except yaml.YAMLError as error:
        print(f"Failed to parse {path}: {error}", file=sys.stderr)
        raise SystemExit(1) from error


def project_documents(path):
    for document in load_documents(path):
        if isinstance(document, dict) and document.get("kind") == "Project":
            yield document


def project_names(path):
    for document in project_documents(path):
        name = document.get("name")
        if name:
            yield str(name)


def project_sources(path):
    for document in project_documents(path):
        sources = document.get("sources") or []
        if not isinstance(sources, list):
            continue

        for source in sources:
            if not isinstance(source, dict):
                continue

            name = source.get("name")
            if name:
                yield str(name)


def find_current_project_file(cwd):
    for file_name in PROJECT_FILE_NAMES:
        path = cwd / file_name
        if path.is_file() and any(project_names(path)):
            return path

    print(f"No Garden Project config found in {cwd}", file=sys.stderr)
    raise SystemExit(1)


def file_depth(root, path):
    return len(path.relative_to(root).parts)


def find_project_files(root):
    paths = []

    for dir_path, dir_names, file_names in os.walk(root):
        directory = Path(dir_path)
        directory_depth = len(directory.relative_to(root).parts)

        if directory_depth >= MAX_DEPTH - 1:
            dir_names.clear()

        for file_name in PROJECT_FILE_NAMES:
            if file_name not in file_names:
                continue

            path = directory / file_name
            depth = file_depth(root, path)
            if 2 <= depth <= MAX_DEPTH:
                paths.append(path)

    return sorted(paths)


def find_source_dir(source_name, workspace_roots, cwd):
    for root in workspace_roots:
        if not root.is_dir():
            continue

        for project_file in find_project_files(root):
            directory = project_file.parent
            if directory.resolve() == cwd.resolve():
                continue

            if directory.name == source_name or source_name in project_names(project_file):
                return directory

    return None


def print_command(command):
    print(f"+ {shlex.join(command)}")


def run(command, dry_run):
    print_command(command)

    if not dry_run:
        subprocess.run(command, check=True)


def run_unlink(source_name, dry_run):
    command = ["garden", "unlink", "source", source_name]
    print_command(command)

    if not dry_run:
        subprocess.run(command, check=False)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main():
    args = parse_args()
    cwd = Path.cwd()
    workspace_roots = [
        Path(root)
        for root in os.path.dirname(str(cwd)).split(os.pathsep)
        if root
    ]

    current_project_file = find_current_project_file(cwd)
    sources = sorted(set(project_sources(current_project_file)))

    for source in sources:
        source_dir = find_source_dir(source, workspace_roots, cwd)

        if source_dir is None:
            run_unlink(source, args.dry_run)
        else:
            run(["garden", "link", "source", source, str(source_dir)], args.dry_run)


if __name__ == "__main__":
    main()
