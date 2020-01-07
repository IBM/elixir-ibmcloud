defmodule IBMCloud.IAM.OAuth2 do
  @moduledoc """
  OAuth2 interfaces to IAM.
  """

  @default_endpoint "https://iam.cloud.ibm.com"

  def build_client(auth \\ [], endpoint \\ @default_endpoint, adapter \\ nil) do
    middlewares =
      [
        {Tesla.Middleware.BaseUrl, endpoint},
        Tesla.Middleware.FormUrlencoded,
        Tesla.Middleware.DecodeJson
      ]
      |> add_auth_middleware(auth)

    Tesla.client(middlewares, adapter)
  end

  defp add_auth_middleware(middlewares, auth) do
    with {:ok, client_id} <- Keyword.fetch(auth, :client_id),
         {:ok, client_secret} <- Keyword.fetch(auth, :client_secret) do
      [
        {Tesla.Middleware.BasicAuth, username: client_id, password: client_secret}
        | middlewares
      ]
    else
      _ -> middlewares
    end
  end

  @doc """
  Creates a token.

  ## API Key

  - `:apikey`

  ```elixir
  {:ok, %{status: 200, body: %{"access_token" => bearer_token}}} =
    IBMCloud.IAM.OAuth2.build_client()
    |> IBMCloud.IAM.OAuth2.create_token(apikey: apikey)
  ```

  [Create an IAM access token for a user or service ID](https://cloud.ibm.com/apidocs/iam-identity-token-api#create-an-iam-access-token-for-a-user-or-service-i)

  ## Authorization Code

  - `:code`

  [Step 4. Developing an authentication flow](https://cloud.ibm.com/docs/third-party?topic=third-party-step4-iam#token-post)
  """
  def create_token(client, body \\ [], opts \\ []) do
    grant_type =
      cond do
        Keyword.has_key?(body, :apikey) -> "urn:ibm:params:oauth:grant-type:apikey"
        Keyword.has_key?(body, :code) -> "authorization_code"
      end

    body = Keyword.put_new(body, :grant_type, grant_type)

    case Tesla.post(client, "identity/token", body, opts) do
      {:ok, %{status: 200} = resp} -> {:ok, resp}
      {_, other} -> {:error, other}
    end
  end
end
