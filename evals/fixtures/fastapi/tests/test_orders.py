import unittest

from app.services.orders import order_total_label


class OrderTotalLabelTest(unittest.TestCase):
    def test_sums_lines(self) -> None:
        self.assertEqual(order_total_label([(1000, 2), (500, 1)]), "Order total: $25.00")
