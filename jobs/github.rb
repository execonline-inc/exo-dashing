require 'octokit'

class Octokit::Client
  public :request
end


def run
  #page = 1
  #repositories = client.organization_repositories(organization, page:page)
  #repository = repositories.first
  #average_pr_life(repository_name: repository_name)
end


def client
  client = Octokit::Client.new(access_token: token)
end

def organization
  "execonline-inc"
end

def repository_name
  "#{organization}/exec_online"
end

def start_time
  Time.parse("2016-9-30 17:58:57 -0700")
end

def prs(repository_name)
  puts "Retrieving pull requests created before #{start_time}"
  page = 1
  pull_requests = []
  while true
    puts "Reading page #{page} of pull requests from github for #{repository_name}"
    p = client.pull_requests(
      repository_name,
      state: "closed",
      per_page: 20,
      page: page
    )
    break if p.empty?
    break if p.all? { |pr| pr.created_at < start_time }
    page = page + 1;
    pull_requests = pull_requests + p
  end

  recent(pull_requests)
end

def recent(pull_requests)
  puts "Extracting relevant pull requests"
  recent = pull_requests.
    select{|p| p.closed_at? || p.merged_at?}.
    select{|p|p.created_at > start_time}.
    select{|pr|pr[:base][:ref] == "master" || pr[:base][:ref] == "staging" }
  puts "#{recent.count} relevant PR's"
  recent
end

def average_pr_life(options)
  repository_name = options[:repository_name]
  pull_requests = prs(repository_name)

  puts "Calculating PR longevity"
  times = pull_requests.collect do |pr|
    from =  pr.created_at
    to   =  pr.closed_at
    (to - from ) / 60 / 60
  end

  average = times.inject{ |sum, el| sum + el }.to_f / times.size
  puts "Average is #{average} hrs"
  average.round(2)
end

SCHEDULER.every '20s' do
  last_karma =  0;
  a = average_pr_life(repository_name: repository_name)
  puts "sending event #{a}"
  #send_event('karma', { current: a, last: last_karma })
  send_event('karma', { current: a })
end
