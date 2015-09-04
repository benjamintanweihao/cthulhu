defmodule Cthulhu do
  use Application

  def start(_type, _args) do
    Cthulhu.Crawler.Supervisor.start_link(5)
  end
end
