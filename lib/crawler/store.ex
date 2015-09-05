defmodule Cthulhu.Crawler.Store do
  require Logger

  defmodule UrlState do
    defstruct body: nil, is_seen: false
  end

  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
  end

  def add_url(url) do
    Agent.update(__MODULE__, &HashDict.put_new(&1, strip_extra_slashes(url), %UrlState{}))
  end

  def get_unseen_url do
    Agent.get_and_update(__MODULE__, fn dict ->
      result = dict 
                 |> Enum.into([])
                 |> Enum.find(fn(entry) ->
                      case entry do
                        {_, %UrlState{is_seen: false}} ->
                          true
                        _ ->
                          false
                      end
                    end)

      case result do
        nil ->
          {nil, dict} 

        {url, _} ->
          new_dict = dict |> HashDict.update!(url, fn(_) ->
                              %UrlState{is_seen: true} 
                            end)

          {url, new_dict}
      end

    end)
  end

  def update_url(url, body) do
    Agent.update(__MODULE__, &HashDict.update!(&1, url, fn(_) ->
      %UrlState{is_seen: true, body: body} 
    end)) 
  end

  defp strip_extra_slashes(url) do
    Regex.replace(~r/([^:]\/)\/+/, url, "\\1")
  end

end
