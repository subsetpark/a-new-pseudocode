defmodule ExpressionParserTest do
  use ExUnit.Case

  defp tryexp(text, r) do
    {:ok, exp, "", %{}, _, _} = Pantagruel.Parse.expression(text)
    assert r == exp
  end

  describe "applications" do
    test "parse symbol" do
      text = "x"
      tryexp(text, ["x"])
    end

    test "parse symbol sequence" do
      text = "x y z"
      tryexp(text, appl: [f: {:appl, [f: "x", x: "y"]}, x: "z"])
    end

    test "parse par symbol sequence" do
      text = "(x y z)"
      tryexp(text, par: [appl: [f: {:appl, [f: "x", x: "y"]}, x: "z"]])
    end

    test "parse set symbol sequence" do
      text = "{x y z}"
      tryexp(text, set: [appl: [f: {:appl, [f: "x", x: "y"]}, x: "z"]])
    end

    test "parse bracketed set symbol sequence" do
      text = "(x,{y z})"
      tryexp(text, par: ["x", set: [{:appl, [f: "y", x: "z"]}]])
    end

    test "parse string followed by integer" do
      text = ~s({D} 10)
      tryexp(text, [{:appl, [f: {:set, ["D"]}, x: 10]}])
    end

    test "function application with float" do
      text = "f 1.0"

      expected = [
        appl: [
          f: "f",
          x: 1.0
        ]
      ]

      tryexp(text, expected)
    end

    test "insert operator" do
      text = "+\\[1,2,3]=6"

      expected = [
        appl: [
          operator: :equals,
          x:
            {:appl,
             [
               operator: :insert,
               x: :plus,
               y: {:list, [1, 2, 3]}
             ]},
          y: 6
        ]
      ]

      tryexp(text, expected)
    end
  end

  describe "comprehensions" do
    test "comprehension parsing" do
      text = "{x∈X⸳x * 2}"

      comprehension_elements = [
        [appl: [operator: :from, x: "x", y: "X"]],
        appl: [operator: :times, x: "x", y: 2]
      ]

      tryexp(text,
        comprehension: [set: comprehension_elements]
      )
    end

    test "comprehension parsing 2 elements" do
      text = "{x∈X,y∈Y⸳x * y}"

      comprehension_elements = [
        [
          appl: [operator: :from, x: "x", y: "X"],
          appl: [operator: :from, x: "y", y: "Y"]
        ],
        appl: [operator: :times, x: "x", y: "y"]
      ]

      [
        [appl: [operator: :from, x: "x", y: "X"]],
        [appl: [operator: :from, x: "y", y: "Y"]],
        [appl: [operator: :times, x: "x", y: "y"]]
      ]

      tryexp(text,
        comprehension: [set: comprehension_elements]
      )
    end

    test "comprehension parsing 3 elements" do
      text = "{x∈X,y∈Y,z∈Z⸳x * y ^ z}"

      comprehension_elements = [
        set: [
          [
            appl: [operator: :from, x: "x", y: "X"],
            appl: [operator: :from, x: "y", y: "Y"],
            appl: [operator: :from, x: "z", y: "Z"]
          ],
          appl: [operator: :exp, x: {:appl, [operator: :times, x: "x", y: "y"]}, y: "z"]
        ]
      ]

      tryexp(text,
        comprehension: comprehension_elements
      )
    end

    test "exists quantifier parsing" do
      text = "∃x:X⸳x>1"

      tryexp(text,
        quantifier: [
          quant_operator: :exists,
          quant_bindings: [{:appl, [operator: :in, x: "x", y: "X"]}],
          quant_expression: {:appl, [operator: :gt, x: "x", y: 1]}
        ]
      )
    end
  end

  describe "values" do
    test "empty set" do
      text = "{}"
      tryexp(text, set: [])
    end

    test "literal" do
      text = "`foo"
      tryexp(text, literal: "foo")
    end

    test "spaced literal" do
      text = "`foo 0 Bar`"
      tryexp(text, literal: "foo 0 Bar")
    end

    test "float" do
      text = "1.5"
      tryexp(text, [1.5])
    end

    test "negative float" do
      text = "-1.5"
      tryexp(text, [-1.5])
    end

    test "application parsing" do
      text = "x X"
      tryexp(text, [{:appl, [f: "x", x: "X"]}])
    end

    test "operator parsing" do
      text = "x∈X"
      tryexp(text, [{:appl, [operator: :from, x: "x", y: "X"]}])
    end

    test "unary operator" do
      text = "#x"
      expected = [appl: [operator: :card, x: "x"]]
      tryexp(text, expected)
    end

    test "cardinality testing" do
      text = "#x > 3"
      text2 = "# x > 3"
      expected = [appl: [operator: :gt, x: {:appl, [operator: :card, x: "x"]}, y: 3]]

      tryexp(text, expected)
      tryexp(text2, expected)
    end

    test "lambda with comma-joined domain" do
      text = "|x:(Y,Z)|"

      expected = [
        lambda: [
          lambda_args: ["x"],
          lambda_doms: [par: ["Y", "Z"]]
        ]
      ]

      tryexp(text, expected)
    end

    test "insert" do
      text = "\\"
      expected = [:insert]

      tryexp(text, expected)
    end
  end

  describe "objects" do
    test "object access with string splitting" do
      text = "obj.foo"

      expected = [
        appl: [
          f: ".foo",
          x: "obj"
        ]
      ]

      tryexp(text, expected)
    end

    test "object access chaining" do
      text = "foo.bar.baz"

      expected = [
        appl: [
          f: ".baz",
          x: {:appl, [f: ".bar", x: "foo"]}
        ]
      ]

      tryexp(text, expected)
    end

    test "object access chaining with an operator" do
      text = "f foo.bar.baz > 1"

      chain = {:appl, [f: ".baz", x: {:appl, [f: ".bar", x: "foo"]}]}
      left_side = {:appl, [f: "f", x: chain]}
      right_side = 1

      expected = [
        appl: [
          operator: :gt,
          x: left_side,
          y: right_side
        ]
      ]

      tryexp(text, expected)
    end

    test "object access is treated as special case of function application" do
      text = "(x - 1).foo"

      expected = [
        appl: [
          f: ".foo",
          x: {:par, [appl: [operator: :minus, x: "x", y: 1]]}
        ]
      ]

      tryexp(text, expected)
    end
  end
end
