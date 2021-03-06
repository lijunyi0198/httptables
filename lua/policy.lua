-- httptables startup

local _M = {}

local ngx = require "ngx"
local cjson = require "cjson"
local redis_api = require "redis_api"
local config = require "config"
local utils = require "utils"
local http = require "http"

shared_role_types = {}
shared_roles = {}
shared_version_counter = 0
shared_sync_pending = false
shared_mark_funcions = {}
sorted_role_types = {}

function _M.try_reload_policy()
    local center_version_counter = _M.get_center_version_counter()
    if _M.get_shared_version_counter() < center_version_counter and not shared_sync_pending then
        shared_sync_pending = true
        local ret = _M.load_policy_from_http()
        if ret then
            _M.set_shared_version_counter(center_version_counter)
            ngx.log(ngx.INFO, "[try_reload_policy] shared_version_counter: ", _M.get_shared_version_counter(),
                              ", center_version_counter:", _M.get_center_version_counter())
            --cache lamda
            for _,role_type in pairs(shared_role_types) do
                shared_mark_funcions[role_type.name] = loadstring(role_type.lamda)
            end
            --reorganize role_type and role
            sorted_role_types = utils.deep_copy(shared_role_types)
            sorted_roles = utils.deep_copy(shared_roles)
            local role_type_comps = function (a, b)
                return a.priority < b.priority
            end
            local role_comps = function (a, b)
                return a.createtime < b.createtime
            end
            table.sort(sorted_role_types, role_type_comps)
            table.sort(sorted_roles, role_comps)
            for _,role in pairs(sorted_roles) do
                local timestamp = ngx.now()
                if role.expired > timestamp then
                    local role_type_name = role["type"]
                    local role_type_domain = role["domain"]
                    for _,role_type in pairs(sorted_role_types) do
                        if role_type_name == role_type.name and role_type_domain == role_type.domain then
                            if not role_type.hash then
                                role_type.hash = {}
                            end
                            role_type.hash[role.mark] = role
                        end
                    end
                end
            end
        end
        shared_sync_pending = false
    end
end

function _M.get_roles()
    return shared_roles
end

function _M.get_role_types()
    return shared_role_types
end

function _M.get_sorted_role_types()
    return sorted_role_types
end

function _M.get_shared_mark_functions()
    return shared_mark_funcions
end

function _M.get_shared_version_counter(v)
    return shared_version_counter
end

function _M.set_shared_version_counter(v)
    shared_version_counter = v
end

function _M.increase_center_version_counter()
    local counter = _M.get_center_version_counter()
    counter = counter + 1
    _M.set_center_version_counter(counter)
end

function _M.set_center_version_counter(v)
    local data = ngx.shared.data
    data:set("center_version_counter", v)
end

function _M.get_center_version_counter()
    local data = ngx.shared.data
    return data:get("center_version_counter")
end

-- load config to lua_shared_dict from Redis
function _M.load_policy_from_redis()
    ngx.log(ngx.INFO, "[policy] load_policy_from_redis")
    local rds, err = redis_api.open_redis()
    if not rds then
        ngx.log(ngx.ERR, "connect redis failed")
        return false
    end

    local role_types, err = rds:hget("__httptables__", "role_types")
    if role_types == ngx.null or not role_types then
        ngx.log(ngx.ERR, "read [role_types] from redis failed")
        return false
    end

    local roles, err = rds:hget("__httptables__", "roles")
    if roles == ngx.null or not roles then
        ngx.log(ngx.ERR, "read [roles] from redis failed")
        return false
    end

    local data = ngx.shared.data
    shared_role_types = cjson.decode(role_types)
    shared_roles = cjson.decode(roles)
    return true
end

-- load config to lua_shared_dict from HTTP
function _M.load_policy_from_http()
    ngx.log(ngx.INFO, "[policy] load_policy_from_http")
    local data = ngx.shared.data
    local httpc = http.new()
    local role_types, roles

    local res, err = httpc:request_uri(config.http_endpoint.role_types, {})
    if not res then
        ngx.log(ngx.ERR, "[load_policy_from_http] request_uri role_types failed: ", err)
        return false
    end
    if res.status == ngx.HTTP_OK then
        role_types = cjson.decode(res.body)
    else
        ngx.log(ngx.ERR, "[load_policy_from_http] role_types:", res.status, ", reason:", res.reason)
        return false
    end
    shared_role_types = utils.deep_copy(role_types.result or role_types) or {}

    res, err = httpc:request_uri(config.http_endpoint.roles, {})
    if not res then
        ngx.log(ngx.ERR, "[load_policy_from_http] request_uri roles failed")
        return false
    end
    if res.status == ngx.HTTP_OK then
        roles = cjson.decode(res.body)
    else
        ngx.log(ngx.ERR, "[load_policy_from_http] roles:", res.status, ", reason:", res.reason)
        return false
    end
    shared_roles = utils.deep_copy(roles.result or roles) or {}

    return true
end

return _M
