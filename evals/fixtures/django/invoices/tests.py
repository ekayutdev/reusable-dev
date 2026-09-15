import unittest

from invoices.services import amount_due_label


class AmountDueLabelTest(unittest.TestCase):
    def test_sums_amounts(self) -> None:
        self.assertEqual(amount_due_label([100, 250]), "Amount due: $3.50")
