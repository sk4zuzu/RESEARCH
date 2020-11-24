#!/usr/bin/env python3

import sys
import copy
import unittest

import string
import textwrap

import yaml
import jsonschema
import jmespath


def group_dictify(a_list, *, group_by="kind", select_by="name"):
    items = copy.deepcopy(a_list)

    groups = {
        item[group_by]
        for item in items
    }

    return {
        group: {
            item[select_by]: item
            for item in items
            if item[group_by] == group
        }
        for group in groups
    }


class TestDictifyPerGroup(unittest.TestCase):
    INPUT1 = textwrap.dedent("""
    ---
    kind: cluster
    name: env1
    spec:
      app1:
        vm: vm1
      app2:
        vm: vm2
    ---
    kind: infra/vm
    name: vm1
    spec:
      os: ubuntu
    ---
    kind: infra/vm
    name: vm2
    spec:
      os: redhat
    """)

    OUTPUT1 = textwrap.dedent("""
    "cluster":
      "env1":
        kind: "cluster"
        name: "env1"
        spec:
          app1:
            vm: "vm1"
          app2:
            vm: "vm2"
    "infra/vm":
      "vm1":
        kind: "infra/vm"
        name: "vm1"
        spec:
          os: ubuntu
      "vm2":
        kind: "infra/vm"
        name: "vm2"
        spec:
          os: redhat
    """)

    def test_group_dictify(self):
        self.assertEqual(
            group_dictify(
                list(yaml.load_all(self.INPUT1, Loader=yaml.SafeLoader))
            ),
            yaml.load(self.OUTPUT1, Loader=yaml.SafeLoader),
        )


def nested_jmespath(expression, data, options=None):

    def _replace(value, start_token="{{", end_token="}}"):  # go "horizontal"
        start = 0

        for guard in range(16, -1, -1):
            start = value.find(start_token, start)
            if start == -1:
                break

            end = value.find(end_token, start + len(start_token))
            if end == -1:
                break

            key = value[start + len(start_token) : end]

            value = value[:start] + jmespath.search(key.strip(), data, options=options) + value[end + len(end_token):]

            start = end + len(end_token)

        if guard == 0:
            raise ValueError('Too many steps while replacing properties.')

        return value

    return jmespath.search(_replace(expression), data, options=options)


class TestNestedJmesPath(unittest.TestCase):

    DATA1 = textwrap.dedent("""
    aaa:
      xxx: yyy
    bbb:
      yyy: zzz
    """)

    EXPR1 = textwrap.dedent("""
    bbb.{{ aaa.xxx }}
    """)

    OUTPUT1 = "zzz"

    def test_nested_jmespath(self):
        self.assertEqual(
            nested_jmespath(
                yaml.load(self.EXPR1, Loader=yaml.SafeLoader),
                yaml.load(self.DATA1, Loader=yaml.SafeLoader),
            ),
            self.OUTPUT1,
        )


OP = {
    "all": { "n": 0, "x": lambda *a: all(a) },
    "any": { "n": 0, "x": lambda *a: any(a) },
    "not": { "n": 1, "x": lambda a: not a },
    "and": { "n": 2, "x": lambda a: lambda b: a and b },
    "or": { "n": 2, "x": lambda a: lambda b: a or b },
    "->": { "n": 2, "x": lambda a: lambda b: not a or b }, # implication
    "lt": { "n": 2, "x": lambda a: lambda b: a < b },
    "le": { "n": 2, "x": lambda a: lambda b: a <= b },
    "eq": { "n": 2, "x": lambda a: lambda b: a == b },
    "ne": { "n": 2, "x": lambda a: lambda b: a != b },
    "ge": { "n": 2, "x": lambda a: lambda b: a >= b },
    "gt": { "n": 2, "x": lambda a: lambda b: a > b },
    "?:": { "n": 3, "x": lambda a: lambda b: lambda c: b if a else c }, # ternary
}


def evaluate_pn(pn_expression, data=None, debug=False):
    if pn_expression is None:
        raise ValueError("Invalid expression")

    def _recurse(something):
        if debug:
            print(something, file=sys.stderr)

        if isinstance(something, dict):
            key, value = next(iter(something.items()))

            if key == "jmespath":
                return nested_jmespath(value, data)

            op = OP[key]

            if op["n"] == 0:
                return op["x"] (*[
                    _recurse(item)
                    for item in value
                ])

            if op["n"] == 1:
                return op["x"] (_recurse(value))

            if op["n"] == 2:
                return op["x"] (_recurse(value[0])) (_recurse(value[1]))

            if op["n"] == 3:
                return op["x"] (_recurse(value[0])) (_recurse(value[1])) (_recurse(value[2]))

        return something

    return _recurse(pn_expression)


