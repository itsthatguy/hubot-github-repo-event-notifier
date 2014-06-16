#! /usr/bin/env coffee

unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

extractMentionsFromBody = (body) ->
  mentioned = body.match(/(^|\s)(@[\w\-\/]+)/g)

  if mentioned?
    mentioned = mentioned.filter (nick) ->
      slashes = nick.match(/\//g)
      slashes is null or slashes.length < 2

    mentioned = mentioned.map (nick) -> nick.trim()
    mentioned = unique mentioned

    "\nMentioned: #{mentioned.join(", ")}"
  else
    ""

buildNewIssueOrPRMessage = (data, eventType, callback) ->
  pr_or_issue = data[eventType]
  action = data.action
  switch data.action
    when "opened"
      actionMsg = "New"
    when "reopened"
      actionMsg = "Reopened"
    when "closed"
      actionMsg = "Closed"
    else return

  mentioned_line = ''
  if pr_or_issue.body?
    mentioned_line = extractMentionsFromBody(pr_or_issue.body)
  callback "#{actionMsg} #{eventType.replace('_', ' ')} \"#{pr_or_issue.title}\" by #{pr_or_issue.user.login}: #{pr_or_issue.html_url}#{mentioned_line}"

module.exports =
  issues: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'issue', callback)

  pull_request: (data, callback) ->
    buildNewIssueOrPRMessage(data, 'pull_request', callback)

  issue_comment: (data, callback) ->
    callback "New issue comment on \"#{data.issue.title}\" by #{data.comment.user.login}: #{data.comment.html_url}"

  create: (data, callback) ->
    callback "Create a new branch '#{data.ref}': #{data.repository.html_url}/tree/#{data.ref}"

  push: (data, callback) ->
    unless data.deleted
      message = data.head_commit.message.replace(/(\n\n|\r\n|\n|\r)/gm," ")
      callback "New commit \"#{message}\" by #{data.head_commit.committer.username}: #{data.head_commit.url}"

  page_build: (data, callback) ->
    build = data.build
    if build?
      if build.status is "built"
        callback "#{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "Page build for #{data.repository.full_name} errored: #{build.error.message}."

