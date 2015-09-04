defmodule Cthulhu.Crawler.Worker do
  use GenServer

  @timeout 1000

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
    # send out of band message to self to kick start pooling ...
    :timer.send_after(0, :poll)
    {:ok, []}
  end

  def handle_cast({:crawl, url}, _state) do
    case fetch_page(url) do
      {:ok, body} ->
        case URI.parse(url) do
          %URI{host: host} when is_binary(host) ->
            links = extract_links(host, body)
            # TODO: Add to store
            :timer.send_after(0, self, :poll) 
            IO.puts "#{inspect self} crawling done!"
            {:noreply, links}

          _ ->
            {:noreply, []}
        end

      {:error, _reason} ->
        {:noreply, []}
    end
  end

  def handle_info(:poll, state) do
    if :random.uniform < 0.50 do
      IO.puts "#{inspect self} crawling ..."
      crawl(self, "https://en.wikipedia.org/wiki/Main_Page")
    else
      IO.puts "#{inspect self} polling ..."
      :timer.send_after(@timeout, self, :poll) 
    end

    {:noreply, state}
  end

  #####################
  # Private Functions #
  #####################

  def fetch_page(url) do
    case HTTPoison.get(url) do
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

  def extract_links(host, page) do
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

  def normalize_link(host, url) do
    case URI.parse(url) do
      %URI{host: nil, path: nil} -> 
        nil

      %URI{host: nil, path: path} when is_binary(path) -> 
        host <> path

      %URI{host: host, path: path} -> 
        "#{host}#{path}"

      _ -> 
        nil
    end
  end

end
