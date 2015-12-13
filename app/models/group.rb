class Group < ActiveRecord::Base
  include GitHubTeamable

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :grouping

  belongs_to :grouping

  has_and_belongs_to_many :repo_accesses, before_add:    :add_member_to_github_team, unless: :new_record?,
                                          before_remove: :remove_from_github_team

  validates :github_team_id, presence: true
  validates :github_team_id, uniqueness: true

  validates :grouping, presence: true

  validates :title, presence: true
  validates :title, length: { maximum: 39 }

  before_validation(on: :create) do
    create_github_team if organization
  end

  before_destroy :silently_destroy_github_team

  private

  # Internal
  #
  def add_member_to_github_team(repo_access)
    user = repo_access.user

    github_team = GitHubTeam.new(organization.github_client, github_team_id)
    github_user = GitHubUser.new(user.github_client, user.uid)

    github_team.add_team_membership(github_user.login)
  end

  # Internal
  #
  def remove_from_github_team(repo_access)
    user = repo_access.user

    github_team = GitHubTeam.new(organization.github_client, github_team_id)
    github_user = GitHubUser.new(user.github_client, user.uid)

    github_team.remove_team_membership(github_user.login)
  end
end
