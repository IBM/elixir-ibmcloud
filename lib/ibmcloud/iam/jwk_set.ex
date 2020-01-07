defmodule IBMCloud.IAM.JWKSet do
  @moduledoc """
  Interfaces to JWK Set.

  - [RFC 7517 - JSON Web Key (JWK) - 5. JWK Set Format](https://tools.ietf.org/html/rfc7517#section-5)
  """

  defstruct by_alg_kid: %{}

  alias JOSE.{JWK, JWS, JWT}

  def from(keys) when is_list(keys), do: from_enum(keys)

  def from(json_string) when is_binary(json_string),
    do: json_string |> Jason.decode!() |> Map.fetch!("keys") |> from_enum()

  def from(%{"keys" => keys}), do: from_enum(keys)

  defp from_enum(keys) do
    by_alg_kid =
      keys
      |> Enum.map(&JWK.from/1)
      |> Enum.map(fn k = %JWK{fields: %{"alg" => alg, "kid" => kid}} -> {{alg, kid}, k} end)
      |> Enum.into(%{})

    %__MODULE__{by_alg_kid: by_alg_kid}
  end

  defp get_key(%__MODULE__{by_alg_kid: by_alg_kid}, alg, kid),
    do: Map.fetch(by_alg_kid, {alg, kid})

  @doc """
  Verify a token.

  ```elixir
  jwks = IBMCloud.IAM.JWKSet.from(jwks_json)
  token = "..."
  {:ok, %{"sub" => sub}} = IBMCloud.IAM.JWKSet.verify(jwks, token)
  ```
  """
  def verify(jwk_set, signed) do
    %JWS{alg: {_, alg_atom}, fields: %{"kid" => kid}} = JWT.peek_protected(signed)

    case get_key(jwk_set, Atom.to_string(alg_atom), kid) do
      {:ok, key} -> verify_signature(key, signed)
      :error -> {:error, :unknown_alg_kid}
    end
  end

  defp verify_signature(key, signed) do
    case JWS.verify(key, signed) do
      {true, payload, _jws} -> {:ok, Jason.decode!(payload)}
      {false, _payload, _jws} -> {:error, :invalid}
      {:error, error} -> {:error, error}
    end
  end
end
