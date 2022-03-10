--[[
    Ask not.bass#3945 for uncompressed verison if needed
]]

local vector = require "vector"
local trace  = require "gamesense/trace"

local scan_width, scan_length = 5, 120
local scan_result = nil

local mp = {"LUA", "B"}
local width_choices  = {"Exact", "Accurate", "Default", "Rough", "Very Rough"}
local length_choices = {"Very Near", "Near", "Default", "Far", "Very Far"}

local m = {
    label  = ui.new_label(mp[1], mp[2], " "),
    enable = ui.new_checkbox(mp[1], mp[2], "> Draw Hit-Angles"),
    width  = ui.new_slider(mp[1], mp[2], "Accuracy                   (Affects FPS)", 1, 5, 3, true, "", 1, width_choices),
    length = ui.new_slider(mp[1], mp[2], "Distance                   (Affects FPS)", 1, 5, 3, true, "", 1, length_choices),
    
    text_lbl = ui.new_label(mp[1], mp[2], "Text Color"),
    text_clr = ui.new_color_picker(mp[1], mp[2], "__Text Color", 255, 255, 255, 255),

    line_lbl = ui.new_label(mp[1], mp[2], "Line Color"),
    line_clr = ui.new_color_picker(mp[1], mp[2], "__Line Color", 255, 255, 255, 255),
}

-- compressed generalized help functions
local function table_visible(a,b)for c,d in pairs(a)do if type(a[c])=='table'then for e,d in pairs(a[c])do ui.set_visible(a[c][e],b)end else ui.set_visible(a[c],b)end end end
local function as_clr(b,c,d,e)if b==nil then return{r=255,g=255,b=255,a=255}elseif type(b)=="number"then return{r=math.floor(b)or 255,g=math.floor(c)or 255,b=math.floor(d)or 255,a=math.floor(e)or 255}elseif type(b)=="table"then return{r=math.floor(b[1])or 255,g=math.floor(b[2])or 255,b=math.floor(b[3])or 255,a=math.floor(b[4])or 255}else return error("[as_clr] Invalid Type : "..type(b))end end
local function handle_callback(b,c,d)local e=d and client.set_event_callback or client.unset_event_callback;e(b,c)end

-- compressed vector cancer for QOL & effeciency sake
local function vector_angles(b,c)local d,e;if c==nil then e,d=b,vector(client.eye_position())if d.x==nil then return end else d,e=b,c end;local f=e-d;if f.x==0 and f.y==0 then return 0,f.z>0 and 270 or 90 else local g=math.deg(math.atan2(f.y,f.x))local h=math.sqrt(f.x*f.x+f.y*f.y)local i=math.deg(math.atan2(-f.z,h))return i,g end end
local function check_overlap(b,c)if b and not c then return b elseif not b and c then return c end;if b.is_active and c.is_active then if b.length<c.length then c.is_active=false;return b elseif b.length>c.length then b.is_active=false;return c end else return b.is_active and b or c end end
local function scan_side(b,c,d,e,f,g)local h,i,j=15,0,0;local k=f;while i<1 and h<scan_length do f=c+e*h;_,i=client.trace_bullet(b,d.x,d.y,d.z,f.x,f.y,f.z)h=h+scan_width;if trace.line(k,f).fraction<1 and j>4 then return nil end;k=f;j=j+1 end;return h<=scan_length and{is_active=true,vector=f,index=b,length=h,side=g}or nil end
local function angle_right(a)local b=math.sin(math.rad(a.x))local c=math.cos(math.rad(a.x))local d=math.sin(math.rad(a.y))local e=math.cos(math.rad(a.y))local f=math.sin(math.rad(a.z))local g=math.cos(math.rad(a.z))return vector(-1.0*f*b*e+-1.0*g*-d,-1.0*f*b*d+-1.0*g*e,-1.0*f*c)end
local function get_scan_result(b)if b==-1 then return nil end;if not entity.is_alive(b)or not entity.is_enemy(b)then return nil end;local c=entity.get_local_player()local d=vector(client.eye_position())local e=vector(entity.get_origin(c))local f=vector(entity.get_prop(b,"m_vecOrigin"))local g=f+vector(entity.get_prop(b,"m_vecViewOffset"))local h,i=vector_angles(e,f)local j=vector(h,i,0)local k=angle_right(j)local l=-angle_right(j)local m=d+l*scan_width;local n=d+k*scan_width;local o=vector(entity.hitbox_position(c,1))local p,q=client.trace_bullet(b,g.x,g.y,g.z,o.x,o.y,o.z)if q<=0 then local r=scan_side(b,d,g,l,m,"left")local s=scan_side(b,d,g,k,n,"right")return(r or s)and check_overlap(r,s)or nil else return nil end end

local function angle_scan()
    local target = client.current_threat()

    local target_result = get_scan_result(target)
    local t_scan_result = get_scan_result(scan_result and scan_result.index or -1)      

    if not t_scan_result and target_result then
        scan_result = target_result
    elseif t_scan_result and target_result then   
        scan_result = target_result.length < t_scan_result.length and target_result or t_scan_result
    elseif not t_scan_result and not target_result then
        scan_result = nil
    end
end

local function draw_hit_lines()
    if not scan_result then return end

    local local_player  = entity.get_local_player()
    if    local_player  == nil or not entity.is_alive(local_player) then return end

    local local_origin  = vector(entity.get_origin(local_player))

    local t_clr = as_clr({ui.get(m.text_clr)})
    local l_clr = as_clr({ui.get(m.line_clr)})

    local pos = scan_result.vector
    local xl, yl = renderer.world_to_screen(pos.x, pos.y, pos.z)
    if xl ~= nil and yl ~= nil then
        local x, y = renderer.world_to_screen(pos.x, pos.y, local_origin.z)
        renderer.text(xl, yl - 15, t_clr.r, t_clr.g, t_clr.b, t_clr.a, "bcd", 0, "Hit")
        renderer.line(xl, yl, x, y, l_clr.r, l_clr.g, l_clr.b, l_clr.a)    
    end
end

local function paint()
	local local_player = entity.get_local_player()
	if not local_player then return end
    
    local is_alive = entity.is_alive(local_player)
    if not is_alive then return end

    scan_width, scan_length = ui.get(m.width) * 2, ui.get(m.length) * 40

	angle_scan() 
    draw_hit_lines()
end

local function handle_ui()
	local enabled = ui.get(m.enable)
	table_visible({m.width, m.length, m.text_lbl, m.text_clr, m.line_clr, m.line_lbl}, enabled)
end
handle_ui()

ui.set_callback(m.enable, function()
	local enabled = ui.get(m.enable)
	handle_callback("paint", paint, enabled)
	handle_ui()
end)