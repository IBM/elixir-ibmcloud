defmodule IBMCloud.NaturalLanguageUnderstandingTest do
  use ExUnit.Case, async: true

  alias IBMCloud.NaturalLanguageUnderstanding, as: NLU

  @test_endpoint "https://api.eu-de.natural-language-understanding.watson.cloud.ibm.com/instances/88888888-4444-4444-4444-121212121212"
  @test_api_key "1234567890"

  setup do
    client = NLU.build_api_key_client(@test_api_key, @test_endpoint, Tesla.Mock)
    {:ok, client: client}
  end

  describe "build_client/3" do
    test "creates an authorized client for the given endpoint and bearer token" do
      client = NLU.build_client("test-token", @test_endpoint, Tesla.Mock)

      assert match?(%Tesla.Client{}, client)
      assert Tesla.Client.adapter(client) == Tesla.Mock

      middlewares = Tesla.Client.middleware(client)

      base_url = Keyword.fetch!(middlewares, Tesla.Middleware.BaseUrl)
      assert base_url == @test_endpoint

      headers = Keyword.fetch!(middlewares, Tesla.Middleware.Headers)

      assert {_, auth} = Enum.find(headers, fn {key, _} -> key == "authorization" end)
      assert auth == "Bearer test-token"
    end
  end

  describe "build_api_key_client/3" do
    test "creates an authorized client for the given endpoint and API key", %{client: client} do
      assert match?(%Tesla.Client{}, client)
      assert Tesla.Client.adapter(client) == Tesla.Mock

      middlewares = Tesla.Client.middleware(client)

      base_url = Keyword.fetch!(middlewares, Tesla.Middleware.BaseUrl)
      assert base_url == @test_endpoint

      headers = Keyword.fetch!(middlewares, Tesla.Middleware.Headers)

      assert {_, auth} = Enum.find(headers, fn {key, _} -> key == "authorization" end)
      assert auth == "Basic YXBpa2V5OjEyMzQ1Njc4OTA="
    end
  end

  describe "analyze/5" do
    test "[GET] calls the analyze endpoint and returns results", %{client: client} do
      Tesla.Mock.mock(fn
        %{method: :get} = env ->
          uri = URI.parse(env.url)
          query = URI.decode_query(uri.query)

          assert uri.path == "/instances/88888888-4444-4444-4444-121212121212/v1/analyze"

          assert query == %{
                   "version" => "2022-04-07",
                   "text" => "This is a horrible story!",
                   "features[sentiment][document]" => "true"
                 }

          %Tesla.Env{
            status: 200,
            body: %{
              "sentiment" => %{
                "document" => %{
                  "score" => -0.989674,
                  "label" => "negative"
                }
              },
              "language" => "en"
            }
          }
      end)

      assert {:ok, response} =
               NLU.analyze(client, "2022-04-07", %{
                 text: "This is a horrible story!",
                 features: %{sentiment: %{document: true}}
               })

      assert response["language"] == "en"

      assert response["sentiment"] == %{
               "document" => %{
                 "score" => -0.989674,
                 "label" => "negative"
               }
             }
    end

    test "[POST] calls the analyze endpoint and returns results", %{client: client} do
      Tesla.Mock.mock(fn
        %{method: :post} = env ->
          uri = URI.parse(env.url)
          query = URI.decode_query(uri.query)

          assert uri.path == "/instances/88888888-4444-4444-4444-121212121212/v1/analyze"
          assert query == %{"version" => "2022-04-07"}

          assert env.body ==
                   Jason.encode!(%{
                     text: "This is a horrible story!",
                     features: %{
                       sentiment: %{
                         document: true
                       }
                     }
                   })

          %Tesla.Env{
            status: 200,
            body: %{
              "sentiment" => %{
                "document" => %{
                  "score" => -0.989674,
                  "label" => "negative"
                }
              },
              "language" => "en"
            }
          }
      end)

      assert {:ok, response} =
               NLU.analyze(
                 client,
                 "2022-04-07",
                 %{
                   text: "This is a horrible story!",
                   features: %{sentiment: %{document: true}}
                 },
                 method: :post
               )

      assert response["language"] == "en"

      assert response["sentiment"] == %{
               "document" => %{
                 "score" => -0.989674,
                 "label" => "negative"
               }
             }
    end
  end

  describe "list_models/3" do
    test "fetches a list of deployed models from the API", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :get, url: @test_endpoint <> "/v1/models?version=2022-04-07"} ->
          %Tesla.Env{status: 200, body: %{"models" => [fake_model]}}
      end)

      assert {:ok, response} = NLU.list_models(client, "2022-04-07")
      assert [res_model] = response["models"]
      assert res_model == fake_model
    end
  end

  describe "delete_model/4" do
    test "calls the API to DELETE a model by ID", %{client: client} do
      model_id = Faker.UUID.v4()
      url = @test_endpoint <> "/v1/models/#{model_id}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :delete, url: ^url} ->
          %Tesla.Env{status: 200, body: %{"deleted" => model_id}}
      end)

      assert {:ok, response} = NLU.delete_model(client, "2022-04-07", model_id)
      assert response["deleted"] == model_id
    end
  end

  describe "create_sentiment_model/4" do
    test "calls the API to create a model", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :post, url: @test_endpoint <> "/v1/models/sentiment?version=2022-04-07"} ->
          response =
            Map.merge(fake_model, %{
              "created" => now_iso(),
              "features" => ["sentiment"],
              "last_trained" => nil,
              "last_deployed" => nil,
              "notices" => []
            })

          %Tesla.Env{status: 200, body: response}
      end)

      params = Map.put(fake_model, :training_data, "@sentiment_data.csv;type=text/csv")
      assert {:ok, response} = NLU.create_sentiment_model(client, "2022-04-07", params)

      assert response["model_id"] == fake_model["model_id"]
      assert response["features"] == ["sentiment"]
    end
  end

  describe "list_sentiment_models/3" do
    test "fetches a list of sentiment models from the API", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :get, url: @test_endpoint <> "/v1/models/sentiment?version=2022-04-07"} ->
          %Tesla.Env{status: 200, body: %{"models" => [fake_model]}}
      end)

      assert {:ok, response} = NLU.list_sentiment_models(client, "2022-04-07")
      assert [res_model] = response["models"]
      assert res_model == fake_model
    end
  end

  describe "get_sentiment_model/4" do
    test "fetches a sentiment model by ID from the API", %{client: client} do
      fake_model = gen_model()
      url = @test_endpoint <> "/v1/models/sentiment/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :get, url: ^url} ->
          %Tesla.Env{status: 200, body: fake_model}
      end)

      assert {:ok, response} =
               NLU.get_sentiment_model(client, "2022-04-07", fake_model["model_id"])

      assert response == fake_model
    end
  end

  describe "update_sentiment_model/5" do
    test "updates a sentiment model by ID from the API", %{client: client} do
      fake_model = gen_model()
      url = @test_endpoint <> "/v1/models/sentiment/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :put, url: ^url, body: body} ->
          assert body == "{\"name\":\"Something new\"}"
          %Tesla.Env{status: 200, body: %{fake_model | "name" => "Something new"}}
      end)

      assert {:ok, response} =
               NLU.update_sentiment_model(
                 client,
                 "2022-04-07",
                 fake_model["model_id"],
                 %{name: "Something new"}
               )

      assert response == %{fake_model | "name" => "Something new"}
    end
  end

  describe "delete_sentiment_model/4" do
    test "calls the API to DELETE a sentiment model by ID", %{client: client} do
      model_id = Faker.UUID.v4()
      url = @test_endpoint <> "/v1/models/sentiment/#{model_id}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :delete, url: ^url} ->
          %Tesla.Env{status: 200, body: %{"deleted" => model_id}}
      end)

      assert {:ok, response} = NLU.delete_sentiment_model(client, "2022-04-07", model_id)
      assert response["deleted"] == model_id
    end
  end

  describe "create_categories_model/4" do
    test "calls the API to create a model", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :post, url: @test_endpoint <> "/v1/models/categories?version=2022-04-07"} ->
          response =
            Map.merge(fake_model, %{
              "created" => now_iso(),
              "features" => ["categories"],
              "last_trained" => nil,
              "last_deployed" => nil,
              "notices" => []
            })

          %Tesla.Env{status: 200, body: response}
      end)

      params = Map.put(fake_model, :training_data, "@categories_data.csv;type=text/csv")
      assert {:ok, response} = NLU.create_categories_model(client, "2022-04-07", params)

      assert response["model_id"] == fake_model["model_id"]
      assert response["features"] == ["categories"]
    end
  end

  describe "list_categories_models/3" do
    test "fetches a list of categories models from the API", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :get, url: @test_endpoint <> "/v1/models/categories?version=2022-04-07"} ->
          %Tesla.Env{status: 200, body: %{"models" => [fake_model]}}
      end)

      assert {:ok, response} = NLU.list_categories_models(client, "2022-04-07")
      assert [res_model] = response["models"]
      assert res_model == fake_model
    end
  end

  describe "get_categories_model/4" do
    test "fetches a categories model by ID from the API", %{client: client} do
      fake_model = gen_model()
      url = @test_endpoint <> "/v1/models/categories/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :get, url: ^url} ->
          %Tesla.Env{status: 200, body: fake_model}
      end)

      assert {:ok, response} =
               NLU.get_categories_model(client, "2022-04-07", fake_model["model_id"])

      assert response == fake_model
    end
  end

  describe "update_categories_model/5" do
    test "updates a categories model by ID from the API", %{client: client} do
      fake_model = gen_model()
      url = @test_endpoint <> "/v1/models/categories/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :put, url: ^url, body: body} ->
          assert body == "{\"name\":\"Something new\"}"
          %Tesla.Env{status: 200, body: %{fake_model | "name" => "Something new"}}
      end)

      assert {:ok, response} =
               NLU.update_categories_model(
                 client,
                 "2022-04-07",
                 fake_model["model_id"],
                 %{name: "Something new"}
               )

      assert response == %{fake_model | "name" => "Something new"}
    end
  end

  describe "delete_categories_model/4" do
    test "calls the API to DELETE a categories model by ID", %{client: client} do
      model_id = Faker.UUID.v4()
      url = @test_endpoint <> "/v1/models/categories/#{model_id}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :delete, url: ^url} ->
          %Tesla.Env{status: 200, body: %{"deleted" => model_id}}
      end)

      assert {:ok, response} = NLU.delete_categories_model(client, "2022-04-07", model_id)
      assert response["deleted"] == model_id
    end
  end

  describe "create_classifications_model/4" do
    test "calls the API to create a model", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :post, url: @test_endpoint <> "/v1/models/classifications?version=2022-04-07"} ->
          response =
            Map.merge(fake_model, %{
              "created" => now_iso(),
              "features" => ["classifications"],
              "last_trained" => nil,
              "last_deployed" => nil,
              "notices" => []
            })

          %Tesla.Env{status: 200, body: response}
      end)

      params = Map.put(fake_model, :training_data, "@classifications_data.csv;type=text/csv")
      assert {:ok, response} = NLU.create_classifications_model(client, "2022-04-07", params)

      assert response["model_id"] == fake_model["model_id"]
      assert response["features"] == ["classifications"]
    end
  end

  describe "list_classifications_models/3" do
    test "fetches a list of classifications models from the API", %{client: client} do
      fake_model = gen_model()

      Tesla.Mock.mock(fn
        %{method: :get, url: @test_endpoint <> "/v1/models/classifications?version=2022-04-07"} ->
          %Tesla.Env{status: 200, body: %{"models" => [fake_model]}}
      end)

      assert {:ok, response} = NLU.list_classifications_models(client, "2022-04-07")
      assert [res_model] = response["models"]
      assert res_model == fake_model
    end
  end

  describe "get_classifications_model/4" do
    test "fetches a classifications model by ID from the API", %{client: client} do
      fake_model = gen_model()

      url =
        @test_endpoint <>
          "/v1/models/classifications/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :get, url: ^url} ->
          %Tesla.Env{status: 200, body: fake_model}
      end)

      assert {:ok, response} =
               NLU.get_classifications_model(client, "2022-04-07", fake_model["model_id"])

      assert response == fake_model
    end
  end

  describe "update_classifications_model/5" do
    test "updates a classifications model by ID from the API", %{client: client} do
      fake_model = gen_model()

      url =
        @test_endpoint <>
          "/v1/models/classifications/#{fake_model["model_id"]}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :put, url: ^url, body: body} ->
          assert body == "{\"name\":\"Something new\"}"
          %Tesla.Env{status: 200, body: %{fake_model | "name" => "Something new"}}
      end)

      assert {:ok, response} =
               NLU.update_classifications_model(
                 client,
                 "2022-04-07",
                 fake_model["model_id"],
                 %{name: "Something new"}
               )

      assert response == %{fake_model | "name" => "Something new"}
    end
  end

  describe "delete_classifications_model/4" do
    test "calls the API to DELETE a classifications model by ID", %{client: client} do
      model_id = Faker.UUID.v4()
      url = @test_endpoint <> "/v1/models/classifications/#{model_id}?version=2022-04-07"

      Tesla.Mock.mock(fn
        %{method: :delete, url: ^url} ->
          %Tesla.Env{status: 200, body: %{"deleted" => model_id}}
      end)

      assert {:ok, response} = NLU.delete_classifications_model(client, "2022-04-07", model_id)
      assert response["deleted"] == model_id
    end
  end

  defp gen_model do
    version = Faker.App.semver()

    %{
      "workspace_id" => Faker.UUID.v4(),
      "version_description" => "Final version",
      "model_version" => version,
      "version" => version,
      "status" =>
        Enum.random(["starting", "training", "deploying", "available", "error", "deleted"]),
      "notices" => [],
      "name" => Faker.App.name() <> " Model",
      "model_id" => Faker.UUID.v4(),
      "language" => "en",
      "description" => "A test model",
      "created" => now_iso()
    }
  end

  defp now_iso, do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
end
