import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class CascadePackagingTests(unittest.TestCase):
    def run_command(self, *args, env=None):
        merged_env = os.environ.copy()
        if env:
            merged_env.update(env)
        return subprocess.run(
            args,
            cwd=REPO_ROOT,
            env=merged_env,
            text=True,
            capture_output=True,
            check=True,
        )

    def test_aliases_script_contains_official_commands(self):
        aliases_path = REPO_ROOT / "scripts" / "aliases.sh"
        content = aliases_path.read_text()

        expected_aliases = [
            'alias quick=\'"$HOME/.cascade/help.sh" quick\'',
            "alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'",
            'alias think=\'"$HOME/.cascade/help.sh" think\'',
            'alias cloud=\'"$HOME/.cascade/help.sh" cloud\'',
            "alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'",
        ]

        for alias_line in expected_aliases:
            self.assertIn(alias_line, content)
        self.assertIn('alias cascade-start=', content)
        self.assertIn("cascade() {", content)

    def test_install_creates_runtime_layout_in_clean_home(self):
        temp_home = tempfile.mkdtemp(prefix="cascade-home-")
        self.addCleanup(lambda: shutil.rmtree(temp_home, ignore_errors=True))
        (Path(temp_home) / ".zshrc").write_text("")

        self.run_command("bash", "install.sh", "--force", env={"HOME": temp_home})

        runtime_dir = Path(temp_home) / ".cascade"
        expected_paths = [
            runtime_dir / "heal.sh",
            runtime_dir / "help.sh",
            runtime_dir / "router.sh",
            runtime_dir / ".install-source",
            runtime_dir / "lib" / "chat_session.sh",
            runtime_dir / "lib" / "catalog_parser.py",
            runtime_dir / "lib" / "router_policy.sh",
            runtime_dir / "lib" / "router_core.sh",
            runtime_dir / "lib" / "router_status.sh",
            runtime_dir / "lib" / "model_catalog.sh",
            runtime_dir / "lib" / "model_health.sh",
            runtime_dir / "lib" / "router_selection.sh",
            runtime_dir / "lib" / "nightly_core.sh",
            runtime_dir / "docs" / "INSTALL.md",
            runtime_dir / "docs" / "COMMANDS.md",
            runtime_dir / ".env",
            runtime_dir / ".env.cascade",
            Path(temp_home) / ".zshrc",
        ]

        for path in expected_paths:
            self.assertTrue(path.exists(), f"missing installed path: {path}")

        shell_config = (Path(temp_home) / ".zshrc").read_text()
        self.assertIn('source "$HOME/.cascade/aliases.sh" --load', shell_config)
        self.assertEqual((runtime_dir / ".install-source").read_text().strip(), str(REPO_ROOT))

    def test_install_removes_legacy_cascade_alias_from_shell_config(self):
        temp_home = tempfile.mkdtemp(prefix="cascade-home-legacy-")
        self.addCleanup(lambda: shutil.rmtree(temp_home, ignore_errors=True))
        (Path(temp_home) / ".zshrc").write_text("alias cascade='~/.cascade/help.sh'\n")

        self.run_command("bash", "install.sh", env={"HOME": temp_home})

        shell_config = (Path(temp_home) / ".zshrc").read_text()
        self.assertNotIn("alias cascade='~/.cascade/help.sh'", shell_config)
        self.assertIn('source "$HOME/.cascade/aliases.sh" --load', shell_config)

    def test_router_core_maps_local_models(self):
        quick = self.run_command(
            "bash",
            "-lc",
            "source scripts/lib/router_core.sh && local_model_for_task quick",
        )
        code = self.run_command(
            "bash",
            "-lc",
            "source scripts/lib/router_core.sh && local_model_for_task code",
        )
        reason = self.run_command(
            "bash",
            "-lc",
            "source scripts/lib/router_core.sh && local_model_for_task reason",
        )

        self.assertIn("ollama_chat/qwen3:4b", quick.stdout.strip())
        self.assertIn("ollama_chat/qwen3-coder", code.stdout.strip())
        self.assertIn("ollama_chat/deepseek-r1:8b", reason.stdout.strip())

    def test_help_output_lists_official_commands(self):
        result = self.run_command("bash", "scripts/help.sh", "help")

        for command_name in ['cascade "zadanie"', 'cascade run "zadanie"', 'think "zadanie"', 'quick "zadanie"', "heal", "cascade start", "cascade sync"]:
            self.assertIn(command_name, result.stdout)


if __name__ == "__main__":
    unittest.main()
