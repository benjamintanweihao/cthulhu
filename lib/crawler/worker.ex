defmodule Cthulhu.Crawler.Worker do
  use GenServer
  require Logger

  alias Cthulhu.Crawler.Store

  @timeout 5000

  #######
  # API #
  #######

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def crawl(pid, url) do
    GenServer.cast(pid, {:crawl, url})
  end

  #############
  # Callbacks #
  #############

  def init(:ok) do
    :timer.send_after(0, :poll)
    {:ok, []}
  end

  def handle_cast({:crawl, url}, _state) do
    Logger.info "#{inspect self} crawling: #{url}"

    case fetch_page(url) do
      {:ok, body} ->
        case URI.parse(url) do
          %URI{path: path} ->

            links = extract_links(url, body)

            Enum.each(links, &Store.add_url(&1))
            Store.update_url(url, body)

            :timer.send_after(@timeout, self, :poll)
            {:noreply, links}

          _ ->
            :timer.send_after(0, :poll)
            {:noreply, []}
        end

      {:error, _reason} ->
        :timer.send_after(0, :poll)
        {:noreply, []}
    end
  end

  def handle_info(:poll, state) do
    case Store.get_unseen_url do
      nil ->
        Logger.info "#{inspect self} polling"

        :timer.send_after(@timeout, self, :poll)

      url ->
        crawl(self, url)
    end

    {:noreply, state}
  end

  #####################
  # Private Functions #
  #####################

  defp fetch_page(url) do
    case HTTPoison.get(url, [], [hackney: [follow_redirect: true]]) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in 200..299 ->
        {:ok, body} 

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      _ ->
        {:error, :unknown} 

    end
  end

  defp extract_links(host, page) do
    result = ~r/<a[^>]* href="([^"]*)"/ |> Regex.scan(page) 
    links = case is_list(result) do
      true  -> result |> Enum.map(fn [_,x] -> x end)
      false -> []
    end

    links 
      |> Enum.map(&normalize_link(host, &1))
      |> Enum.reject(&is_nil(&1))
      |> Enum.uniq
  end

  defp normalize_link(host, url) do
    case URI.parse(url) do
      %URI{host: nil, path: nil} -> 
        nil

      %URI{host: nil, path: path} when is_binary(path) ->
        host <> path

      %URI{host: host, path: nil} when is_binary(host) ->
        host

      %URI{host: host, path: path} when is_binary(host) and is_binary(path) ->
        "#{host}#{path}"

      _ -> 
        nil
    end
  end

end
