defmodule Cthulhu.Crawler.Supervisor do
  use Supervisor

  alias Cthulhu.Crawler.Worker

  def start_link(num_crawlers) do
    Supervisor.start_link(__MODULE__, num_crawlers, name: __MODULE__)
  end

  def init(num_crawlers) do
    opts = [
      strategy: :one_for_one
    ]

    children = 1..num_crawlers |> Enum.map(fn x -> worker(Worker, [], id: "worker_#{x}") end)

    supervise(children, opts)
  end

end