class TestEvaluatePN(unittest.TestCase):
    def test_OP(self):
        self.assertTrue(OP["all"]["x"](True,True,True))
        self.assertFalse(OP["all"]["x"](True,False,True))

        self.assertTrue(OP["any"]["x"](False,True,False))
        self.assertFalse(OP["any"]["x"](False,False,False))

        self.assertTrue(OP["not"]["x"](False))
        self.assertFalse(OP["not"]["x"](True))

        self.assertTrue(OP["and"]["x"](True)(True))
        self.assertFalse(OP["and"]["x"](False)(True))
        self.assertFalse(OP["and"]["x"](True)(False))
        self.assertFalse(OP["and"]["x"](False)(False))

        self.assertTrue(OP["or"]["x"](True)(True))
        self.assertTrue(OP["or"]["x"](False)(True))
        self.assertTrue(OP["or"]["x"](True)(False))
        self.assertFalse(OP["or"]["x"](False)(False))

        self.assertTrue(OP["->"]["x"](True)(True))
        self.assertFalse(OP["->"]["x"](True)(False))
        self.assertTrue(OP["->"]["x"](False)(True))
        self.assertTrue(OP["->"]["x"](False)(False))

        self.assertTrue(OP["lt"]["x"](1)(2))
        self.assertFalse(OP["lt"]["x"](1)(1))
        self.assertFalse(OP["lt"]["x"](2)(1))

        self.assertTrue(OP["le"]["x"](1)(2))
        self.assertTrue(OP["le"]["x"](1)(1))
        self.assertFalse(OP["le"]["x"](2)(1))

        self.assertTrue(OP["eq"]["x"](1)(1))
        self.assertFalse(OP["eq"]["x"](2)(1))

        self.assertFalse(OP["ne"]["x"](1)(1))
        self.assertTrue(OP["ne"]["x"](2)(1))

        self.assertTrue(OP["ge"]["x"](2)(1))
        self.assertTrue(OP["ge"]["x"](1)(1))
        self.assertFalse(OP["ge"]["x"](1)(2))

        self.assertTrue(OP["gt"]["x"](2)(1))
        self.assertFalse(OP["gt"]["x"](1)(1))
        self.assertFalse(OP["gt"]["x"](1)(2))

        self.assertTrue(OP["?:"]["x"](True)(True)(False))
        self.assertTrue(OP["?:"]["x"](False)(False)(True))
        self.assertFalse(OP["?:"]["x"](True)(False)(True))
        self.assertFalse(OP["?:"]["x"](False)(True)(False))

    EXPR1 = textwrap.dedent("""
    all:
      - true
      - not: false
      - gt: [2, 1]
      - "->": [false, false]
      - "?:": [true, true, false]
      - any:
          - not: true
          - "?:": [false, true, {eq: ["a", "a"]}]
    """)

    def test_EXPR1(self):
        self.assertTrue(
            evaluate_pn(yaml.load(self.EXPR1, Loader=yaml.SafeLoader), debug=True),
        )

    EXPR2 = textwrap.dedent("""
    "?:":
      - gt: ["bcd", "abc"]
      - not: {and: [false, true]}
      - or: [false, false]
    """)

    def test_EXPR2(self):
        self.assertTrue(
            evaluate_pn(yaml.load(self.EXPR2, Loader=yaml.SafeLoader), debug=True),
        )

    EXPR3 = textwrap.dedent("""
    not: null
    """)

    def test_EXPR3(self):
        self.assertTrue(
            evaluate_pn(yaml.load(self.EXPR3, Loader=yaml.SafeLoader), debug=True),
        )

    EXPR4 = textwrap.dedent("""
    null
    """)

    def test_EXPR4(self):
        with self.assertRaises(ValueError):
            evaluate_pn(yaml.load(self.EXPR4, Loader=yaml.SafeLoader), debug=True)

    EXPR5 = textwrap.dedent("""
    lel: [1, 2]
    """)

    def test_EXPR5(self):
        with self.assertRaises(KeyError):
            evaluate_pn(yaml.load(self.EXPR5, Loader=yaml.SafeLoader), debug=True)

    EXPR6 = textwrap.dedent("""
    any:
      - not: true
      - lt:
          - jmespath: 'aaa.xxx'
          - jmespath: 'bbb.yyy'
    """)

    DATA6 = textwrap.dedent("""
    aaa:
      xxx: 1
    bbb:
      yyy: 2
    """)

    def test_EXPR6(self):
        self.assertTrue(
            evaluate_pn(
                yaml.load(self.EXPR6, Loader=yaml.SafeLoader),
                yaml.load(self.DATA6, Loader=yaml.SafeLoader),
                debug=True,
            ),
        )

    INPUT7 = textwrap.dedent("""
    ---
    kind: cluster
    name: env1
    spec:
      app1:
        vm: vm1
      app2:
        vm: vm2
    ---
    kind: infra/vm
    name: vm1
    spec:
      os: ubuntu
    ---
    kind: infra/vm
    name: vm2
    spec:
      os: redhat
    """)

    # OUTPUT7 = textwrap.dedent("""
    # "cluster":
    #   "env1":
    #     kind: "cluster"
    #     name: "env1"
    #     spec:
    #       app1:
    #         vm: "vm1"
    #       app2:
    #         vm: "vm2"
    # "infra/vm":
    #   "vm1":
    #     kind: "infra/vm"
    #     name: "vm1"
    #     spec:
    #       os: ubuntu
    #   "vm2":
    #     kind: "infra/vm"
    #     name: "vm2"
    #     spec:
    #       os: redhat
    # """)

    EXPR7 = textwrap.dedent("""
    all:
      - eq:
          - jmespath: >-
              "infra/vm".{{ cluster.* | [0].spec.app1.vm }}.spec.os
          - ubuntu
      - ne:
          - jmespath: >-
              "infra/vm".{{ cluster.* | [0].spec.app1.vm }}.spec.os
          - jmespath: >-
              "infra/vm".{{ cluster.* | [0].spec.app2.vm }}.spec.os
    """)

    def test_EXPR7(self):
        data = group_dictify(
            list(yaml.load_all(self.INPUT7, Loader=yaml.SafeLoader)),
        )

        self.assertTrue(
            evaluate_pn(
                yaml.load(self.EXPR7, Loader=yaml.SafeLoader),
                data,
                debug=True,
            ),
        )


