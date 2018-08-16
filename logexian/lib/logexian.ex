defmodule ParserHelpers do
  import NimbleParsec

  def ignore_spaces(c \\ empty()) do
    c
    |> ignore(
      choice([string(" "), string("\n")])
      |> repeat()
    )
  end

  def join(c, joiner) do
    repeat(
      c
      |> ignore_spaces()
      |> ignore(joiner)
      |> ignore_spaces()
    )
    |> concat(c)
  end

  def space_join(c) do
    c
    |> repeat(
      ignore(times(string(" "), min: 1))
      |> concat(c)
    )
  end

  def comma_join(c), do: join(c, string(","))

  def strings(ss), do: for(s <- ss, do: string(s))
end

defmodule Logexian do
  @moduledoc """
  Documentation for Logexian.
  """
  import NimbleParsec
  import ParserHelpers

  space = string(" ")
  newline = string("\n")

  where =
    ignore(repeat(newline))
    |> string(";;\n")
    |> ignore(repeat(newline))

  identifier = ascii_string([?a..?z], min: 1)

  log_and = choice(strings(["and", "∧"]))
  log_or = choice(strings(["or", "∨"]))
  log_op = choice([log_and, log_or])

  variable = choice([integer(min: 1), identifier])
  domain = ascii_string([?A..?Z, ?a..?z], min: 1)

  relation =
    choice(
      strings([
        "==",
        "!=",
        ">",
        "<",
        ">=",
        "<=",
        ":"
      ])
    )

  entailment = choice(strings(["=", "->"]))
  symbol = choice([log_op, relation, variable, domain])

  expression =
    optional(unwrap_and_tag(log_op, :intro_op) |> ignore(times(space, min: 1)))
    |> optional(
      tag(space_join(symbol), :left)
      |> ignore(times(space, min: 1))
      |> unwrap_and_tag(entailment, :op)
      |> ignore(times(space, min: 1))
    )
    |> tag(space_join(symbol), :right)
    |> ignore(repeat(space))
    |> tag(:expr)

  decl_args =
    tag(comma_join(identifier), :decl_args)
    |> ignore(repeat(space))
    |> ignore(string(":"))
    |> ignore(repeat(space))
    |> concat(tag(comma_join(domain), :decl_doms))

  decl_yields =
    ignore(repeat(space))
    |> choice(strings(["::", "=>"]))
    |> unwrap_and_tag(:yield_type)
    |> ignore(repeat(space))
    |> concat(unwrap_and_tag(domain, :yield_domain))

  decl =
    identifier
    |> unwrap_and_tag(:decl_ident)
    |> ignore(repeat(space) |> string("<") |> repeat(space))
    |> optional(
      decl_args
      |> optional(
        ignore(times(space, min: 1))
        |> ignore(log_and)
        |> ignore(times(space, min: 1))
        |> concat(comma_join(expression))
      )
    )
    |> ignore(repeat(space) |> string(">") |> repeat(space))
    |> concat(optional(decl_yields))
    |> tag(:decl)

  section =
    decl
    |> repeat(
      ignore(times(newline, min: 1))
      |> concat(expression)
    )
    |> tag(:sect)

  defparsec(
    :program,
    empty()
    |> ignore_spaces()
    |> concat(join(section, where))
    |> ignore_spaces()
  )
end
