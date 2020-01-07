defmodule IBMCloud.IAM.OpenIDConfig do
  @moduledoc """
  Interfaces for configuration from OpenID Connect Discovery.

  - [OpenID Connect Discovery 1.0 incorporating errata set 1](https://openid.net/specs/openid-connect-discovery-1_0.html)
  """

  @default_endpoint "https://iam.cloud.ibm.com"

  import IBMCloud.Utils

  def build_client(endpoint \\ @default_endpoint, adapter \\ nil),
    do: build_json_client(endpoint, adapter)

  def get_config(client, opts \\ []) do
    case Tesla.get(client, "identity/.well-known/openid-configuration", opts) do
      {:ok, %{status: 200, body: %{"issuer" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  def get_jwks(client, jwks_uri_or_config, opts \\ [])

  def get_jwks(client, jwks_uri, opts) when is_binary(jwks_uri) do
    case Tesla.get(client, jwks_uri, opts) do
      {:ok, %{status: 200, body: %{"keys" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  def get_jwks(client, %{"jwks_uri" => jwks_uri} = _config, opts),
    do: get_jwks(client, jwks_uri, opts)
end
