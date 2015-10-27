crud = require('../core/crud.coffee')

RES_TYPE_RE = "([A-Za-z]+)"
ID_RE = "([A-Za-z0-9\\-]+)"

ROUTES =
  resource_instance: new RegExp("^/#{RES_TYPE_RE}/#{ID_RE}$")
  resource_instance_rev: new RegExp("^/#{RES_TYPE_RE}/#{ID_RE}/_history/#{ID_RE}$")
  resource_instance_hist: new RegExp("^/#{RES_TYPE_RE}/#{ID_RE}/_history$")
  resource: new RegExp("^/#{RES_TYPE_RE}$")
  resource_hist: new RegExp("^/#{RES_TYPE_RE}/_history$")
  hist: new RegExp("^/_history$")

# TODO:
# - conditional update
# - conditional delete
makePlan = (bundle) ->
  bundle.entry.map (entry) ->
    url = entry.request.url
    method = entry.request.method
    action = null
    match = null
    matchType = null

    for type, re of ROUTES
      match = url.match(re)

      if match
        matchType = type
        break

    if match && matchType
      switch matchType
        when 'resource_instance'
          if method == 'GET'
            action =
              type: 'read'
              resourceId: match[2]
              resourceType: match[1]

          else if method == 'PUT'
            action =
              type: 'update'
              resourceId: match[2]
              resourceType: match[1]
              resource: entry.resource

          else if method == 'DELETE'
            action =
              type: 'delete'
              resourceId: match[2]
              resourceType: match[1]

        when 'resource_instance_rev'
          if method == 'GET'
            action =
              type: 'vread'
              resourceId: match[2]
              resourceType: match[1]
              versionId: match[3]

        when 'resource'
          if method == 'POST'
            action =
              type: 'create'
              resource: entry.resource
              resourceType: match[1]

        when 'resource_instance_hist'
          if method == 'GET'
            action =
              type: 'history'
              resourceType: match[1]
              resourceId: match[2]

        when 'resource_hist'
          if method == 'GET'
            action =
              type: 'history'
              resourceType: match[1]

        when 'hist'
          if method == 'GET'
            action =
              type: 'history'

    if !action
      action =
        type: 'error'
        message: "Cannot determine action for request #{method} #{url}"

    action

executePlan = (plv8, plan) ->
  plan.map (action) ->
    switch action.type
      when "create"
        crud.create(plv8, action.resource)
      when "update"
        resource = action.resource
        resource.resourceType = action.resourceType
        resource.id = action.resourceId

        crud.update(plv8, resource)
      when "delete"
        crud.delete(plv8, {id: action.resourceId, resourceType: action.resourceType})
      when "read"
        crud.read(plv8, {id: action.resourceId, resourceType: action.resourceType})
      when "vread"
        crud.vread(plv8, {id: action.resourceId, resourceType: action.resourceType, versionId: action.versionId})
      else
        "TODO: return operation outcome here!\n#{action.message}"

exports.makePlan = makePlan
exports.executePlan = executePlan
