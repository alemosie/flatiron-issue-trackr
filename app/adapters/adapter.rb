module Adapter

  class GitHubWrapper
    # gets all issues of given repo and using them to create new issues associated to that repo

    attr_accessor :repo

    def initialize(repo)
      @client ||= Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
      @repo = repo
    end

    def create_issues
      @client.repo("#{repo.user.github_username}/#{repo.name}") # don't need to use instance var because of attr accessor
      @client.issues("#{repo.user}/#{repo.name}").each do |issue|
        Issue.create(url: issue.html_url, opened_by: issue.user.login, status: issue.state, title: issue.title, content: issue.body, opened_on: issue.created_at, assignee: issue.assignee, repository: repo)
      end
    end

    # creating a webhook on a given repo (we tell the repo to send us a post request to our app when the repo is changed/new issue is created)

    def create_webhook
      @client.create_hook("#{repo.user.github_username}/#{repo.name}",
        'web',
        {url: "#{ENV['ISSUE_TRACKR_APP_URL']}/webhooks/receive", content_type: 'json'},
        {events: ['issues'], active: true})
    end
  end

  class TwilioWrapper

    attr_accessor :issue

    def initialize(issue)
      @client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
      @issue = issue
    end

    def create_issue_text
      @client.messages.create(
        to: issue.repository.user.phone_number,
        from: "+1 #{ENV['TWILIO_NUMBER']}",
        body: "#{issue.title} has been updated. View it here: #{issue.url}")
    end
  end

end
