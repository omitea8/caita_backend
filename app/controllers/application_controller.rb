class ApplicationController < ActionController::API
  private

  # ログインしているユーザーのcreator_idを取得
  def current_creator
    return unless session[:id]

    # TODO: APIモードでも@をつけた変数を使用するのかわからない
    @current_creator ||= Creator.find_by(id: session[:id])
  end

  # creator_idのログインを確認
  def logged_in
    !current_creator.nil?
  end
end
