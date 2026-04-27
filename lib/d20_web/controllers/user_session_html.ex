defmodule D20Web.UserSessionHTML do
  use D20Web, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:d20, D20.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
