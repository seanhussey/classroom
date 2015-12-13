class GitHubUser
  include GitHub

  def initialize(client, id = nil)
    @client = client
    @id     = id
  end

  # Public
  #
  def login(options = {})
    with_error_handling { @client.user(@id, options).login }
  end

  # Public
  #
  def organization_memberships
    with_error_handling do
      @client.organization_memberships(state: 'active', headers: no_cache_headers)
    end
  end

  # Public
  #
  def user
    with_error_handling { @client.user(@id) }
  end
end
