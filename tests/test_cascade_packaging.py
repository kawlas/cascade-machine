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
            "alias quick='aider --model ollama_chat/qwen3:4b --auto-commits --yes'",
            "alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'",
            "alias think='aider --model ollama_chat/deepseek-r1:8b --auto-commits --yes'",
            "alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'",
            "alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'",
        ]

        for alias_line in expected_aliases:
            self.assertIn(alias_line, content)

    def test_install_creates_runtime_layout_in_clean_home(self):
        temp_home = tempfile.mkdtemp(prefix="cascade-home-")
        self.addCleanup(lambda: shutil.rmtree(temp_home, ignore_errors=True))

        self.run_command("bash", "install.sh", "--force", env={"HOME": temp_home})

        runtime_dir = Path(temp_home) / ".cascade"
        expected_paths = [
            runtime_dir / "heal.sh",
            runtime_dir / "help.sh",
            runtime_dir / "router.sh",
            runtime_dir / "docs" / "INSTALL.md",
            runtime_dir / "docs" / "COMMANDS.md",
            runtime_dir / ".env",
            runtime_dir / ".env.cascade",
            Path(temp_home) / ".bashrc",
        ]

        for path in expected_paths:
            self.assertTrue(path.exists(), f"missing installed path: {path}")

    def test_router_uses_available_local_models(self):
        quick = self.run_command(
            "bash",
            "scripts/router.sh",
            "best",
            "fix typo in README",
        )
        reason = self.run_command(
            "bash",
            "scripts/router.sh",
            "best",
            "explain this bug in auth middleware",
        )

        self.assertIn("ollama_chat/qwen3:4b", quick.stdout.strip())
        self.assertIn("ollama_chat/deepseek-r1:8b", reason.stdout.strip())

    def test_help_output_lists_official_commands(self):
        result = self.run_command("bash", "scripts/help.sh", "help")

        for command_name in ["quick", "fast", "think", "cloud", "smart", "heal"]:
            self.assertIn(command_name, result.stdout)


if __name__ == "__main__":
    unittest.main()
