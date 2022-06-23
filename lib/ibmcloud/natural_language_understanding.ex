defmodule IBMCloud.NaturalLanguageUnderstanding do
  @moduledoc """
  IBM Natural Language Understanding API.

  - [IBM Cloud API Docs: Natural Language Understanding API](https://cloud.ibm.com/apidocs/natural-language-understanding)
  """

  import IBMCloud.Utils

  @type client :: Tesla.Client.t()

  @type analyze_params :: %{
          required(:version) => String.t(),
          required(:features) => String.t(),
          optional(:text) => String.t(),
          optional(:html) => String.t(),
          optional(:url) => String.t(),
          optional(:return_analyzed_text) => boolean(),
          optional(:clean) => boolean(),
          optional(:xpath) => String.t(),
          optional(:fallback_to_raw) => boolean(),
          optional(:language) => String.t(),
          optional(:categories) => %{
            optional(:explanation) => boolean(),
            optional(:limit) => non_neg_integer(),
            optional(:model) => String.t()
          },
          optional(:classifications) => %{
            optional(:model) => String.t()
          },
          optional(:concepts) => %{
            optional(:limit) => non_neg_integer()
          },
          optional(:emotion) => %{
            optional(:document) => boolean(),
            optional(:targets) => String.t()
          },
          optional(:entities) => %{
            optional(:limit) => non_neg_integer(),
            optional(:mentions) => boolean(),
            optional(:model) => String.t(),
            optional(:emotion) => boolean(),
            optional(:sentiment) => boolean()
          },
          optional(:keywords) => %{
            optional(:limit) => non_neg_integer(),
            optional(:emotion) => boolean(),
            optional(:sentiment) => boolean()
          },
          optional(:relations) => %{
            optional(:model) => String.t()
          },
          optional(:semantic_roles) => %{
            optional(:limit) => non_neg_integer(),
            optional(:entities) => boolean(),
            optional(:keywords) => boolean()
          },
          optional(:sentiment) => %{
            optional(:document) => boolean(),
            optional(:model) => String.t(),
            optional(:targets) => String.t()
          },
          optional(:syntax) => %{
            optional(:tokens) => %{
              optional(:lemma) => boolean(),
              optional(:part_of_speech) => boolean()
            },
            optional(:sentences) => boolean()
          },
          optional(:limit_text_characters) => non_neg_integer()
        }

  @type model_params :: %{
          required(:language) => String.t(),
          required(:training_data) => String.t(),
          optional(:name) => String.t(),
          optional(:user_metadata) => map(),
          optional(:description) => String.t(),
          optional(:model_version) => String.t(),
          optional(:workspace_id) => String.t(),
          optional(:version_description) => String.t()
        }

  @doc """
  Builds and returns an authorized client for calling NLU endpoints using a
  Bearer token for authentication.
  """
  @spec build_client(
          bearer_token :: String.t(),
          endpoint :: String.t(),
          adapter :: Tesla.Client.adapter() | nil
        ) :: client()
  def build_client(bearer_token, endpoint, adapter \\ nil)
      when is_binary(bearer_token) and is_binary(endpoint),
      do: build_json_client_with_bearer(endpoint, bearer_token, adapter)

  @doc """
  Builds and returns an authorized client for calling NLU endpoints using an
  API key for authentication.
  """
  @spec build_api_key_client(
          api_key :: String.t(),
          endpoint :: String.t(),
          adapter :: Tesla.Client.adapter() | nil
        ) :: client()
  def build_api_key_client(api_key, endpoint, adapter \\ nil)
      when is_binary(api_key) and is_binary(endpoint),
      do: build_json_client_with_api_key(endpoint, api_key, adapter)

  @doc """
  Analyzes raw text, HTML, or a public webpage.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#analyze)
  for params and result details.

  ### Options

  * `:method`: One of `:get` (default) or `:post`, selects which HTTP method to
    use when making this method call.
  """
  @spec analyze(
          client :: client(),
          version :: String.t(),
          query_or_body :: analyze_params(),
          opts :: [method: :get | :post],
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def analyze(client, version, query_or_body, opts \\ [], tesla_opts \\ [])
      when is_binary(version) and is_map(query_or_body) do
    with {:ok, method} <- fetch_analyze_method(opts[:method]),
         {:ok, %{status: 200, body: body}} <-
           do_analyze(client, version, query_or_body, method, tesla_opts) do
      {:ok, body}
    end
  end

  defp fetch_analyze_method(:get), do: {:ok, :get}
  defp fetch_analyze_method(:post), do: {:ok, :post}
  defp fetch_analyze_method(nil), do: {:ok, :get}
  defp fetch_analyze_method(_other), do: {:error, :unknown_method}

  defp do_analyze(client, version, query, :get, tesla_opts) do
    path = URI.parse("/v1/analyze")

    query =
      query
      |> Map.put(:version, version)
      |> UriQuery.params()
      |> URI.encode_query(:rfc3986)

    full_path = URI.to_string(%{path | query: query})

    Tesla.get(client, full_path, tesla_opts)
  end

  defp do_analyze(client, version, body, :post, tesla_opts) do
    path = attach_version("/v1/analyze", version)
    Tesla.post(client, path, body, tesla_opts)
  end

  @doc """
  Lists Watson Knowledge Studio custom entities and relations models that are
  deployed to your Natural Language Understanding service.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#listmodels)
  for details.
  """
  @spec list_models(
          client :: client(),
          version :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def list_models(client, version, tesla_opts \\ []) when is_binary(version) do
    path = attach_version("/v1/models", version)

    with {:ok, %{status: 200, body: %{"models" => _models} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  Lists Watson Knowledge Studio custom entities and relations models that are
  deployed to your Natural Language Understanding service.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#listmodels)
  for details.
  """
  @spec delete_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def delete_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"deleted" => _model_id} = resp}} <-
           Tesla.delete(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Creates a custom sentiment model by uploading training data and
  associated metadata. The model begins the training and deploying process and
  is ready to use when the status is available.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#createsentimentmodel)
  for details.
  """
  @spec create_sentiment_model(
          client :: client(),
          version :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def create_sentiment_model(client, version, params, tesla_opts \\ []) do
    path = attach_version("/v1/models/sentiment", version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.post(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns all custom sentiment models associated with this service
  instance.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#listsentimentmodels)
  for details.
  """
  @spec list_sentiment_models(
          client :: client(),
          version :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def list_sentiment_models(client, version, tesla_opts \\ []) when is_binary(version) do
    path = attach_version("/v1/models/sentiment", version)

    with {:ok, %{status: 200, body: %{"models" => _models} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns the status of the sentiment model with the given model ID.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#getsentimentmodel)
  for details.
  """
  @spec get_sentiment_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def get_sentiment_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/sentiment/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Overwrites the training data associated with this custom sentiment
  model and retrains the model. The new model replaces the current deployment.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#updatesentimentmodel)
  for details.
  """
  @spec update_sentiment_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def update_sentiment_model(client, version, model_id, params, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) and is_map(params) do
    path = attach_version("/v1/models/sentiment/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.put(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Un-deploys the custom sentiment model with the given model ID and
  deletes all associated customer data, including any training data or binary
  artifacts.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#deletesentimentmodel)
  for details.
  """
  @spec delete_sentiment_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def delete_sentiment_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/sentiment/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"deleted" => _model_id} = resp}} <-
           Tesla.delete(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Creates a custom categories model by uploading training data and
  associated metadata. The model begins the training and deploying process and
  is ready to use when the status is available.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#createcategoriesmodel)
  for details.
  """
  @spec create_categories_model(
          client :: client(),
          version :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def create_categories_model(client, version, params, tesla_opts \\ []) do
    path = attach_version("/v1/models/categories", version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.post(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns all custom categories models associated with this service instance.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#listcategoriesmodels)
  for details.
  """
  @spec list_categories_models(
          client :: client(),
          version :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def list_categories_models(client, version, tesla_opts \\ []) when is_binary(version) do
    path = attach_version("/v1/models/categories", version)

    with {:ok, %{status: 200, body: %{"models" => _models} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns the status of the categories model with the given model ID.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#getcategoriesmodel)
  for details.
  """
  @spec get_categories_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def get_categories_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/categories/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Overwrites the training data associated with this custom categories
  model and retrains the model. The new model replaces the current deployment.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#updatecategoriesmodel)
  for details.
  """
  @spec update_categories_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def update_categories_model(client, version, model_id, params, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) and is_map(params) do
    path = attach_version("/v1/models/categories/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.put(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Un-deploys the custom categories model with the given model ID and
  deletes all associated customer data, including any training data or binary
  artifacts.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#deletecategoriesmodel)
  for details.
  """
  @spec delete_categories_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def delete_categories_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/categories/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"deleted" => _model_id} = resp}} <-
           Tesla.delete(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  Creates a custom classifications model by uploading training data and
  associated metadata. The model begins the training and deploying process and
  is ready to use when the status is available.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#createclassificationsmodel)
  for details.
  """
  @spec create_classifications_model(
          client :: client(),
          version :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def create_classifications_model(client, version, params, tesla_opts \\ []) do
    path = attach_version("/v1/models/classifications", version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.post(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns all custom classifications models associated with this service instance.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#listclassificationsmodels)
  for details.
  """
  @spec list_classifications_models(
          client :: client(),
          version :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def list_classifications_models(client, version, tesla_opts \\ []) when is_binary(version) do
    path = attach_version("/v1/models/classifications", version)

    with {:ok, %{status: 200, body: %{"models" => _models} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  (Beta) Returns the status of the classifications model with the given model ID.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#getclassificationsmodel)
  for details.
  """
  @spec get_classifications_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def get_classifications_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/classifications/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.get(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  Overwrites the training data associated with this custom classifications model
  and retrains the model. The new model replaces the current deployment.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#updateclassificationsmodel)
  for details.
  """
  @spec update_classifications_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          params :: model_params(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def update_classifications_model(client, version, model_id, params, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) and is_map(params) do
    path = attach_version("/v1/models/classifications/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"model_id" => _model_id} = resp}} <-
           Tesla.put(client, path, params, tesla_opts) do
      {:ok, resp}
    end
  end

  @doc """
  Un-deploys the custom classifications model with the given model ID and
  deletes all associated customer data, including any training data or binary
  artifacts.

  See the [official docs](https://cloud.ibm.com/apidocs/natural-language-understanding#deleteclassificationsmodel)
  for details.
  """
  @spec delete_classifications_model(
          client :: client(),
          version :: String.t(),
          model_id :: String.t(),
          tesla_opts :: keyword() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def delete_classifications_model(client, version, model_id, tesla_opts \\ [])
      when is_binary(version) and is_binary(model_id) do
    path = attach_version("/v1/models/classifications/" <> uri_encode(model_id), version)

    with {:ok, %{status: 200, body: %{"deleted" => _model_id} = resp}} <-
           Tesla.delete(client, path, tesla_opts) do
      {:ok, resp}
    end
  end

  defp attach_version(path, version) do
    path
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{version: version}))
    |> URI.to_string()
  end
end
