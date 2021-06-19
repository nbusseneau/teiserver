defmodule Teiserver.EmailHelper do
  @moduledoc false
  alias Central.Account
  alias Central.Mailer
  alias Bamboo.Email
  require Logger

  def new_user(user) do
    host = Application.get_env(:central, CentralWeb.Endpoint)[:url][:host]
    website_url = "https://#{host}"
    verification_code = user.data["verification_code"]

    {:ok, code} =
      Account.create_code(%{
        value: UUID.uuid4(),
        purpose: "reset_password",
        expires: Timex.now() |> Timex.shift(hours: 24),
        user_id: user.id
      })

    host = Application.get_env(:central, CentralWeb.Endpoint)[:url][:host]
    url = "https://#{host}/password_reset/#{code.value}"

    game_name = Application.get_env(:central, Teiserver)[:game_name]

    discord =
      case Application.get_env(:central, Teiserver)[:discord] do
        nil ->
          ""

        d ->
          "If you have any questions please get in touch through the <a href=\"#{d}\">discord</a>."
      end

    html_body = """
    <p>Welcome to #{game_name}.</p>

    <p>To verify your account you will need this code:: <span style="font-family: monospace">#{
      verification_code
    }</span>.<p>

    <p>This client also has a <a href="#{website_url}">website</a> component. Due to the way passwords are generated by the lobby (the program you signed up with) the password is not able to be replicated for the website. We have generated a password reset code for you <a href="#{
      url
    }">#{url}</a> which you will need to make use of to use the site.<p>

    <p>#{discord}</p>
    """

    text_body = """
    Welcome to #{game_name}.

    You will be asked for a verification code, it is: #{verification_code}.

    This client also has a website component at #{website_url}. Due to the way passwords are generated by the lobby (the program you signed up with) the password is not able to be replicated for the website. We have generated a password reset code for you: #{
      url
    }. You will need to make use of it to use the site.<p>

    #{discord}
    """

    Email.new_email()
    |> Email.to({user.name, user.email})
    |> Email.from({"BAR Teiserver", Mailer.noreply_address()})
    |> Email.subject("BAR - New account")
    |> Email.html_body(html_body)
    |> Email.text_body(text_body)
    |> Mailer.deliver_now(response: true)
  end

  def spring_password_reset(user, plain_password) do
    html_body = """
    <p>As per the spring protocol your password is being emailed to you, it is: #{plain_password}.</p>

    <p>This password will also work on the main site</p>
    """

    text_body = """
    As per the spring protocol your password is being emailed to you, it is: #{plain_password}.

    This password will also work on the main site
    """

    Email.new_email()
    |> Email.to({user.name, user.email})
    |> Email.from({"BAR Teiserver", Mailer.noreply_address()})
    |> Email.subject("BAR - Spring password reset")
    |> Email.html_body(html_body)
    |> Email.text_body(text_body)
    |> Mailer.deliver_now()
  end

  def password_reset(user, _plain_password) do
    Central.Account.UserLib.reset_password_request(user)
    |> Central.Mailer.deliver_now()

    # Logger.error("password_reset not implemented at this time")
    # to = user.email
    # subject = "Password reset - Teiserver"

    # body = """
    #   Your code is XXX
    # """
  end
end
