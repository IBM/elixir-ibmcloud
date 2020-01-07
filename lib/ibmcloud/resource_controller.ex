defmodule IBMCloud.ResourceController do
  @moduledoc """
  IBM Cloud Resource Controller API.

  - [IBM Cloud API Docs: Resource Controller API](https://cloud.ibm.com/apidocs/resource-controller)
  """

  @default_endpoint "https://resource-controller.cloud.ibm.com"

  import IBMCloud.Utils

  def build_client(bearer_token, endpoint \\ @default_endpoint, adapter \\ nil),
    do: build_json_client_with_bearer(endpoint, bearer_token, adapter)

  @doc """
  Lists resource instances.

  See [Get a list of all resource instances](https://cloud.ibm.com/apidocs/resource-controller#get-a-list-of-all-resource-instances) for details.
  """
  def list_resource_instances(client, opts \\ []) do
    case Tesla.get(client, "v2/resource_instances", opts) do
      {:ok, %{status: 200, body: %{"resources" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Gets a resource instance.

  See [Get a resource instance](https://cloud.ibm.com/apidocs/resource-controller#get-a-resource-instance) for details.
  """
  def get_resource_instance(client, id, opts \\ []) do
    case Tesla.get(client, "v2/resource_instances/" <> uri_encode(id), opts) do
      {:ok, %{status: 200, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Creates a resource instance.

  See [Create (provision) a new resource instance](https://cloud.ibm.com/apidocs/resource-controller#create-provision-a-new-resource-instance).
  """
  def create_resource_instance(client, body, opts \\ []) do
    case Tesla.post(client, "v2/resource_instances", body, opts) do
      {:ok, %{status: status, body: %{"id" => _}} = resp} when status in [201, 202] -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Deletes a resource instance.

  See [Delete a resource instance](https://cloud.ibm.com/apidocs/resource-controller#delete-a-resource-instance) for details.
  """
  def delete_resource_instance(client, id, opts \\ []) do
    case Tesla.delete(client, "v2/resource_instances/" <> uri_encode(id), opts) do
      {:ok, %{status: status} = resp} when status in [202, 204] -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Lists resource keys.

  See [Get a list of resource keys](https://cloud.ibm.com/apidocs/resource-controller#get-a-list-of-resource-keys) for details.
  """
  def list_resource_keys(client, opts \\ []) do
    case Tesla.get(client, "v2/resource_keys", opts) do
      {:ok, %{status: 200, body: %{"resources" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Gets a resource key.

  See [Get resource key by ID](https://cloud.ibm.com/apidocs/resource-controller#get-resource-key-by-id) for details.
  """
  def get_resource_key(client, id, opts \\ []) do
    case Tesla.get(client, "v2/resource_keys/" <> uri_encode(id), opts) do
      {:ok, %{status: 200, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Creates a resource key.

  See [Create a new resource key](https://cloud.ibm.com/apidocs/resource-controller#create-a-new-resource-key) for details.
  """
  def create_resource_key(client, body, opts \\ []) do
    case Tesla.post(client, "v2/resource_keys", body, opts) do
      {:ok, %{status: 201, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Deletes a resource key.

  See [Delete a resource key by ID](https://cloud.ibm.com/apidocs/resource-controller#delete-a-resource-key-by-id) for details.
  """
  def delete_resource_key(client, id, opts \\ []) do
    case Tesla.delete(client, "v2/resource_keys/" <> uri_encode(id), opts) do
      {:ok, %{status: 204} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc false
  def stream(client, func, opts \\ []) do
    {:ok, %{body: body}} = func.(client, opts)
    Stream.unfold({client, Keyword.delete(opts, :query), body}, &stream_unfold/1)
  end

  defp stream_unfold({client, _opts, %{"resources" => [h | tail]} = body}),
    do: {h, {client, Map.put(body, "resources", tail)}}

  defp stream_unfold({_client, _opts, %{"resources" => [], "next_url" => nil}}), do: nil

  defp stream_unfold({client, opts, %{"resources" => [], "next_url" => next_url}}) do
    {:ok, %{body: body}} = Tesla.get(client, next_url, opts)

    stream_unfold({client, opts, body})
  end
end
