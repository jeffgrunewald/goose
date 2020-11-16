defmodule Maverick.Api.Initializer do
  @moduledoc false

  use GenServer, restart: :transient

  def start_link({api, otp_app, opts}) do
    name = Keyword.get(opts, :init_name, Module.concat(api, Initializer))

    GenServer.start_link(__MODULE__, {api, otp_app}, name: name)
  end

  @impl true
  def init(opts) do
    case build_handler_module(opts) do
      :ok -> {:ok, nil, {:continue, :exit}}
      _ -> {:error, "Failed to initialize the handler"}
    end
  end

  @impl true
  def handle_continue(:exit, state) do
    {:stop, :normal, state}
  end

  defp build_handler_module({api, otp_app}) do
    handler_functions = generate_handler_functions(otp_app)

    contents =
      quote location: :keep do
        @behaviour :elli_handler

        def handle(request, _args) do
          handle(:elli_request.method(request), :elli_request.path(request), request)
        end

        unquote(handler_functions)

        def handle_event(_event, _data, _args), do: :ok

        defp wrap_response({code, headers, response} = resp, _, _)
             when is_integer(code) and is_list(headers) and is_binary(response),
             do: resp

        defp wrap_response({:ok, headers, response}, success, _)
             when is_list(headers) and is_binary(response),
             do: {success, headers, response}

        defp wrap_response({code, headers, response}, _, _)
             when is_integer(code) and is_list(headers),
             do: {code, headers, Jason.encode!(response)}

        defp wrap_response({:ok, headers, response}, success, _)
             when is_list(headers),
             do: {success, headers, Jason.encode!(response)}

        defp wrap_response({:ok, response}, success, _)
             when is_binary(response),
             do: {success, [], response}

        defp wrap_response({:ok, response}, success, _),
          do: {success, [], Jason.encode!(response)}

        defp wrap_response({:error, response}, _, error)
             when is_binary(response),
             do: {error, [], response}

        defp wrap_response({:error, response}, _, error),
          do: {error, [], Jason.encode!(response)}

        defp wrap_response(response, success, _)
             when is_binary(response),
             do: {success, [], response}

        defp wrap_response(response, success, _),
          do: {success, [], Jason.encode!(response)}
      end

    api
    |> Module.concat(Handler)
    |> Module.create(contents, Macro.Env.location(__ENV__))

    :ok
  end

  defp generate_handler_functions(app) do
    contents =
      for %{
            args: arg_type,
            function: function,
            method: method,
            module: module,
            path: path,
            success_code: success,
            error_code: error
          } <-
            get_routes(app) do
        req_var = Macro.var(:req, __MODULE__)
        path_var = variablize_path(path)
        path_var_map = path_var_map(path)

        quote location: :keep do
          def handle(unquote(method), unquote(path_var), unquote(req_var)) do
            req = Maverick.Request.new(unquote(req_var), unquote(path_var_map))
            args = Maverick.Request.args(req, unquote(arg_type))

            unquote(module)
            |> apply(unquote(function), [args])
            |> wrap_response(unquote(success), unquote(error))
          end
        end
      end

    quote location: :keep, bind_quoted: [contents: contents], do: contents
  end

  defp get_routes(app) do
    :application.get_key(app, :modules)
    |> filter_router_modules()
    |> collect_route_info()
  end

  defp filter_router_modules({:ok, modules}) do
    Enum.filter(modules, fn module ->
      module
      |> to_string
      |> String.ends_with?(".Maverick.Router")
    end)
  end

  defp collect_route_info(modules) do
    Enum.reduce(modules, [], fn module, acc ->
      acc ++ apply(module, :routes, [])
    end)
  end

  defp variablize_path(path) do
    Enum.map(path, fn element ->
      case element do
        {:variable, variable} ->
          variable
          |> String.to_atom()
          |> Macro.var(__MODULE__)

        _ ->
          element
      end
    end)
  end

  defp path_var_map(path) do
    entries =
      Enum.reduce(path, [], fn element, acc ->
        case element do
          {:variable, variable} ->
            value = variable |> String.to_atom() |> Macro.var(__MODULE__)
            [{variable, value} | acc]

          _ ->
            acc
        end
      end)

    {:%{}, [], entries}
  end
end
