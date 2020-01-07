defmodule IBMCloud.AccountManager do
  @moduledoc """
  IBM Cloud Account Manager API.

  From `ibmcloud` CLI tool.
  """

  @default_endpoint "https://accounts.cloud.ibm.com"

  import IBMCloud.Utils

  def build_client(bearer_token, endpoint \\ @default_endpoint, adapter \\ nil),
    do: build_json_client_with_bearer(endpoint, bearer_token, adapter)

  def list_accounts(client, opts \\ []) do
    case Tesla.get(client, "v1/accounts", opts) do
      {:ok, %{status: 200, body: %{"resources" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end
end
