defmodule IBMCloud.IAM do
  @moduledoc """
  IBM Cloud Identity and Access Management (IAM) API.

  - [IBM Cloud Docs: Managing identity and access](https://cloud.ibm.com/docs/iam/index.html#iamoverview)
  - [IBM Cloud API Docs: Token Service API](https://cloud.ibm.com/apidocs/iam-identity-token-api)
  """

  @default_endpoint "https://iam.cloud.ibm.com"

  import IBMCloud.Utils

  def build_client(bearer_token, endpoint \\ @default_endpoint, adapter \\ nil),
    do: build_json_client_with_bearer(endpoint, bearer_token, adapter)

  @doc """
  Creates a Service ID.

  See [Create a Service ID](https://cloud.ibm.com/apidocs/iam-identity-token-api#create-a-service-id) for details.
  """
  def create_service_id(client, body, opts \\ []) do
    case Tesla.post(client, "v1/serviceids", body, opts) do
      {:ok, %{status: 201} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  List Service IDs.

  See [List Service IDs](https://cloud.ibm.com/apidocs/iam-identity-token-api#list-service-ids) for details.
  """
  def list_service_ids(client, opts \\ []) do
    case Tesla.get(client, "v1/serviceids", opts) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Returns a stream of Service IDs.

  See `list_service_ids/2`.
  """
  def stream_service_ids(client, opts \\ []) do
    {:ok, %{body: body}} = list_service_ids(client, opts)

    Stream.unfold({client, opts, body}, &stream_unfold_service_ids/1)
  end

  defp stream_unfold_service_ids({client, opts, %{"serviceids" => [h | tail]} = body}),
    do: {h, {client, opts, Map.put(body, "serviceids", tail)}}

  defp stream_unfold_service_ids(
         {client, opts, %{"serviceids" => [], "next" => next, "limit" => limit}}
       )
       when not is_nil(next) do
    with %{query: query} <- URI.parse(next),
         %{"pagetoken" => page_token} <- URI.decode_query(query),
         opts <- Keyword.put(opts, :query, pagetoken: page_token, pagesize: limit),
         {:ok, %{body: %{"serviceids" => [h | tail]} = body}} <- list_service_ids(client, opts) do
      {h, {client, opts, Map.put(body, "serviceids", tail)}}
    else
      _ -> nil
    end
  end

  defp stream_unfold_service_ids({_client, _opts, %{"serviceids" => []}}), do: nil

  @doc """
  Get a Service ID.

  [Get details of a Service ID](https://cloud.ibm.com/apidocs/iam-identity-token-api#get-details-of-a-service-id)
  """
  def get_service_id(client, uuid, opts \\ []) do
    case Tesla.get(client, "v1/serviceids/" <> uri_encode(uuid), opts) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Delete a Service ID.

  [Deletes a Service ID and associated ApiKeys](https://cloud.ibm.com/apidocs/iam-identity-token-api#deletes-a-service-id-and-associated-apikeys)
  """
  def delete_service_id(client, id, opts \\ []) do
    case Tesla.delete(client, "v1/serviceids/" <> uri_encode(id), opts) do
      {:ok, %{status: 204} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  List API keys.

  [Get API keys for a given a service or user IAM ID and account ID](https://cloud.ibm.com/apidocs/iam-identity-token-api#get-api-keys-for-a-given-a-service-or-user-iam-id-)
  """
  def list_api_keys(client, opts \\ []) do
    case Tesla.get(client, "v1/apikeys", opts) do
      {:ok, %{status: 200, body: %{"apikeys" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Get an API key.

  [Get details of an API key](https://cloud.ibm.com/apidocs/iam-identity-token-api#get-details-of-an-api-key)
  """
  def get_api_key(client, id, opts \\ []) do
    case Tesla.get(client, "v1/apikeys/" <> uri_encode(id), opts) do
      {:ok, %{status: 200, body: %{"id" => _}} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Create API Key.

  [Create an ApiKey](https://cloud.ibm.com/apidocs/iam-identity-token-api#create-an-apikey)
  """
  def create_api_key(client, body, opts \\ []) do
    case Tesla.post(client, "v1/apikeys", body, opts) do
      {:ok, %{status: 201} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Delete API Key.

  [Deletes an ApiKey](https://cloud.ibm.com/apidocs/iam-identity-token-api#deletes-an-apikey)
  """
  def delete_api_key(client, apikey_id, opts \\ []) do
    case Tesla.delete(client, "v1/apikeys/" <> uri_encode(apikey_id), opts) do
      {:ok, %{status: 204} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Get IAM policies.

  [Get policies by attributes](https://cloud.ibm.com/apidocs/iam-policy-management#get-policies-by-attributes)
  """
  def list_policies(client, opts \\ []) do
    case Tesla.get(client, "v1/policies", opts) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Get an IAM policy.

  [Retrieve a policy by ID](https://cloud.ibm.com/apidocs/iam-policy-management#retrieve-a-policy-by-id)
  """
  def get_policy(client, policy_id, opts \\ []) do
    case Tesla.get(client, "v1/policies/" <> uri_encode(policy_id), opts) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Create an IAM policy.

  [Create a policy](https://cloud.ibm.com/apidocs/iam-policy-management#create-a-policy)
  """
  def create_policy(client, body, opts \\ []) do
    case Tesla.post(client, "v1/policies", body, opts) do
      {:ok, %{status: 201} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end

  @doc """
  Update an IAM policy.

  [Update a policy](https://cloud.ibm.com/apidocs/iam-policy-management#update-a-policy)
  """
  def update_policy(client, policy_id, body, rev, opts \\ []) do
    case Tesla.put(
           client,
           "v1/policies/" <> uri_encode(policy_id),
           body,
           opts_put_header(opts, {"if-match", rev})
         ) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end
end
