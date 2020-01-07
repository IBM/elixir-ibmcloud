defmodule IBMCloud.CRN do
  @moduledoc """
  Cloud Resource Name.

  - [Cloud Resource Names](https://cloud.ibm.com/docs/overview/crn.html)
  """

  @type scope() :: {:account | :organization | :space, binary()} | nil
  @type t :: %__MODULE__{
          version: binary(),
          cname: binary(),
          ctype: binary(),
          service_name: binary() | nil,
          location: binary() | nil,
          scope: binary() | nil,
          service_instance: binary() | nil,
          service_instance: binary() | nil,
          resource_type: binary() | nil,
          resource: binary() | nil
        }
  defstruct version: "v1",
            cname: "bluemix",
            ctype: "public",
            service_name: nil,
            location: nil,
            scope: nil,
            service_instance: nil,
            service_instance: nil,
            resource_type: nil,
            resource: nil

  def parse(binary) when is_binary(binary) do
    case String.split(binary, ":") do
      [
        "crn",
        version,
        cname,
        ctype,
        service_name,
        location,
        scope,
        service_instance,
        resource_type,
        resource
      ] ->
        {:ok,
         %__MODULE__{
           version: parse_raw(:version, version),
           cname: parse_raw(:cname, cname),
           ctype: parse_raw(:ctype, ctype),
           service_name: parse_raw(:service_name, service_name),
           location: parse_raw(:location, location),
           scope: parse_raw(:scope, scope),
           service_instance: parse_raw(:service_instance, service_instance),
           resource_type: parse_raw(:resource_type, resource_type),
           resource: parse_raw(:resource, resource)
         }}

      _ ->
        {:error, "invalid CRN"}
    end
  end

  def to_string(%__MODULE__{
        version: version,
        cname: cname,
        ctype: ctype,
        service_name: service_name,
        location: location,
        scope: scope,
        service_instance: service_instance,
        resource_type: resource_type,
        resource: resource
      }) do
    [
      "crn",
      raw_to_string(:version, version),
      raw_to_string(:cname, cname),
      raw_to_string(:ctype, ctype),
      raw_to_string(:service_name, service_name),
      raw_to_string(:location, location),
      raw_to_string(:scope, scope),
      raw_to_string(:service_instance, service_instance),
      raw_to_string(:resource_type, resource_type),
      raw_to_string(:resource, resource)
    ]
    |> Enum.join(":")
  end

  def parse_scope("a/" <> val), do: {:account, val}
  def parse_scope("o/" <> val), do: {:organization, val}
  def parse_scope("s/" <> val), do: {:space, val}

  defp parse_raw(_field, ""), do: nil
  defp parse_raw(:scope, val), do: parse_scope(val)
  defp parse_raw(_field, val), do: val

  def scope_to_string({:account, val}), do: "a/" <> val
  def scope_to_string({:organization, val}), do: "o/" <> val
  def scope_to_string({:space, val}), do: "s/" <> val

  defp raw_to_string(_field, nil), do: ""
  defp raw_to_string(:scope, val), do: scope_to_string(val)
  defp raw_to_string(_field, val), do: val
end
