# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Loyalty.Repo.insert!(%Loyalty.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Loyalty.Accounts

# create admin user
# remember to change user details
admin_user = %{ first_name: "Admin",
                last_name: "User",
                email: "admin@mail.com",
                password: "Secret!@34",
                user_role: :admin
              }
Accounts.register_with_email_password(admin_user)
