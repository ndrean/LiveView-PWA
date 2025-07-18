defmodule LiveviewPwaWeb.StockYjsLive do
  @moduledoc """
  LiveView for the stock_yjs page.
  """

  use LiveviewPwaWeb, :live_view
  # alias Phoenix.PubSub
  alias LiveviewPwaWeb.{Menu, PwaLiveComp, Users}

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      :if={@env === :prod}
      module={PwaLiveComp}
      id="pwa_action-yjs"
      update_available={@update_available}
    />
    <br />
    <Users.display user_id={@user_id} module_id="users-yjs" />
    <Menu.display active_path={@active_path} />
    <br />
    <div
      id="hook-yjs-sql3"
      phx-hook="StockYjsChHook"
      phx-update="ignore"
      data-userid={@user_id}
      data-max={@max}
    >
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "YjsCh")}
  end
end
