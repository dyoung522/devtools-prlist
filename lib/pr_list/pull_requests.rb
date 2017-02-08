require "octokit"

module PRlist
  class PullRequest
    attr_reader :issue

    def method_missing(method_sym, *arguments, &block)
      @issue.respond_to?(method_sym) ? @issue.send(method_sym, *arguments, &block) : super
    end

    def respond_to_missing?(method_name, include_private = false)
      @issue.respond_to?(method_name.to_sym) || super
    end

    def initialize(issue)
      @issue ||= issue
    end

    def date
      @issue.created_at
    end

    def has_label?(filter_by)
      labels.any? { |label| [filter_by].flatten.map { |l| l.downcase.strip }.include?(label.downcase.strip) }
    end

    def labels
      @issue.labels.map { |l| l.name }
    end

    def repo(opt = {})
      opt[:short] = false unless opt.has_key?(:short)

      /repos\/(\w*\/?(.*))$/.match(@issue.repository_url)[opt[:short] ? 2 : 1]
    end
  end

  class PullRequests
    attr_reader :pulls

    def initialize(token = nil, repos = [])
      @pulls  ||= []
      @github ||= __authenticate token

      repos.each { |repo| load!(repo) } if authorized?
    end

    def authorized?
      return !@github.nil?
    end

    def auth!(token)
      @github = __authenticate token
    end

    def load!(repo)
      raise NoAuthError, "You must authorized with github using #auth first" unless authorized?

      @github.issues(repo).each do |issue|
        __load_issue issue if issue.pull_request?
      end
    end

    def by_date
      sorted_pulls = @pulls.sort_by { |pr| pr.date }

      block_given? ? sorted_pulls.each { |pr| yield pr } : sorted_pulls
    end

    def repos
      @pulls.collect { |pr| pr.repo }.uniq
    end

    private

    def __load_issue(issue)
      @pulls.push PullRequest.new issue
    end

    def __authenticate(token)
      token ? Octokit::Client.new(access_token: token) : nil
    end

  end
end
