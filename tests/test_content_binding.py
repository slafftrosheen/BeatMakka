"""Offline binding safety checks. Never modifies project IDs or contacts Roblox."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("configure_content", ROOT / "tools/configure_content.py")
binding = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(binding)


class ContentBindingTests(unittest.TestCase):
    def setUp(self):
        self.allowed = binding.allowed_content_keys()
        self.base = binding.validate_mapping(binding.read_json(ROOT / "data/content-ids.json"), self.allowed)

    def test_original_and_style_rosters_are_allowed_without_arbitrary_keys(self):
        self.assertEqual(len(self.allowed["Audio"]), 184)
        self.assertIn("style.triphop.01", self.allowed["Audio"])
        self.assertIn("style.trance.16", self.allowed["Audio"])
        with self.assertRaises(ValueError):
            binding.validate_mapping({"Audio": {"style.unknown.01": 1}}, self.allowed)

    def test_empty_audio_update_preserves_all_existing_images(self):
        incoming = binding.validate_mapping({"Audio": {}}, self.allowed)
        merged, changes = binding.merge_mapping(self.base, incoming, False)
        self.assertEqual(merged, self.base)
        self.assertEqual(len(merged["Images"]), 14)
        self.assertEqual(changes["added"], [])

    def test_malformed_and_unknown_mappings_are_rejected(self):
        key = next(iter(self.base["Images"]))
        for bad in [True, False, 0, -1, 1.5, 2 ** 53, "123"]:
            with self.subTest(value=bad), self.assertRaises(ValueError):
                binding.validate_mapping({"Images": {key: bad}}, self.allowed)
        for mapping in [[], {"Other": {}}, {"Images": []}, {"Images": {"unknown": 1}}]:
            with self.subTest(mapping=mapping), self.assertRaises(ValueError):
                binding.validate_mapping(mapping, self.allowed)
        with self.assertRaises(ValueError):
            json.loads('{"Audio":{},"Audio":{}}', object_pairs_hook=binding.unique_object)

    def test_changed_image_id_requires_explicit_rebind(self):
        keys = list(self.base["Images"])
        incoming = {"Audio": {}, "Images": {keys[0]: self.base["Images"][keys[1]]}}
        with self.assertRaises(ValueError):
            binding.merge_mapping(self.base, incoming, False)
        merged, changes = binding.merge_mapping(self.base, incoming, True)
        self.assertEqual(changes["rebound"], ["Images." + keys[0]])
        self.assertEqual(len(merged["Images"]), 14)

    def test_staged_writes_preserve_complete_mapping_in_temporary_files(self):
        with tempfile.TemporaryDirectory(prefix="BeatMaka-binding-qa-") as folder:
            canonical, runtime = Path(folder) / "ids.json", Path(folder) / "ids.luau"
            binding.write_bindings(canonical, runtime, self.base, {canonical: None, runtime: None})
            self.assertEqual(binding.read_json(canonical), self.base)
            self.assertEqual(runtime.read_text(), binding.render_luau(self.base))
            self.assertEqual(sorted(p.name for p in Path(folder).iterdir()), ["ids.json", "ids.luau"])

    def test_concurrent_change_aborts_before_replacing_either_output(self):
        with tempfile.TemporaryDirectory(prefix="BeatMaka-binding-qa-") as folder:
            canonical, runtime = Path(folder) / "ids.json", Path(folder) / "ids.luau"
            canonical.write_bytes(b"changed by another writer")
            runtime.write_bytes(b"preserve runtime")
            with self.assertRaises(ValueError):
                binding.write_bindings(canonical, runtime, self.base,
                                       {canonical: b"original", runtime: b"preserve runtime"})
            self.assertEqual(canonical.read_bytes(), b"changed by another writer")
            self.assertEqual(runtime.read_bytes(), b"preserve runtime")


if __name__ == "__main__":
    unittest.main()
