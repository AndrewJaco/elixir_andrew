defmodule ElixirAndrewWeb.Router do
  use ElixirAndrewWeb, :router

  import ElixirAndrewWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirAndrewWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirAndrewWeb do
    pipe_through :browser

    live_session :themed_public, on_mount: [{ElixirAndrewWeb.UserAuth, :mount_current_user}, {ElixirAndrewWeb.ThemeHook, :default}] do
      live "/", HomeLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ElixirAndrewWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:elixir_andrew, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirAndrewWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ElixirAndrewWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {ElixirAndrewWeb.UserAuth, :redirect_if_user_is_authenticated}, 
        {ElixirAndrewWeb.ThemeHook, :default}
        ] do
      live "/users/log_in", User.UserLoginLive, :new
      live "/users/reset_password", User.UserForgotPasswordLive, :new
      live "/users/reset_password/:token", User.UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ElixirAndrewWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {ElixirAndrewWeb.UserAuth, :ensure_authenticated},
        {ElixirAndrewWeb.ThemeHook, :default}
        ] do
      live "/dashboard", Admin.DashboardLive
      live "/student/home", Student.StudentHomeLive
      live "/users/register", User.UserRegistrationLive, :new_student
      live "/teachers/register", User.UserRegistrationLive, :new_teacher
      live "/users/:user_id/progress/new", User.UserProgressLive.New, :new
      live "/users/settings/confirm_email/:token", User.UserSettingsLive, :confirm_email
    end

  end
  
scope "/", ElixirAndrewWeb do
    pipe_through [:browser, :require_authenticated_user]

  live_session :scrollable_authenticated_user, 
    layout: {ElixirAndrewWeb.Layouts, :scrollable}, 
    on_mount: [
      {ElixirAndrewWeb.UserAuth, :ensure_authenticated}, 
      {ElixirAndrewWeb.ThemeHook, :default}
      ] do
      live "/users/settings", User.UserSettingsLive, :edit
  end
end

  scope "/", ElixirAndrewWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ElixirAndrewWeb.UserAuth, :mount_current_user}, {ElixirAndrewWeb.ThemeHook, :default}] do
      live "/users/confirm/:token", User.UserConfirmationLive, :edit
      live "/users/confirm", User.UserConfirmationInstructionsLive, :new
    end
  end
end
