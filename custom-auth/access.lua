local _M = { conf = {} }
local http = require "resty.http"
local pl_stringx = require "pl.stringx"
local cjson = require "cjson.safe"


function _M.error_response(res_body, status)
    ngx.header['Content-Type'] = 'application/json'
    ngx.status = status
    ngx.say(res_body)
    ngx.exit(status)
end

function _M.introspect_access_token(access_token)
    local httpc = http:new()
    -- validate the token
    local res, err = httpc:request_uri(_M.conf.introspection_endpoint, {
        method = "GET",
        ssl_verify = false,
        headers = { ["Content-Type"] = "application/json",
            ["Authorization"] = access_token,
        }
    })
    local res_data = cjson.decode(res.body)
    if not res then
        return { status = 0, error = err, body = '{}' }
    end
    if res.status ~= 200 then
        return { status = res.status, error = err, body = res.body }
    end
    return { status = res.status, body = res_data }
end

function _M.run(conf)
    _M.conf = conf
    if not string.match(ngx.var.uri, "api/v1/auth") then
        local access_token = ngx.req.get_headers()[_M.conf.token_header]
        if not access_token then
            local response_data = '{"status": "ERROR"'
                    .. ',"code": ' .. ngx.HTTP_UNAUTHORIZED
                    .. ',"message": "Missing Authorization token."'
                    .. ',"data": {}}'
            _M.error_response(response_data, ngx.HTTP_UNAUTHORIZED)
        end

        local res = _M.introspect_access_token(access_token)
        if not res then
            local response_data = '{"status": "ERROR"'
                    .. ',"code": ' .. ngx.HTTP_INTERNAL_SERVER_ERROR
                    .. ',"service": "Authorization server error."'
                    .. ',"data": {}}'
            _M.error_response(response_data, ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
        if res.status ~= 200 then
            _M.error_response(res.body, res.status)
        end
        ngx.req.set_header("X-Header-Name", res.body.name)
        ngx.req.clear_header(_M.conf.token_header)
    end
end

return _M
