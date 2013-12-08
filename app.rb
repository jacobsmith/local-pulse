require "sinatra"
require "sinatra/activerecord"
require "octokit"

set :database, "sqlite3:///test.sqlite3"

class Repo < ActiveRecord::Base

end

get "/" do
  @repos = Repo.all.order("created_at desc")
  erb :index
end

post "/location" do
  location = params[:location]
  @repos = search_repos(location)
  redirect "/"
end

get "/location" do
  location = params[:location]
  @repos = search_repos(location)
  redirect "/"
end

private

def search_repos(location)
  Repo.delete_all

  developers_from_location(location).first(10).each do |dev|
    repos = repos_for_dev(dev, 2.months.ago)

    repos.each do |repo|
      saved_repo = Repo.create(name: repo.full_name, 
                               description: repo.description,
                               created_at: repo.created_at)
    end
  end
end

def developers_from_location(location)
  locations = location.split(",").map { |e| e.strip }
  locations_query = locations.map { |location| "location:#{location}" } 
  locations_query = locations_query.join(", ")
  Octokit.search_users("#{locations_query} repos:>0").items 
end

def repos_for_dev(dev, time_since)
  Octokit.repos(dev.login, {sort: :created}).find_all {|repo| repo.created_at >= time_since && !repo.fork }
end
