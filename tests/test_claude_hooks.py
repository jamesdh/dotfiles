"""Unit tests for library/claude_hooks.py (pure merge logic, no Ansible runtime).

Run with: make test
"""
import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parent.parent / "library" / "claude_hooks.py"
spec = importlib.util.spec_from_file_location("claude_hooks", MODULE_PATH)
claude_hooks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(claude_hooks)
merge_hooks = claude_hooks.merge_hooks


def group(*commands, matcher=None):
    g = {"hooks": [{"type": "command", "command": c} for c in commands]}
    if matcher is not None:
        g["matcher"] = matcher
    return g


GRRR = {
    "Stop": [group("grrr hook notify --appId Demo")],
    "UserPromptSubmit": [group("grrr hook dismiss --appId Demo")],
}
SIDEBAND_PROMPT = group('"/opt/homebrew/bin/sideband" hook prompt --agent claude')
SIDEBAND_START = group('"/opt/homebrew/bin/sideband" hook session-start --agent claude', matcher="clear")


class MergeHooksTest(unittest.TestCase):
    def test_empty_settings_gets_all_hooks(self):
        merged, changed = merge_hooks({}, GRRR, None)
        self.assertTrue(changed)
        self.assertEqual(merged, {"hooks": GRRR})

    def test_second_run_is_unchanged(self):
        merged, changed = merge_hooks({"hooks": GRRR}, GRRR, None)
        self.assertFalse(changed)
        self.assertEqual(merged, {"hooks": GRRR})

    def test_preserves_foreign_hooks_and_root_keys(self):
        existing = {
            "permissions": {"allow": ["Bash(ls:*)"]},
            "hooks": {
                "UserPromptSubmit": [SIDEBAND_PROMPT],
                "SessionStart": [SIDEBAND_START],
            },
        }
        merged, changed = merge_hooks(existing, GRRR, None)
        self.assertTrue(changed)
        self.assertEqual(merged["permissions"], {"allow": ["Bash(ls:*)"]})
        self.assertEqual(merged["hooks"]["SessionStart"], [SIDEBAND_START])
        self.assertEqual(
            merged["hooks"]["UserPromptSubmit"],
            [SIDEBAND_PROMPT, group("grrr hook dismiss --appId Demo")],
        )
        self.assertEqual(merged["hooks"]["Stop"], GRRR["Stop"])

    def test_partial_install_gets_missing_event(self):
        existing = {"hooks": {"Stop": GRRR["Stop"]}}
        merged, changed = merge_hooks(existing, GRRR, None)
        self.assertTrue(changed)
        self.assertEqual(merged["hooks"], GRRR)

    def test_replace_drops_stale_owned_groups_only(self):
        existing = {
            "hooks": {
                "Stop": [group("grrr hook notify --appId Old")],
                "UserPromptSubmit": [SIDEBAND_PROMPT, group("grrr hook dismiss --appId Old")],
            }
        }
        merged, changed = merge_hooks(existing, GRRR, r"^grrr hook ")
        self.assertTrue(changed)
        self.assertEqual(merged["hooks"]["Stop"], GRRR["Stop"])
        self.assertEqual(
            merged["hooks"]["UserPromptSubmit"],
            [SIDEBAND_PROMPT, group("grrr hook dismiss --appId Demo")],
        )

    def test_replace_does_not_touch_events_it_does_not_own(self):
        existing = {"hooks": {"SessionStart": [SIDEBAND_START]}}
        merged, changed = merge_hooks(existing, GRRR, r"^grrr hook ")
        self.assertTrue(changed)
        self.assertEqual(merged["hooks"]["SessionStart"], [SIDEBAND_START])

    def test_replace_with_matching_current_hooks_is_stable(self):
        existing = {"hooks": dict(GRRR)}
        merged, changed = merge_hooks(existing, GRRR, r"^grrr hook ")
        self.assertFalse(changed)
        self.assertEqual(merged["hooks"], GRRR)

    def test_replace_keeps_order_when_nothing_is_stale(self):
        existing = {"hooks": {"UserPromptSubmit": [group("grrr hook dismiss --appId Demo"), SIDEBAND_PROMPT]}}
        merged, changed = merge_hooks(existing, {"UserPromptSubmit": GRRR["UserPromptSubmit"]}, r"^grrr hook ")
        self.assertFalse(changed)
        self.assertEqual(merged, existing)

    def test_input_is_not_mutated(self):
        existing = {"hooks": {"Stop": [group("grrr hook notify --appId Old")]}}
        snapshot = {"hooks": {"Stop": [group("grrr hook notify --appId Old")]}}
        merge_hooks(existing, GRRR, r"^grrr hook ")
        self.assertEqual(existing, snapshot)

    def test_rejects_non_object_hooks_key(self):
        with self.assertRaises(claude_hooks.HooksFormatError):
            merge_hooks({"hooks": []}, GRRR, None)

    def test_rejects_non_list_event(self):
        with self.assertRaises(claude_hooks.HooksFormatError):
            merge_hooks({"hooks": {"Stop": {}}}, GRRR, None)


if __name__ == "__main__":
    unittest.main()
