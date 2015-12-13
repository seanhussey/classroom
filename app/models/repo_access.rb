class RepoAccess < ActiveRecord::Base
  include GitHubTeamable

  belongs_to :user
  belongs_to :organization, -> { unscope(where: :deleted_at) }

  has_many :assignment_repos

  has_and_belongs_to_many :groups

  validates :organization, presence: true
  validates :organization, uniqueness: { scope: :user }

  validates :user, presence: true
  validates :user, uniqueness: { scope: :organization }

  before_validation(on: :create) do
    if organization
      add_membership_to_github_organization
      accept_membership_to_github_organization
    end
  end

  before_destroy :silently_destroy_github_team
  before_destroy :silently_remove_organization_member

  private

  def add_membership_to_github_organization
    github_organization = GitHubOrganization.new(organization.github_client, organization.github_id)
    github_user         = GitHubUser.new(user.github_client, user.uid)

    github_organization.add_membership(github_user.login)
  end

  # Interal
  #
  def accept_membership_to_github_organization
    github_organization = GitHubOrganization.new(user.github_client, organization.github_id)
    github_user         = GitHubUser.new(user.github_client, user.uid)

    github_organization.accept_membership(github_user.login)
  rescue GitHub::Error
    silently_remove_organization_member
    raise GitHub::Error, 'Failed to add user to the Classroom, please try again'
  end

  def remove_organization_member
    github_organization = GitHubOrganization.new(organization.github_client, organization.github_id)
    github_organization.remove_organization_member(user.uid)
  end

  def silently_remove_organization_member
    remove_organization_member
    true # Destroy ActiveRecord object even if we fail to delete the repository
  end

  # Internal
  #
  def title
    GitHubUser.new(user.github_client, user.uid).login
  end
end
