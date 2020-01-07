defmodule IBMCloud.KeyProtect do
  @moduledoc """
  IBM Key Protect API.

  - [IBM Cloud Docs- IBM Key Protect](https://cloud.ibm.com/docs/services/key-protect)
  - [IBM Cloud API - IBM Key Protect API](https://cloud.ibm.com/apidocs/key-protect)
  """

  import IBMCloud.Utils

  def build_client(endpoint, bearer_token, instance_id, adapter \\ nil) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, endpoint},
        {Tesla.Middleware.JSON,
         decode_content_types: [
           "application/vnd.ibm.kms.key+json",
           "application/vnd.ibm.kms.key_action+json"
         ]},
        {Tesla.Middleware.Headers,
         [
           {"authorization", "Bearer " <> bearer_token},
           {"bluemix-instance", instance_id}
         ]}
      ],
      adapter
    )
  end

  @doc """
  Lists a list of keys.

  See [Retrieve a list of keys](https://cloud.ibm.com/apidocs/key-protect#retrieve-a-list-of-keys) for details.
  """
  def list_keys(client, opts \\ []) do
    case Tesla.get(client, "api/v2/keys", opts) do
      # resources is missing when there is no keys
      {:ok, %{status: 200, body: %{"metadata" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Creates a new key.

  See [Create a new key](https://cloud.ibm.com/apidocs/key-protect#create-a-new-key) for details.
  """
  def create_key(client, %{} = key_body, opts \\ []) do
    body = %{
      metadata: %{
        collectionType: "application/vnd.ibm.kms.key+json",
        collectionTotal: 1
      },
      resources: [Map.put(key_body, :type, "application/vnd.ibm.kms.key+json")]
    }

    case Tesla.post(client, "api/v2/keys", body, opts) do
      {:ok, %{status: 201, body: %{"resources" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Deletes a key by ID.

  See [Delete a key by ID](https://cloud.ibm.com/apidocs/key-protect#delete-a-key-by-id) for details.
  """
  def delete_key(client, id, opts \\ []) do
    case Tesla.delete(client, "api/v2/keys/" <> uri_encode(id), opts) do
      {:ok, %{status: 204} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Invokes an action on key.

  See [Invoke an action on a key](https://cloud.ibm.com/apidocs/key-protect#invoke-an-action-on-a-key) for details.
  """
  def invoke_action(client, id, action, %{} = body, opts \\ []) do
    opts =
      opts
      |> Keyword.put(:method, :post)
      |> Keyword.put(:body, body)
      |> Keyword.put(:url, "api/v2/keys/" <> uri_encode(id))
      |> opts_put_query({"action", action})

    case Tesla.request(client, opts) do
      {:ok, %{status: status} = resp} when status in [200, 204] -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  def wrap_key(client, id, %{} = body, opts \\ []),
    do: invoke_action(client, id, :wrap, body, opts)

  def unwrap_key(client, id, %{} = body, opts \\ []),
    do: invoke_action(client, id, :unwrap, body, opts)
end
