#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("qmllint_gate.py")
SPEC = importlib.util.spec_from_file_location("qmllint_gate", MODULE_PATH)
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)


class QmlLintGateTest(unittest.TestCase):
    def test_accepts_declared_plasmoid_configuration_property(self):
        warning = {
            "id": "missing-property",
            "line": 1,
            "message": 'Member "interval" not found on type "KConfigPropertyMap"',
        }
        self.assertTrue(gate.allowed_dynamic_property(
            warning, "const value = Plasmoid.configuration.interval", {"interval"}))

    def test_rejects_typo_not_declared_in_schema(self):
        warning = {
            "id": "missing-property",
            "line": 1,
            "message": 'Member "intervall" not found on type "KConfigPropertyMap"',
        }
        self.assertFalse(gate.allowed_dynamic_property(
            warning, "const value = Plasmoid.configuration.intervall", {"interval"}))

    def test_rejects_same_name_outside_plasmoid_configuration(self):
        warning = {
            "id": "missing-property",
            "line": 1,
            "message": 'Member "interval" not found on type "KConfigPropertyMap"',
        }
        self.assertFalse(gate.allowed_dynamic_property(
            warning, "const value = another.configuration.interval", {"interval"}))

    def test_rejects_every_other_warning_category(self):
        warning = {
            "id": "incompatible-type",
            "line": 1,
            "message": "Incompatible type",
        }
        self.assertFalse(gate.allowed_dynamic_property(
            warning, "const value = Plasmoid.configuration.interval", {"interval"}))


if __name__ == "__main__":
    unittest.main()