def validate(schema, data):
    documents = list(yaml.load_all(schema, Loader=yaml.SafeLoader))

    _schema, _expression = documents[0], documents[1]

    jsonschema.validate(
        instance=data,
        schema=_schema,
    )

    return evaluate_pn(_expression, data, debug=True)


class TestValidate(unittest.TestCase):
    INPUT1 = textwrap.dedent("""
    ---
    kind: cluster
    name: env1
    spec:
      app1:
        vm: vm1
      app2:
        vm: vm2
    ---
    kind: infra/vm
    name: vm1
    spec:
      os: redhat
    ---
    kind: infra/vm
    name: vm2
    spec:
      os: redhat
    """)

    SCHEMA1 = textwrap.dedent("""
    type: object
    required:
      - "cluster"
      - "infra/vm"
    properties:
      "cluster":
        type: object
        patternProperties:
          "^[a-z0-9]+$":
            required:
              - spec
    ---
    all:
      - eq:
          - jmespath: >-
              "infra/vm".{{ cluster.* | [0].spec.app1.vm }}.spec.os
          - jmespath: >-
              "infra/vm".{{ cluster.* | [0].spec.app2.vm }}.spec.os
    """)

    def test_INPUT1(self):
        data = group_dictify(
            list(yaml.load_all(self.INPUT1, Loader=yaml.SafeLoader)),
        )

        self.assertTrue(
            validate(self.SCHEMA1, data),
        )

    INPUT2 = textwrap.dedent("""
    ---
    kind: cluster
    name: env1
    spec:
      app1:
        vm: vm1
      app2:
        vm: vm2
    ---
    kind: infra/vm
    name: vm1
    spec:
      os: ubuntu
    ---
    kind: infra/vm
    name: vm2
    spec:
      os: redhat
    """)

    def test_INPUT2(self):
        data = group_dictify(
            list(yaml.load_all(self.INPUT2, Loader=yaml.SafeLoader)),
        )

        self.assertFalse(
            validate(self.SCHEMA1, data),
        )


if __name__ == "__main__":
    unittest.main(verbosity=1)
