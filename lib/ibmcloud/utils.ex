defmodule IBMCloud.Utils do
  @moduledoc false

  def build_json_client(endpoint, adapter) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, endpoint},
        Tesla.Middleware.JSON
      ],
      adapter
    )
  end

  def build_json_client_with_bearer(endpoint, bearer_token, adapter) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, endpoint},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> bearer_token}]}
      ],
      adapter
    )
  end

  def build_json_client_with_api_key(endpoint, api_key, adapter) when is_binary(api_key) do
    credentials = :base64.encode("apikey:#{api_key}")

    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, endpoint},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"authorization", "Basic #{credentials}"}]}
      ],
      adapter
    )
  end

  def uri_encode(val) when is_integer(val), do: to_string(val)
  def uri_encode(val), do: URI.encode(val, &URI.char_unreserved?/1)

  def opts_put_query(opts, val) do
    opts
    |> Keyword.put_new(:query, [])
    |> update_in([:query], &[val | &1])
  end

  def opts_put_header(opts, val) do
    opts
    |> Keyword.put_new(:headers, [])
    |> update_in([:headers], &[val | &1])
  end
end
