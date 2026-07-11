import json
import tempfile
import unittest
from pathlib import Path

import flutter_architecture_audit as audit


class FlutterArchitectureAuditTest(unittest.TestCase):
    def test_detects_oversized_and_multi_class_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bad.dart").write_text(
                "class First {}\nclass Second extends CustomPainter {}\n"
                + "// padding\n" * audit.MAX_LINES,
                encoding="utf-8",
            )
            found = audit.violations(audit.scan(root))["bad.dart"]
            self.assertGreater(found["lines"], audit.MAX_LINES)
            self.assertEqual(found["declarations"], 2)
            self.assertEqual(found["embedded_special_declarations"], 1)

    def test_single_painter_file_is_compliant(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "curve_painter.dart").write_text(
                "class CurvePainter extends CustomPainter {}\n", encoding="utf-8"
            )
            self.assertEqual(audit.violations(audit.scan(root)), {})

    def test_baseline_allows_reduction_but_rejects_growth(self):
        baseline = {"legacy.dart": {"declarations": 3, "lines": 700}}
        reduced = {"legacy.dart": {"declarations": 2, "lines": 600}}
        grown = {"legacy.dart": {"declarations": 4, "lines": 701}}
        self.assertEqual(audit.regressions(reduced, baseline), [])
        self.assertEqual(len(audit.regressions(grown, baseline)), 2)

    def test_new_central_registration_fails(self):
        current = {"new.dart": {"central_registrations": 1}}
        self.assertEqual(
            audit.regressions(current, {}),
            ["new.dart: central_registrations=1, baseline=0"],
        )


if __name__ == "__main__":
    unittest.main()
