defmodule Cthulhu.Crawler.Supervisor do
  use Supervisor

  alias Cthulhu.Crawler.Store
  alias Cthulhu.Crawler.Worker

  def start_link(num_crawlers) do
    Supervisor.start_link(__MODULE__, num_crawlers, name: __MODULE__)
  end

  def init(num_crawlers) do
    store    = [worker(Store, [])]
    crawlers = 1..num_crawlers |> Enum.map(fn x -> worker(Worker, [], id: "worker_#{x}") end)

    supervise(store ++ crawlers, strategy: :one_for_one)
  end

end
