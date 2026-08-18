#!/usr/bin/env python3
"""Generate a DeepSeek Harness agent preset from Codex-style TOML roles.

The generated preset uses Harness-native composition files:

  agent.cordis.yml
    -> flattened runtime composition:
       official standard preset rows + one role row per Codex agent
  agents/<role>.cordis.yml
    -> readable source fragments for each generated role

Each role file contributes one @deepseek-ai/dsh-tool-subagent row with a fixed
toolName and persona. The primary source is the upstream
VoltAgent/awesome-codex-subagents repository, usually its categories/**/*.toml
files. The Harness-required preset entrypoint is deliberately flattened because
nested cordis:include files under ~/.dsh/.agent-presets do not inherit the
package-resolution base that agent-presets applies to the root composition.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None


DEFAULT_PRESET_ID = "codex-roles"
DEFAULT_SOURCE_DIR = "~/.dsh/_awesome-codex-subagents"


@dataclass(frozen=True)
class CodexAgent:
    source: Path
    name: str
    description: str
    instructions: str
    model: Optional[str]
    reasoning_effort: Optional[str]
    sandbox_mode: Optional[str]
    file_stem: str
    row_id: str
    tool_name: str


def expand_path(value: str) -> Path:
    return Path(value).expanduser().resolve()


def safe_suffix(value: str, separator: str) -> str:
    chars: list[str] = []
    previous_sep = False
    for char in value.lower():
        if char.isascii() and char.isalnum():
            chars.append(char)
            previous_sep = False
        elif not previous_sep:
            chars.append(separator)
            previous_sep = True
    suffix = "".join(chars).strip(separator)
    if not suffix:
        raise ValueError(f"cannot derive safe suffix from agent name: {value!r}")
    return suffix


def required_str(data: dict[str, object], key: str, source: Path) -> str:
    value = data.get(key)
    if not isinstance(value, str) or value == "":
        raise ValueError(f"{source}: missing non-empty TOML string field {key!r}")
    return value


def optional_str(data: dict[str, object], key: str, source: Path) -> Optional[str]:
    value = data.get(key)
    if value is None:
        return None
    if not isinstance(value, str):
        raise ValueError(f"{source}: TOML field {key!r} must be a string when present")
    return value


def parse_fixed_agent_toml(source: Path) -> dict[str, object]:
    content = source.read_text(encoding="utf-8")
    data: dict[str, object] = {}

    for key in ("name", "description", "model", "model_reasoning_effort", "sandbox_mode"):
        match = re.search(rf'^{key}\s*=\s*("(?:(?:\\.)|[^"\\])*")\s*$', content, re.MULTILINE)
        if match is None:
            continue
        data[key] = json.loads(match.group(1))

    match = re.search(r'^developer_instructions\s*=\s*"""\r?\n?([\s\S]*?)\r?\n?"""', content, re.MULTILINE)
    if match is None:
        raise ValueError(f"{source}: missing TOML multiline field 'developer_instructions'")
    data["developer_instructions"] = match.group(1)
    return data


def parse_agent_toml(source: Path) -> dict[str, object]:
    if tomllib is not None:
        with source.open("rb") as file:
            return tomllib.load(file)
    return parse_fixed_agent_toml(source)


def discover_toml_files(source_dir: Path) -> list[Path]:
    if not source_dir.is_dir():
        raise ValueError(f"source role directory not found: {source_dir}")

    categories_dir = source_dir / "categories"
    search_root = categories_dir if categories_dir.is_dir() else source_dir
    files = sorted(path for path in search_root.rglob("*.toml") if path.is_file())
    if not files:
        raise ValueError(f"no .toml role files found in {search_root}")
    return files


def read_codex_agents(source_dir: Path) -> list[CodexAgent]:
    agents: list[CodexAgent] = []
    names: set[str] = set()
    row_ids: set[str] = set()
    tool_names: set[str] = set()

    for source in discover_toml_files(source_dir):
        data = parse_agent_toml(source)

        name = required_str(data, "name", source)
        description = required_str(data, "description", source)
        instructions = required_str(data, "developer_instructions", source)
        file_stem = safe_suffix(name, "-")
        tool_suffix = safe_suffix(name, "_")
        row_id = f"tool-subagent-role-{file_stem}"
        tool_name = f"subagent_{tool_suffix}"

        if name in names:
            raise ValueError(f"duplicate Codex agent name: {name}")
        if row_id in row_ids:
            raise ValueError(f"duplicate generated row id: {row_id}")
        if tool_name in tool_names:
            raise ValueError(f"duplicate generated tool name: {tool_name}")

        names.add(name)
        row_ids.add(row_id)
        tool_names.add(tool_name)
        agents.append(
            CodexAgent(
                source=source,
                name=name,
                description=description,
                instructions=instructions.replace("\r\n", "\n"),
                model=optional_str(data, "model", source),
                reasoning_effort=optional_str(data, "model_reasoning_effort", source),
                sandbox_mode=optional_str(data, "sandbox_mode", source),
                file_stem=file_stem,
                row_id=row_id,
                tool_name=tool_name,
            )
        )

    return agents


def npm_global_root() -> Optional[Path]:
    try:
        output = subprocess.check_output(["npm", "root", "-g"], text=True, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    return Path(output).expanduser().resolve() if output else None


def locate_standard_preset(explicit: str | None) -> Path:
    candidates: list[Path] = []
    if explicit:
        candidates.append(expand_path(explicit))
    env_value = os.environ.get("DSH_STANDARD_PRESET_DIR")
    if env_value:
        candidates.append(expand_path(env_value))
    global_root = npm_global_root()
    if global_root is not None:
        candidates.append(global_root / "@deepseek-ai" / "dsh" / "config" / "agent-presets" / "standard")
    candidates.extend(
        [
            Path("/opt/homebrew/lib/node_modules/@deepseek-ai/dsh/config/agent-presets/standard"),
            Path("/usr/local/lib/node_modules/@deepseek-ai/dsh/config/agent-presets/standard"),
        ]
    )

    checked: list[Path] = []
    for candidate in candidates:
        candidate = candidate.expanduser().resolve()
        if candidate in checked:
            continue
        checked.append(candidate)
        if (candidate / "agent.cordis.yml").is_file():
            return candidate

    rendered = "\n".join(f"- {path}" for path in checked)
    raise ValueError(
        "could not locate DeepSeek Harness standard preset. "
        "Install dsh globally or pass --standard-preset-dir.\n"
        f"Checked:\n{rendered}"
    )


def indent_block(text: str, spaces: int) -> str:
    prefix = " " * spaces
    lines = text.rstrip().split("\n")
    return "\n".join(f"{prefix}{line}" for line in lines)


def persona_for(agent: CodexAgent) -> str:
    parts = [
        f'You are the DeepSeek Harness child-agent role "{agent.name}".',
        "",
        "Routing description:",
        agent.description,
        "",
        "Source role metadata:",
        f"- source file: {agent.source.name}",
        f"- source role name: {agent.name}",
        f"- source model hint: {agent.model or 'not specified'}",
        f"- source reasoning effort hint: {agent.reasoning_effort or 'not specified'}",
        f"- source sandbox mode hint: {agent.sandbox_mode or 'not specified'}",
        "",
        "Role instructions:",
        agent.instructions,
        "",
        "DeepSeek Harness execution notes:",
        "- You run through DeepSeek Harness @deepseek-ai/dsh-tool-subagent.",
        "- You inherit the parent preset capabilities and model route unless the tool is configured otherwise.",
        "- Follow the delegated prompt boundary exactly.",
        "- Return concise results with concrete evidence, file paths, commands, and residual risk when relevant.",
    ]
    if agent.sandbox_mode == "read-only":
        parts.append("- The source role was read-only; do not modify files unless the parent explicitly asks.")
    return "\n".join(parts)


def render_role_file(agent: CodexAgent) -> str:
    return (
        f"# Generated from {agent.source.name}. Edit the source role and rerun the converter.\n"
        f"- id: {agent.row_id}\n"
        "  name: '@deepseek-ai/dsh-tool-subagent'\n"
        "  config:\n"
        "    provider: spawn\n"
        f"    toolName: {agent.tool_name}\n"
        "    backgroundMode: one-shot\n"
        "    enableRunInBackground: false\n"
        "    persona: |-\n"
        f"{indent_block(persona_for(agent), 6)}\n"
    )


def render_agent_index(agents: list[CodexAgent]) -> str:
    lines = [
        "# Generated include list for fixed expert role tools.",
        "# Each included file contributes one @deepseek-ai/dsh-tool-subagent row.",
    ]
    for agent in agents:
        path = f"./{agent.file_stem}.cordis.yml"
        lines.extend(
            [
                f"- id: include-role-{agent.file_stem}",
                "  name: cordis:include",
                "  config:",
                f"    path: {json.dumps(path, ensure_ascii=False)}",
            ]
        )
    return "\n".join(lines) + "\n"


def render_flat_entrypoint(standard_content: str, agents: list[CodexAgent]) -> str:
    role_rows = "\n".join(render_role_file(agent).rstrip() for agent in agents)
    return (
        "# DeepSeek Harness preset entrypoint.\n"
        "# This file is flattened for runtime loading. Keep agents/*.cordis.yml as\n"
        "# readable generated fragments, but do not include them from here: nested\n"
        "# cordis:include files under ~/.dsh/.agent-presets do not inherit Harness'\n"
        "# package-resolution base for @deepseek-ai/dsh-* plugins.\n"
        "\n"
        "# ---- official standard preset rows ----\n"
        f"{standard_content.rstrip()}\n"
        "\n"
        "# ---- fixed expert role subagent tools ----\n"
        f"{role_rows}\n"
    )


def render_preset_metadata(count: int) -> str:
    return (
        "name: 专家角色模式\n"
        "description: 基于 DeepSeek Harness 原生 agent preset / tool-subagent / persona 机制，"
        f"预置 {count} 个固定专家子 agent 角色。\n"
    )


def escape_markdown_cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def render_role_map(agents: list[CodexAgent], source_dir: Path, preset_id: str) -> str:
    lines = [
        "# DeepSeek Harness Expert Role Map",
        "",
        "This file is generated for humans. DeepSeek Harness loads the `.cordis.yml` files, not this map.",
        "",
        f"- Source role directory: `{source_dir}`",
        f"- Harness preset id: `{preset_id}`",
        f"- Generated roles: {len(agents)}",
        "",
        "| Source role | Harness tool | Role file | Description |",
        "|---|---|---|---|",
    ]
    for agent in agents:
        lines.append(
            f"| `{agent.name}` | `{agent.tool_name}` | `agents/{agent.file_stem}.cordis.yml` | "
            f"{escape_markdown_cell(agent.description)} |"
        )
    return "\n".join(lines) + "\n"


def write_generated_preset(
    target: Path,
    standard_preset: Path,
    agents: list[CodexAgent],
    source_dir: Path,
    preset_id: str,
    force: bool,
) -> Tuple[Path, Optional[Path]]:
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    temp = target.parent / f".{target.name}.tmp.{os.getpid()}.{stamp}"
    backup = target.with_name(f"{target.name}.bak.{stamp}")

    if target.exists() and not force:
        raise ValueError(f"target preset already exists: {target}\nRe-run with --force to replace it with a backup.")

    if temp.exists():
        shutil.rmtree(temp)
    temp.mkdir(parents=True)
    (temp / "base").mkdir()
    (temp / "agents").mkdir()

    standard_content = (standard_preset / "agent.cordis.yml").read_text(encoding="utf-8")
    shutil.copy2(standard_preset / "agent.cordis.yml", temp / "base" / "standard.agent.cordis.yml")
    (temp / "agent.cordis.yml").write_text(render_flat_entrypoint(standard_content, agents), encoding="utf-8")
    (temp / "preset.yml").write_text(render_preset_metadata(len(agents)), encoding="utf-8")
    (temp / "agent-role-map.md").write_text(render_role_map(agents, source_dir, preset_id), encoding="utf-8")
    (temp / "agents" / "index.cordis.yml").write_text(render_agent_index(agents), encoding="utf-8")
    for agent in agents:
        (temp / "agents" / f"{agent.file_stem}.cordis.yml").write_text(render_role_file(agent), encoding="utf-8")

    if target.exists():
        target.rename(backup)
    temp.rename(target)
    return target, backup if backup.exists() else None


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a DeepSeek Harness expert-role preset from Codex-style TOML roles.")
    parser.add_argument("--source-dir", default=DEFAULT_SOURCE_DIR, help="Source directory containing categories/**/*.toml or *.toml role files.")
    parser.add_argument("--codex-agents-dir", help="Deprecated alias for --source-dir; kept for old local ~/.codex/agents input.")
    parser.add_argument("--dsh-home", default=os.environ.get("DSH_HOME", "~/.dsh"))
    parser.add_argument("--preset-id", default=DEFAULT_PRESET_ID)
    parser.add_argument("--standard-preset-dir")
    parser.add_argument("--output-dir")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args(argv)
    if not args.preset_id or not args.preset_id[0].isalnum() or any(
        not (char.isalnum() or char == "-") for char in args.preset_id
    ):
        parser.error("--preset-id must match [a-z0-9][a-z0-9-]*")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    source_dir = expand_path(args.codex_agents_dir or args.source_dir)
    dsh_home = expand_path(args.dsh_home)
    target = expand_path(args.output_dir) if args.output_dir else dsh_home / ".agent-presets" / args.preset_id
    standard_preset = locate_standard_preset(args.standard_preset_dir)
    agents = read_codex_agents(source_dir)

    print(f"Source roles : {source_dir}")
    print(f"Role count   : {len(agents)}")
    print(f"Standard base: {standard_preset}")
    print(f"Preset id    : {args.preset_id}")
    print(f"Output dir   : {target}")
    print("")
    print("Generated layout:")
    print("  agent.cordis.yml  (flattened runtime composition)")
    print("  base/standard.agent.cordis.yml")
    print("  agents/index.cordis.yml  (readable generated index)")
    print(f"  agents/<role>.cordis.yml x {len(agents)}")
    print("")
    print("Preview:")
    for agent in agents[:10]:
        print(f"  {agent.name} -> {agent.tool_name} -> agents/{agent.file_stem}.cordis.yml")
    if len(agents) > 10:
        print(f"  ... {len(agents) - 10} more")

    if args.dry_run:
        print("")
        print("DRY-RUN: no files written.")
        return 0

    written, backup = write_generated_preset(
        target=target,
        standard_preset=standard_preset,
        agents=agents,
        source_dir=source_dir,
        preset_id=args.preset_id,
        force=args.force,
    )
    print("")
    print(f"Wrote preset : {written}")
    if backup is not None:
        print(f"Backup      : {backup}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
