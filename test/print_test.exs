defmodule Pantagruel.FormatTest do
  use ExUnit.Case
  alias Pantagruel.Format

  defp eval(text) when is_binary(text) do
    text
    |> Pantagruel.Scan.scan()
    |> eval
  end

  defp eval(text) do
    with {:ok, parsed} <-
           :lexer.string(text)
           |> Pantagruel.Parse.handle_lex(),
         {:ok, scope} <- Pantagruel.Eval.eval(parsed, []) do
      {parsed, scope}
    end
  end

  describe "scope display" do
    test "null case" do
      {parsed, scopes} = eval("")
      assert "" == Format.format_program(parsed)
      assert "" == Format.format_scopes(scopes)
    end

    test "minimal function" do
      {parsed, scopes} =
        """
        f()
        """
        |> eval

      assert "f()  " == Format.format_program(parsed)
      assert "f()" == Format.format_scopes(scopes)
    end

    test "minimal function with module name" do
      {parsed, scopes} =
        """
        module TEST
        f()
        """
        |> eval

      assert "# TEST\n\n***\n\nf()  " == Format.format_program(parsed)
      assert "# TEST\nf()" == Format.format_scopes(scopes)
    end

    test "function" do
      {parsed, scopes} =
        """
        f(x: Nat) :: Real
        """
        |> eval

      assert "f(x:ℕ) ∷ ℝ  " == Format.format_program(parsed)
      assert "f(ℕ) ∷ ℝ\nx : ℕ" == Format.format_scopes(scopes)
    end

    test "constructor" do
      {parsed, scopes} =
        """
        f() => F
        """
        |> eval

      assert "f() ⇒ F  " == Format.format_program(parsed)
      assert "f() ⇒ F" == Format.format_scopes(scopes)
    end

    test "aliasing" do
      {parsed, scopes} =
        """
        Status <= {`ok}
        """
        |> eval

      assert "Status ⇐ {*ok*}  " == Format.format_program(parsed)
      assert "Status ⇐ {*ok*}" == Format.format_scopes(scopes)
    end

    test "section" do
      {parsed, scopes} =
        """
        f() => F
        ---
        f 1 <-> 0
        """
        |> eval

      assert "f() ⇒ F  \nf 1 ↔ 0  " == Format.format_program(parsed)
      assert "f() ⇒ F" == Format.format_scopes(scopes)
    end

    test "unary operator" do
      {parsed, scopes} =
        """
        f()
        ---
        ~f
        """
        |> eval

      assert "f()  \n¬f  " == Format.format_program(parsed)
      assert "f()" == Format.format_scopes(scopes)
    end

    test "intro operator" do
      {parsed, scopes} =
        """
        f()
        ---
        and ~f
        """
        |> eval

      assert "f()  \n∧ ¬f  " == Format.format_program(parsed)
      assert "f()" == Format.format_scopes(scopes)
    end

    test "refinement" do
      {parsed, scopes} =
        """
        f()
        ---
        f \\ exists n : Nat \\ n > 1 <- n
        """
        |> eval

      assert "f()  \nf ⸳ ∃ n : ℕ ⸳ n > 1 ← n  " == Format.format_program(parsed)
      assert "f()" == Format.format_scopes(scopes)
    end

    test "refinement error" do
      {:error, {:unbound_variables, e}} =
        """
        f()
        ---
        f \\ exists n : Nat \\ n > 1 <- k
        """
        |> eval

      assert "f ⸳ ∃ *n* : ℕ ⸳ *n* > 1 ← *k*" == Format.format_exp(e.unbound, e.scopes)
    end
  end
end
