ngx.header.content_length = nil
if ngx.header.Location and ngx.header.Location:find('feigua.cn') then
    ngx.header.Location = ngx.var.login_url
end
