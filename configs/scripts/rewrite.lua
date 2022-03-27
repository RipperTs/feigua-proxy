local function reject (code)
    if ngx.req.get_headers()['X-Requested-With'] then
        ngx.say('{"Status":402,"Message":"登陆超时","Button":"重新登陆","Url":"' .. ngx.var.login_url .. '"}')
        ngx.exit(ngx.HTTP_OK)
    else
        ngx.redirect(ngx.var.login_url..'?code='..code, 302)
    end
end

-- 定义请求头
local headers=ngx.req.get_headers()
-- 获取客户端ip
local client_ip=headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"

-- 错误提示盒子
local function render (text)
    return '<div style="display: flex;height:30vh;align-items: center;width:100%;justify-content: center;"><span style="margin: auto; font-size: 18px;">'..text..'</span></div>'
end

-- 发送http请求
local function HttpUtil(url)
	local http = require('resty.http')
        local httpc = http.new()
        local res, err = httpc:request_uri(url, {
            keepalive_timeout = 3000 -- 毫秒
        })
end

-- init cookie
local ck = require 'cookie'
local cookie, err = ck:new()

-- init redis
local rds = require 'resty.redis'
local redis = rds:new()
redis:connect('127.0.0.1', 6379)

-- get user
local session_id = cookie:get('session_id')
if not session_id then
    ngx.log(ngx.DEBUG, 'no session id')
    reject(1001)
end
local user_id = cookie:get('user_id')
if not user_id then
    ngx.log(ngx.DEBUG, 'no user id')
    reject(1002)
end
local res = redis:get('ineundo:user.id:'..user_id..':session.id')
if res ~= session_id then
    ngx.log(ngx.DEBUG, 'session id and user id not match')
    reject(1003)
end

-- local client_ip = get_client_ip()

-- 检查账号是否被锁定
local isBackUser = redis:get('ineundo:back_user_id:'..user_id)
if isBackUser == '1' then
    ngx.header.content_type = 'text/plain; charset=utf-8'
    ngx.say(render('您的账号已被管理员锁定!'))
    ngx.exit(ngx.HTTP_OK)
end

-- frequence limit
if ngx.var.limit == '1' and ngx.var.uri ~= '/LiveLargeScreen/getroomInfo' and ngx.var.uri ~= '/LiveLargeScreen/GetRoomSalesStat' and ngx.var.uri ~= '/Home/GetUserNotice' then
    local dailyLimit = 3000
    local dailyKey = 'ineundo:ip:'..ngx.var.ip..':platform:'..ngx.var.platform..':user.id:'..user_id..':date:'..os.date('%Y%m%d')..':view.count'
    local dailyCount = redis:incr(dailyKey)
    redis:expire(dailyKey, 86400)
    if dailyCount > dailyLimit then
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say(render('访问太频繁，请明天再来吧！'))
        ngx.exit(ngx.HTTP_OK)
    end

    --   所有页面限制
    local hourlyLimit = 200
    local hourlyKey = 'ineundo:ip:'..ngx.var.ip..':platform:'..ngx.var.platform..':user.id:'..user_id..':datetime:'..os.date('%Y%m%d%H')..':view.count'
    local hourlyCount = redis:incr(hourlyKey)
    redis:expire(hourlyKey, 3600)
    if hourlyCount > hourlyLimit then
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say(render('访问太频繁，请关闭所有页面，1小时后再来吧！'))
        ngx.exit(ngx.HTTP_OK)
    end

--     播主查找页面限制
    local pathlyBzLimit = 200
        if (ngx.var.uri == '/BloggerSearch/Search') then
--         这个页面每次请求计次3次 限制20次共计次60次
            pathlyBzLimit = 150
        end
        local pathBzlyKey = 'ineundo:ip:'..ngx.var.ip..':platform:'..ngx.var.platform..':user.id:'..user_id..':path:'..ngx.var.uri..':view.count'
        local pathBzlyCount = redis:incr(pathBzlyKey)
        redis:expire(pathBzlyKey, 7200)
        if pathBzlyCount > pathlyBzLimit then
            ngx.header.content_type = 'text/plain; charset=utf-8'
            ngx.say(render('此页面2小时限制查询50次,请稍后再试!'))
            ngx.exit(ngx.HTTP_OK)
        end

--  抖音直播详情页面限制(此页面一次2个请求)
    local pathlyLimit = 200
    if ngx.var.uri == '/BloggerNew/Loadbloggerlive' then
        pathlyLimit = 100
    end
    local pathlyKey = 'ineundo:ip:'..ngx.var.ip..':platform:'..ngx.var.platform..':user.id:'..user_id..':path:'..ngx.var.uri..':view.count'
    local pathlyCount = redis:incr(pathlyKey)
    redis:expire(pathlyKey, 3600)
    if pathlyCount > pathlyLimit then
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say(render('访问太频繁，请关闭所有页面，1小时后再来吧！'))
        ngx.exit(ngx.HTTP_OK)
    end

--  快手博主查找页面限制 (此页面一次2个请求)
    local pathlyKuaishouLimit = 200
    if ngx.var.uri == '/Blogger/Search' then
        pathlyKuaishouLimit = 400
    end
    local pathlyKuaishouKey = 'ineundo:ip:'..ngx.var.ip..':platform:'..ngx.var.platform..':user.id:'..user_id..':path:'..ngx.var.uri..':view.count'
    local pathlyKuaishouCount = redis:incr(pathlyKuaishouKey)
    redis:expire(pathlyKuaishouKey, 3600)
    if pathlyKuaishouCount > pathlyKuaishouLimit then
        ngx.header.content_type = 'text/plain; charset=utf-8'
        ngx.say(render('访问太频繁，请关闭所有页面，1小时后再来吧！'))
        ngx.exit(ngx.HTTP_OK)
    end
end

-- get version
local versions = {}
local res = redis:hgetall('ineundo:user.id:'..user_id..':platforms')
for i = 1, #res, 2 do
    versions[res[i]] = res[i + 1]
end
local version = versions[ngx.var.platform]
if not version then
    ngx.log(ngx.DEBUG, 'no version')
    reject(1004)
end
local platform = ngx.var.platform..'.'..version

-- get account id
local account_id = redis:get('ineundo:user.id:'..user_id..':platform:'..platform..':account.id')
if account_id == ngx.null then
    -- get available account ids
    local account_ids = redis:lrange('ineundo:ip:'..ngx.var.ip..':platform:'..platform..':account.ids', 0, -1)
    if #account_ids == 0 then
        ngx.log(ngx.DEBUG, 'no account ids')
        reject(1005)
    end

    -- pick account
    local index = math.random(1, #account_ids)
    account_id = account_ids[index]
    redis:set('ineundo:user.id:'..user_id..':platform:'..platform..':account.id', account_id)
end

local cookie = redis:get('ineundo:account.id:'..account_id..':cookie')
if cookie == ngx.null then
    redis:del('ineundo:user.id:'..user_id..':platform:'..platform..':account.id')
    ngx.log(ngx.DEBUG, 'no cookie')
    reject(1006)
end

-- 记录访问日志
-- HttpUtil('http://119.167.182.119:9980/index.php?s=/api/statistics/lualog&ip='..client_ip..'&user_id='..user_id..'&path='..ngx.var.uri..'&user_agent='..ngx.req.get_headers()['user_agent'])

local platforms = {
    ['feigua.douyin'] = 'FEIGUA',
    ['feigua.kuaishou'] = 'KUAISHOU',
}
-- ngx.log(ngx.DEBUG,cookie..'|'..user_id)
ngx.req.set_header('Cookie', platforms[ngx.var.platform]..'='..cookie)
