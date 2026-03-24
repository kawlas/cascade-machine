import json
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PARSER_PATH = REPO_ROOT / "scripts" / "lib" / "catalog_parser.py"


class CatalogParserTests(unittest.TestCase):
    def write_payload(self, payload):
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        payload_path = Path(temp_dir.name) / "payload.json"
        payload_path.write_text(json.dumps(payload), encoding="utf-8")
        return payload_path

    def load_module(self):
        import importlib.util

        spec = importlib.util.spec_from_file_location("catalog_parser", PARSER_PATH)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_openrouter_marks_zero_price_models_as_free(self):
        module = self.load_module()
        payload_path = self.write_payload(
            {
                "data": [
                    {
                        "id": "deepseek/deepseek-chat:free",
                        "pricing": {"prompt": "0", "completion": "0"},
                        "context_length": 128000,
                    }
                ]
            }
        )

        records = module.parse_payload("openrouter", "openrouter", "prepaid", "", "OPENROUTER_API_KEY", module.load_payload(payload_path))

        self.assertEqual(1, len(records))
        self.assertIn("\tfree\t128000\t", records[0])
        self.assertTrue(records[0].startswith("openrouter\topenrouter/deepseek/deepseek-chat:free\topenrouter/deepseek/deepseek-chat:free"))

    def test_gemini_keeps_only_generate_content_models(self):
        module = self.load_module()
        payload_path = self.write_payload(
            {
                "models": [
                    {
                        "name": "models/gemini-2.0-flash",
                        "supportedGenerationMethods": ["generateContent"],
                        "inputTokenLimit": 1048576,
                    },
                    {
                        "name": "models/embedding-001",
                        "supportedGenerationMethods": ["embedContent"],
                    },
                ]
            }
        )

        records = module.parse_payload("gemini", "gemini", "free", "", "GEMINI_API_KEY", module.load_payload(payload_path))

        self.assertEqual(1, len(records))
        self.assertIn("gemini/gemini-2.0-flash", records[0])
        self.assertIn("\t1048576\t", records[0])

    def test_custom_openai_provider_maps_to_openai_runtime_model(self):
        module = self.load_module()
        payload_path = self.write_payload({"data": [{"id": "devstral-medium", "context_window": 131072}]})

        records = module.parse_payload("chutes", "openai", "prepaid", "https://llm.chutes.ai/v1", "CHUTES_API_KEY", module.load_payload(payload_path))

        self.assertEqual(
            "chutes\tchutes/devstral-medium\topenai/devstral-medium\tprepaid\t131072\thttps://llm.chutes.ai/v1\tCHUTES_API_KEY",
            records[0],
        )


if __name__ == "__main__":
    unittest.main()
