#!/usr/bin/env python3

import yaml
import jsonschema
import textwrap
import unittest


class TestMinimumMaximum(unittest.TestCase):
    SCHEMA = textwrap.dedent("""
    type: object
    required: [specification]
    properties:
      specification:
        type: object
        properties:
          advanced:
            type: object
            properties:
              certificates:
                type: object
                properties:
                  expiration_days:
                    type: integer
                    minimum: 1
                    maximum: 24855
    """)

    DOCUMENT1 = textwrap.dedent("""
    specification:
      advanced:
        certificates:
          location: /etc/kubernetes/pki
          expiration_days: {expiration_days}
          renew: true
    """)

    def _validate_DOCUMENT1(self, expiration_days):
        jsonschema.validate(
            instance=yaml.load(self.DOCUMENT1.format(expiration_days=expiration_days), Loader=yaml.SafeLoader),
            schema=yaml.load(self.SCHEMA, Loader=yaml.SafeLoader),
        )

    def test_DOCUMENT1_with_100_000(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT1(100_000)

    def test_DOCUMENT1_with_0(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT1(0)

    def test_DOCUMENT1_with_8686(self):
        self._validate_DOCUMENT1(8686)


class TestIfThenElse(unittest.TestCase):
    SCHEMA = textwrap.dedent("""
    type: object
    required:
      - components
    properties:
      components:
        type: object
        dependencies:
          kubernetes_node:
            - kubernetes_master
        allOf:
          - if:
              properties:
                kubernetes_master:
                  properties:
                    count:
                      maximum: 0
            then:
              properties:
                kubernetes_node:
                  properties:
                    count:
                      maximum: 0
    """)

    DOCUMENT1 = textwrap.dedent("""
    components:
      kubernetes_node:
        count: {node_count}
    """)

    DOCUMENT2 = textwrap.dedent("""
    components:
      kubernetes_master:
        count: {master_count}
      kubernetes_node:
        count: {node_count}
    """)

    def _validate_DOCUMENT1(self, node_count):
        jsonschema.validate(
            instance=yaml.load(self.DOCUMENT1.format(node_count=node_count), Loader=yaml.SafeLoader),
            schema=yaml.load(self.SCHEMA, Loader=yaml.SafeLoader),
        )

    def _validate_DOCUMENT2(self, master_count, node_count):
        jsonschema.validate(
            instance=yaml.load(self.DOCUMENT2.format(master_count=master_count, node_count=node_count), Loader=yaml.SafeLoader),
            schema=yaml.load(self.SCHEMA, Loader=yaml.SafeLoader),
        )

    def test_DOCUMENT1_with_0(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT1(0)

    def test_DOCUMENT1_with_1(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT1(1)

    def test_DOCUMENT2_with_0_0(self):
        self._validate_DOCUMENT2(0, 0)

    def test_DOCUMENT2_with_1_0(self):
        self._validate_DOCUMENT2(1, 0)

    def test_DOCUMENT2_with_2_0(self):
        self._validate_DOCUMENT2(2, 0)

    def test_DOCUMENT2_with_1_1(self):
        self._validate_DOCUMENT2(1, 1)

    def test_DOCUMENT2_with_2_2(self):
        self._validate_DOCUMENT2(2, 2)

    def test_DOCUMENT2_with_0_1(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT2(0, 1)

    def test_DOCUMENT2_with_0_2(self):
        with self.assertRaises(jsonschema.exceptions.ValidationError):
            self._validate_DOCUMENT2(0, 2)


if __name__ == "__main__":
    unittest.main()
