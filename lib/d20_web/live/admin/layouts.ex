defmodule D20Web.Admin.Layouts do
  @moduledoc """
  Layouts shared by the protected administration area.
  """

  use D20Web, :html

  @doc """
  Renders the protected catalog administration shell.
  """
  def admin(assigns) do
    ~H"""
    <Backpex.HTML.Layout.app_shell
      socket={@socket}
      fluid={@fluid?}
      live_resource={@live_resource}
      sidebar_open={@sidebar_open}
      preferences_manifest={@preferences_manifest}
      class="[--sidebar-width:17rem]"
    >
      <:topbar class="gap-3">
        <div class="flex min-w-0 flex-1 items-center gap-3">
          <span class="badge badge-outline badge-sm">Operations</span>
          <p class="truncate text-sm text-base-content/70">{@current_user.username}</p>
        </div>
        <Backpex.HTML.Layout.theme_selector
          current_theme={@current_theme}
          themes={[{"Light", "light"}, {"Dark", "dark"}]}
        />
        <.link href={~p"/"} class="btn btn-ghost btn-sm">Home</.link>
        <.link href={~p"/users/log-out"} method="delete" class="btn btn-neutral btn-sm">
          Log out
        </.link>
      </:topbar>

      <:sidebar_branding>
        <Backpex.HTML.Layout.sidebar_branding title="D20 Admin">
          <:logo>
            <img src={~p"/images/logo.svg"} alt="" class="size-7" />
          </:logo>
        </Backpex.HTML.Layout.sidebar_branding>
      </:sidebar_branding>

      <:sidebar>
        <Backpex.HTML.Layout.sidebar_section
          id="catalog"
          sidebar_section_states={@sidebar_section_states}
        >
          <:label>Catalog</:label>
          <Backpex.HTML.Layout.sidebar_item
            current_url={@current_url}
            navigate={~p"/dashboard"}
          >
            <.icon name="hero-squares-2x2" class="size-5" /> Games
          </Backpex.HTML.Layout.sidebar_item>
        </Backpex.HTML.Layout.sidebar_section>
      </:sidebar>

      <Backpex.HTML.Layout.flash_messages flash={@flash} />
      {render_slot(@inner_block)}
    </Backpex.HTML.Layout.app_shell>
    """
  end
end
