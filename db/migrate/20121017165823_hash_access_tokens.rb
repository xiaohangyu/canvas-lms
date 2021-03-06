class HashAccessTokens < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    loop do
      batch = AccessToken.connection.select_all(<<-SQL)
        SELECT id, token FROM access_tokens WHERE crypted_token IS NULL LIMIT 1000
      SQL

      break if batch.empty?

      batch.each do |at|
        updates = {
          :token_hint => at['token'][0,5],
          :crypted_token => AccessToken.hashed_token(at['token']),
        }
        AccessToken.update_all(updates, { :id => at['id'] })
      end
    end
  end

  def self.down
    AccessToken.update_all({ :crypted_token => nil, :token_hint => nil })
  end
end
