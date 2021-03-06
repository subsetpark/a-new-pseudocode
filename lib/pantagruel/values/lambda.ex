defmodule Pantagruel.Values.Lambda do
  @moduledoc """
  A function in an evaluated Pantagruel program, either as introduced
  in a header declaration or referred to as an anonymous function inside
  of a section body.

  The `type` of a lambda is either `:function`, which is a normal
  function from 0 or more arguments with an optional return type, or
  `:constructor`, which defines the construction function for complex
  types such as List[Int] or of objects with named fields.

  The evaluation behavior of constructors is such that they also bind
  their codomain into scope; functions must have their codomains defined
  elsewhere.
  """
  alias Pantagruel.Env
  defstruct name: "", domain: [], codomain: nil, type: nil

  @doc """
  Given a function declaration, build a Lambda struct.
  """
  def from_declaration(decl, doms \\ nil)

  def from_declaration([symbol, bindings, yield_type, codomain], doms) do
    doms = doms || Env.args_and_domains(bindings) |> elem(1)

    %__MODULE__{
      name: symbol,
      domain: doms,
      codomain: codomain,
      type: yield_type
    }
  end

  def from_declaration(decl, doms), do: from_declaration([nil | decl], doms)
end
