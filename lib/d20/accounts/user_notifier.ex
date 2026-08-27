defmodule D20.Accounts.UserNotifier do
  import Swoosh.Email

  alias D20.Accounts.User
  alias D20.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from(config!(:from))
      |> reply_to(config!(:reply_to))
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(%User{email: nil}, _url),
    do: {:error, :email_not_available}

  def deliver_update_email_instructions(%User{email: email}, url) do
    deliver(email, "Update email instructions", """

    ==============================

    Hi #{email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(%User{email: nil}, _url),
    do: {:error, :email_not_available}

  def deliver_login_instructions(%User{confirmed_at: nil} = user, url),
    do: deliver_confirmation_instructions(user, url)

  def deliver_login_instructions(%User{} = user, url),
    do: deliver_magic_link_instructions(user, url)

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @spec config!(:from | :reply_to) :: {String.t(), String.t()}
  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
