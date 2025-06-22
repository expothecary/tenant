defmodule Tenant.MySQLTestRepo do
  use Ecto.Repo, otp_app: :tenant, adapter: Ecto.Adapters.MyXQL
end
