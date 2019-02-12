require 'octokit'
require 'openssl'
require 'jwt'

# setup those env vars
dirtycop_installation_id = ENV.fetch('DIRTYCOP_INSTALLATION_ID')
dirtycop_app_id = ENV.fetch('DIRTYCOP_APP_ID')
dirtycop_app_key_path = ENV.fetch('DIRTYCOP_APP_KEY_PATH')
git_commit = ENV.fetch('GIT_COMMIT')
repo = ENV.fetch('REPO')
result_path = ENV.fetch('RESULT_PATH', 'result.json')

def jwt(dirtycop_app_key_path, dirtycop_app_id)
  private_pem = File.read(dirtycop_app_key_path)
  private_key = OpenSSL::PKey::RSA.new(private_pem)

  payload = {
    iat: Time.now.to_i,
    exp: Time.now.to_i + (10 * 60), # 10 minutes
    iss: dirtycop_app_id
  }

  JWT.encode(payload, private_key, "RS256")
end

token_client = Octokit::Client.new(bearer_token: jwt(dirtycop_app_key_path, dirtycop_app_id))
token_response = token_client.create_app_installation_access_token(dirtycop_installation_id)
token = token_response[:token]

result = JSON.parse(File.read(result_path))

annotations = [].tap do |a|
  result["files"].each do |file|
    file["offenses"].each do |offense|
      a << {
        path: file['path'],
        start_line: offense['location']['start_line'],
        end_line: offense['location']['last_line'],
        # TODO: those are rejected by github API sometimes
        # start_column: offense['location']['start_column'], 
        # end_column: offense['location']['last_column'],
        annotation_level: 'warning',
        message: offense['message']
      }
    end
  end
end

Octokit.default_media_type = 'application/vnd.github.antiope-preview+json'
client = Octokit::Client.new(access_token: token)

# create run
run = client.create_check_run(repo, 'Rubocop', git_commit)

# update with annotations (batch limit is 50 on GitHub side)
annotations.each_slice(50).each do |annotations_slice|
  run_params = {
    status: 'in_progress',
    output: {
      title: 'Rubo-dirtycop report',
      summary: "#{result['summary']['inspected_file_count']} file(s) inspected. Found #{result['summary']['offense_count']} problem(s).",
      annotations: annotations_slice
    }
  }

  begin
    client.update_check_run(repo, run[:id], run_params)
  rescue Octokit::UnprocessableEntity
    warn "Annotation failed to be created - #{run_params}"
  end
end

# complete run
finish_params = {
  status: 'completed',
  conclusion: result['summary']['offense_count'] == 0 ? 'success' : 'neutral',
  completed_at: Time.now
}
client.update_check_run(repo, run[:id], finish_params)
