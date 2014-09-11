namespace :brakeman do
  task :run do
    if ENV['CIRCLECI'] == 'true'
      path = ENV['CIRCLE_ARTIFACTS'] || 'log'
      %x{bundle exec brakeman -o #{path}/brakeman.json -o #{path}/brakeman.html}
    end
  end
  task :notify do
    if ENV['CIRCLECI'] == 'true'
      %x{curl https://shopify-brakeman-dashboard.herokuapp.com/ping/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/#{ENV['CIRCLE_BUILD_NUM']}}
    end
  end
end
