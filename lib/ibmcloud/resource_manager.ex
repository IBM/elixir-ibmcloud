defmodule IBMCloud.ResourceManager do
  @moduledoc """
  IBM Cloud Resource Manager API.

  - [IBM Cloud API Docs: Resource Manager API](https://cloud.ibm.com/apidocs/resource-manager)
  """

  @default_endpoint "https://resource-controller.cloud.ibm.com"

  import IBMCloud.Utils

  def build_client(bearer_token, endpoint \\ @default_endpoint, adapter \\ nil),
    do: build_json_client_with_bearer(endpoint, bearer_token, adapter)

  @doc """
  Lists resource groups.

  See [Get a list of all resource groups.](https://cloud.ibm.com/apidocs/resource-manager#get-a-list-of-all-resource-groups) for details.
  """
  def list_resource_groups(client, opts \\ []) do
    case Tesla.get(client, "v2/resource_groups", opts) do
      {:ok, %{status: 200, body: %{"resources" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Gets a resource group.

  See [Get a resource group](https://cloud.ibm.com/apidocs/resource-manager#get-a-resource-group) for details.
  """
  def get_resource_group(client, id, opts \\ []) do
    case Tesla.get(client, "v2/resource_groups/" <> uri_encode(id), opts) do
      {:ok, %{status: 200, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Creates a resource group.

  See [Create a new resource group](https://cloud.ibm.com/apidocs/resource-manager#create-a-new-resource-group) for details.
  """
  def create_resource_group(client, body, opts \\ []) do
    case Tesla.post(client, "v2/resource_groups", body, opts) do
      {:ok, %{status: 201, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end
end
