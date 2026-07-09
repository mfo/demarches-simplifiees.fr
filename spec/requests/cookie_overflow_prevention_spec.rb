# frozen_string_literal: true

RSpec.describe "Cookie overflow prevention on auth failure", type: :request do
  # An unauthenticated GET to an authenticate_user!-protected route with a huge
  # query string makes Devise::FailureApp try to store `user_return_to` = the
  # full attempted path. Without the size cap that overflows the 4 KB session
  # cookie; with it, the oversized location is skipped and the request stays clean.
  it "redirects to sign in without storing an oversized return_to" do
    huge_query = "x=#{'a' * 4000}"

    get "/profil?#{huge_query}"

    expect(response).to redirect_to(new_user_session_path)
    expect(session["user_return_to"]).to be_nil
  end

  it "still stores a normal-size return_to" do
    get "/profil?statut=en-cours"

    expect(response).to redirect_to(new_user_session_path)
    expect(session["user_return_to"]).to eq("/profil?statut=en-cours")
  end
end
