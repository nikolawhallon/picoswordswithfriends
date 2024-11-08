pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- functions and objects

mapw=128
maph=64

function wall_chk(x,y)
	local n=0
	if mget(x,y-1)==3 then n+=1 end
	if mget(x,y+1)==3 then n+=1 end
	if mget(x-1,y)==3 then n+=1 end
	if mget(x+1,y)==3 then n+=1 end
	if mget(x+1,y+1)==3 then n+=1 end
	if mget(x+1,y-1)==3 then n+=1 end
	if mget(x-1,y+1)==3 then n+=1 end
	if mget(x-1,y-1)==3 then n+=1 end
 return n
end

function place_object(o)
 local placed=false
 while not placed do
  local x=8 * rnd(mapw)
  local y=8 * rnd(maph)
  if not intersects_tile(3,x,y,8,8) then
   o.x=x
   o.y=y
   placed=true
  end
 end
end

function place_object_near(o,x,y)
 local placed=false
 while not placed do
  local ox=x-5+8 * rnd(10)
  local oy=y-5+8 * rnd(10)
  if not intersects_tile(3,ox,oy,8,8)
     and ox>0 and ox<128*8-8
     and oy>0 and oy<64*8-8 then
   o.x=ox
   o.y=oy
   placed=true
  end
 end
end

function is_close(x1,y1,x2,y2,d)
 if abs(x1-x2)>d then
  return false
 end
 
 if abs(y1-y2)>d then
  return false
 end 

 return true
end


function intersects(x1,y1,w1,h1,x2,y2,w2,h2)
 if x1+w1<=x2 or x2+w2<=x1 then
  return false
 end
    
 if y1+h1<=y2 or y2+h2<=y1 then
  return false
 end
     
 return true
end

function intersects_tile(t,x1,y1,w1,h1)
 local n=2
 for i=0,n do
  for j=0,n do
   local x=x1+(w1*i)/n
   local y=y1+(h1*j)/n
   if mget(x/8,y/8)==t then
    return true
   end
  end
 end

 return false
end

-- usage:
-- ```
-- myanim=anim:new({
--  sprs={19,21},
--  fpi=3
-- })
-- ```
-- sprs = sprite indices
-- fpi = frames per index
anim={
 sprs={},
 cur=0,
 fpi=1,

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,
 
 update=function(self,f)
  for n=1,#self.sprs do
   if f / self.fpi % #self.sprs == n - 1 then
    self.cur=self.sprs[n]
   end
  end
 end
}

player={
 pad=0,
 x=16,
 y=16,
 -- move, idle must be present
 -- override for p2, etc
 anims={
  move=anim:new({
   sprs={19,21},
   fpi=3
  }),
  idle=anim:new({
   sprs={19,20},
   fpi=10
  })
 },
 dir='right',
 mov=false,
 score=0,
 health=6,
 plume_color=2,
 -- consider making sword object
 -- would have:
 -- x,y,dir,active,draw
 swd_dir='right',
 swd_out=false,

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,

 -- update state
 update=function(self,f)
  local l=btn(0,self.pad)
  local r=btn(1,self.pad)
  local u=btn(2,self.pad)
  local d=btn(3,self.pad)
  local a=btn(4,self.pad)
  local b=btn(5,self.pad)

  if self.health<=0 then
   return
  end
  
  if not a and not b then
   self.swd_out=false
  else
   if self.swd_out==false then
    sfx(12)
   end
   self.swd_out=true
  end
  
  if l then
   if not self.swd_out then
    if not intersects_tile(3,self.x+1-1,self.y+1,6,6) then
     self.x-=1
    end
   end
   self.dir='left'
   self.swd_dir='left'
  end
  if r then
   if not self.swd_out then
    if not intersects_tile(3,self.x+1+1,self.y+1,6,6) then
     self.x+=1
    end
   end
   self.dir='right'
   self.swd_dir='right'
  end
  if u then
   if not self.swd_out then
    if not intersects_tile(3,self.x+1,self.y+1-1,6,6) then
     self.y-=1
    end
   end
   self.swd_dir='up'
  end
  if d then
   if not self.swd_out then
    if not intersects_tile(3,self.x+1,self.y+1+1,6,6) then
     self.y+=1
    end
   end
   self.swd_dir='down'
  end

  if l or r or u or d then
   self.mov=true
  else
   self.mov=false
  end

  for k,v in pairs(self.anims) do
   v:update(f)
  end
 end,

 -- pick the animation
 -- based on state
 draw=function(self,cam)
  if self.health<=0 then
   return
  end
  
  flp=false
  if self.dir=='left' then
   flp=true
  end
  
  if self.mov then
   cur=self.anims['move'].cur
   spr(cur,self.x-cam.x,self.y-cam.y,1,1,flp)
  else
   cur=self.anims['idle'].cur
   spr(cur,self.x-cam.x,self.y-cam.y,1,1,flp)
  end

  if self.swd_out then
   if self.swd_dir=='left' then
    spr(28,self.x-8-cam.x,self.y-cam.y,1,1,true)
   elseif self.swd_dir=='right' then
    spr(28,self.x+8-cam.x,self.y-cam.y)
   elseif self.swd_dir=='up' then
    spr(29,self.x-cam.x,self.y-8-cam.y,1,1,false,true)
   elseif self.swd_dir=='down' then
    spr(29,self.x-cam.x,self.y+8-cam.y)
   end
  end

  -- ui health bar
  for h=0,min(self.health-1,2) do
   rectfill(self.x+3 * h-cam.x,self.y-3-cam.y,self.x+1+3 * h-cam.x,self.y-2-cam.y,11)
  end
  for h=3,min(self.health-1,5) do
   rectfill(self.x+3 * (h-3)-cam.x,self.y-3-cam.y,self.x+1+3 * (h-3)-cam.x,self.y-2-cam.y,12)
  end
 end
}

-- gosoh by default
-- override for other enemies
enemy={
 typ='gosoh',
 spd=1,
 pause=0,
 x=64,
 y=64,
 dst=nil,
 vel_x=0,
 vel_y=0,
 anims={
  move=anim:new({
   sprs={5,6,7},
   fpi=3
  })
 },

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,

 update=function(self,f)
  for k,v in pairs(self.anims) do
   v:update(f)
  end

  if self.pause > 0 then
   self.pause-=1
   return
  end

  self.vel_x=0
  self.vel_y=0
  
  if self.dst ~=nil then
   local dx=self.dst.x-self.x
   local dy=self.dst.y-self.y
   local a=atan2(dx,dy)
   self.vel_x=self.spd * cos(a)
   self.vel_y=self.spd * sin(a)
  end
  
  if self.typ=='gosoh' or not intersects_tile(3,self.x+1+self.vel_x,self.y+1,6,6) then
   self.x+=self.vel_x
  end
  if self.typ=='gosoh' or not intersects_tile(3,self.x+1,self.y+1+self.vel_y,6,6) then
   self.y+=self.vel_y
  end
 end,

 draw=function(self,cam)
  cur=self.anims['move'].cur
  if self.vel_x < 0 then
   spr(cur,self.x-cam.x,self.y-cam.y,1,1,true)
  else
   spr(cur,self.x-cam.x,self.y-cam.y)
  end
 end
}

-->8
-- game loop

--music(0)

key={
 x=0,
 y=0,
 rotate=anim:new({
  sprs={11,12,13,14},
  fpi=6
 })
}

door={
 x=0,
 y=0,
 idle=anim:new({
  sprs={41},
  fpi=3
 })
}

-- todo: use
heart={
 x=0,
 y=0,
 float=anim:new({
  sprs={1,2},
  fpi=8
 })
}

-- todo: use
super_heart={
 x=0,
 y=0,
 float=anim:new({
  sprs={16,32},
  fpi=10
 })
}

p2=player:new({
 plume_color=2,
 anims={
  move=anim:new({
   sprs={19,21},
   fpi=3
  }),
  idle=anim:new({
   sprs={19,20},
   fpi=10
  })
 }
})

p14=player:new({
 plume_color=14,
 anims={
  move=anim:new({
   sprs={22,24},
   fpi=3
  }),
  idle=anim:new({
   sprs={22,23},
   fpi=10
  })
 }
})

p8=player:new({
 plume_color=8,
 anims={
  move=anim:new({
   sprs={38,40},
   fpi=3
  }),
  idle=anim:new({
   sprs={38,39},
   fpi=10
  })
 }
})

p3=player:new({
 plume_color=3,
 anims={
  move=anim:new({
   sprs={54,56},
   fpi=3
  }),
  idle=anim:new({
   sprs={54,55},
   fpi=10
  })
 }
})

player_templates={p2,p3,p8,p14}
players={}

enemies={}
gosoh_timer=120
blofire_timer=60

torches={}
enchanted_torches={}

level=0

f=1

cam = {
 x=0,
 y=0
}

minimap=false
protected=false

function pad_active(pad)
 local pad_active=false
 for p in all(players) do
  if p.pad==pad then
   pad_active=true
  end
 end
 return pad_active
end

function decorate_floor(p,t)
 if mget(p[1],p[2])==0 then
  mset(p[1],p[2],t)
 end
end

function lighten_circle(x,y,r)
 for i=x-r,x+r do
  for j=y-r,y+r do
   local dx=i-x
   local dy=j-y
   if dx*dx+dy*dy <= r*r then
    local c=pget(i,j)
    if c==1 then
     pset(i,j,2)
    elseif c==2 then
     pset(i,j,8)
    end
   end
  end
 end
end

function object_in_view(o,cam)
 local dx=o.x-cam.x
 local dy=o.y-cam.y
 if dx<0-64 then return false end
 if dx>128+64 then return false end
 if dy<0-64 then return false end
 if dy>128+64 then return false end
 return true
end

function init()
 -- the map
 for x=0,mapw do
	 for y=0,maph do
   mset(x,y,3)
  end
 end
 
	for x=1,mapw-2 do
		for y=1,maph-2 do
			if rnd(1.0) < 0.65 then
				mset(x,y,0)
			end
		end
	end
	
	for i=0,10 do
		for x=1,mapw-2 do
			for y=1,maph-2 do
				if wall_chk(x,y) > 4 then
				 mset(x,y,3)
				elseif wall_chk(x,y) < 3 then
					mset(x,y,0)
    end
   end
  end
 end

 for x=0,mapw do
	 for y=0,maph do
   if x%8==0 and y%8==0 then
    local points = {
     {x,y},{x+1,y},{x,y+1},{x+1,y+1}
    }
    for p in all(points) do
     decorate_floor(p,4)
    end
   end
   if (x+4)%8==0 and (y+4)%8==0 then
    local points = {
     {x-1,y-1},{x-1,y},{x-1,y+1},{x-1,y+2},
     {x+2,y-1},{x+2,y},{x+2,y+1},{x+2,y+2},
     {x,y-1},{x+1,y-1},{x,y+2},{x+1,y+2}
    }
    for p in all(points) do
     decorate_floor(p,4)
    end
   end
  end
 end

 -- the objects
 if #players>0 then
  place_object(players[1])
  for p in all(players) do
   place_object_near(p,players[1].x, players[1].y)
  end
 end
 enemies={}

 torches={}
 for t=0,10 do
  local torch={
   x=0,
   y=0,
   burn=anim:new({
    sprs={48,49,50,49},
    fpi=3
   })
  }
  place_object(torch)
  add(torches,torch)
 end

 enchanted_torches={}
 for t=0,10 do
  local torch={
   x=0,
   y=0,
   burn=anim:new({
    sprs={48,49,50,49},
    fpi=3
   }),
   spawned=0
  }
  place_object(torch)
  add(enchanted_torches,torch)
 end

 key.player=nil
 place_object(key)
 place_object(door)
end

init()

function _update()
 -- player jumping in
 for pad=0,4 do
  if btn(4,pad) and btn(5,pad) then
   if not pad_active(pad) then
    local player=rnd(player_templates)
    player.pad=pad
    if #players==0 then
     place_object(player)
     place_object_near(key,player.x,player.y)
    else
     place_object_near(player,players[1].x,players[1].y)
    end
    add(players,player)
    del(player_templates,player)
   end
  end
 end

 -- turning the minimap on
 for pad=0,4 do
  if btnp(4,pad) and btn(5,pad)
     or btn(4,pad) and btnp(5,pad) then
   if pad_active(pad) then
    minimap=not minimap
    break
   end
  end
 end

 -- useful state
 protected=true
 for p in all(players) do
  local p_protected=false
  for t in all(torches) do
   if is_close(p.x,p.y,t.x,t.y,16) then
    p_protected=true
   end
  end
  protected=protected and p_protected
 end

 -- update objects
 for p in all(players) do
  p:update(f)
 end

 if f % gosoh_timer==0 and not protected then
  local p=rnd(players)
  local a=rnd(1.0)
  gosoh=enemy:new({
   x=cam.x+64+(256 * cos(a)),
   y=cam.y+64+(256 * sin(a)),
   dst=p,
  })
  add(enemies,gosoh)
 end

 if f % blofire_timer==0 then
  for t in all(enchanted_torches) do
   local should_spawn=false
   for p in all(players) do
    if is_close(p.x,p.y,t.x,t.y,64) then
     should_spawn=true
     break
    end
   end

   if should_spawn then
    local p=rnd(players)
    blofire=enemy:new({
     typ='blofire',
     spd=0.25,
     x=t.x,
     y=t.y,
     dst=p,
     anims={
      move=anim:new({
       sprs={35,36},
       fpi=10
      })
     }
    })
    add(enemies,blofire)
   end
  end
 end
 
 for enemy in all(enemies) do
  if enemy.typ=='gosoh' and protected then
   enemy.pause+=1
  end
  enemy:update(f)
 end

 -- enemy player collision
 for p in all(players) do
  if p.health<=0 then
   goto continue
  end
  
  for e in all(enemies) do
   if intersects(e.x,e.y,8,8,p.x,p.y,8,8) then
    p.health-=1
    sfx(14)
    local dx=p.x-e.x
    local dy=p.y-e.y
    local a=atan2(dx,dy)
    if not intersects_tile(3,p.x+6 * cos(a),p.y,8,8) then
     p.x+=6 * cos(a)
    end
    if not intersects_tile(3,p.x,p.y+6 * sin(a),8,8) then
     p.y+=6 * sin(a)
    end
    e.x+=6 * cos(a+0.5)
    e.y+=6 * sin(a+0.5)
    e.pause+=60
   end
  end
  
  ::continue::
 end
 
 for p in all(players) do
  if p.health<=0 then
   if key.player==p then
    key.player=nil
   end
   del(players,p)
  end
 end
 
 -- enemy sword collision
 for p in all(players) do
  for enemy in all(enemies) do
   if p.swd_out then
    local swdx = p.x
    local swdy = p.y
    if p.swd_dir=='left' then
     swdx-=8
    elseif p.swd_dir=='right' then
     swdx+=8
    elseif p.swd_dir=='up' then
     swdy-=8
    elseif p.swd_dir=='down' then
     swdy+=8
    end
 
    if intersects(enemy.x,enemy.y,8,8,swdx,swdy,8,8) then
     del(enemies,enemy)
     sfx(13)
     p.score+=1
    end
   end
  end
 end
 
 for torch in all(torches) do
  torch.burn:update(f)
 end

 for torch in all(enchanted_torches) do
  torch.burn:update(f)
 end
  
 key.rotate:update(f)
 
 door.idle:update(f)
 door.x+=2*cos(f/64)
 door.y+=2*sin(f/64)
 if door.x>128*8 or door.x<0 or door.y>64*8 or door.y<0 then
  place_object(door)
 end
 
 for p in all(players) do
  if intersects(p.x,p.y,8,8,door.x,door.y,8,8)
    and key.player==p then
   sfx(15)
   level+=1
   gosoh_timer-=2
   init()
   break
  end
 end

 if key.player==nil then
  for p in all(players) do
   if intersects(p.x,p.y,8,8,key.x,key.y,8,8) then
    sfx(16)
    key.player=p
    break
   end
  end
 else
  key.x=key.player.x+8
  key.y=key.player.y-4
 end
end

function _draw()
 cam.x=0
 cam.y=0
 for p in all(players) do
  cam.x+=p.x
  cam.y+=p.y
 end
 cam.x=cam.x/#players-64
 cam.y=cam.y/#players-64

 if cam.x<0 then cam.x=0 end
 if cam.x>896 then cam.x=896 end
 if cam.y<0 then cam.y=0 end
 if cam.y>384 then cam.y=384 end

 cls(1)

 -- draw the map and minimap
 if minimap then
  -- this is efficient
  clip(0,0,128,32)
  rectfill(0,0,128,32,0)
  pal(6,5)
  pal(7,6)
  pal(2,1)
  pal(1,0)
  map(0,0,-cam.x,-cam.y,mapw,maph)
  pal()
  clip()
  
  -- this is efficient
  clip(0,96,128,32)
  rectfill(0,96,128,128,0)
  pal(6,5)
  pal(7,6)
  pal(2,1)
  pal(1,0)
  map(0,0,-cam.x,-cam.y,mapw,maph)

  pal()
  clip()
  
  -- this is inefficient
  clip(0,32,128,64)
  map(0,0,-cam.x,-cam.y,mapw,maph)
  local mget,pget,pset=mget,pget,pset
  local color_map={[6]=5,[7]=6,[2]=1}
  local y_offset=maph/2
  for i=0,mapw do
   for j=0,maph do
    local x=i
    local y=j+y_offset
    if mget(i,j)==3 do
     local c=pget(x,y)
     pset(x,y,color_map[c] or 0)
    end
   end
  end
  clip()
    
  for p in all(players) do
   local i=p.x/8
   local j=p.y/8
   rectfill(i,j+maph/2,i+1,j+maph/2+1,p.plume_color)
  end

  for enemy in all(enemies) do
   local i=enemy.x/8
   local j=enemy.y/8
   rectfill(i,j+maph/2,i+1,j+maph/2+1,7)
  end

  for torch in all(torches) do
   pset(torch.x/8,torch.y/8+maph/2,10)
   pset(torch.x/8,torch.y/8-1+maph/2,8)
  end
  
  pset(key.x/8,key.y/8+maph/2,12)
  pset(key.x/8-1,key.y/8+maph/2,10)
  pset(key.x/8,key.y/8-1+maph/2,10)
  pset(key.x/8+1,key.y/8+maph/2,10)
  pset(key.x/8,key.y/8+1+maph/2,10)

  pset(door.x/8,door.y/8+maph/2,12)
  pset(door.x/8-1,door.y/8+maph/2,10)
  pset(door.x/8,door.y/8-1+maph/2,10)
  pset(door.x/8+1,door.y/8+maph/2,10)
  pset(door.x/8,door.y/8+1+maph/2,10)
  pset(door.x/8+1,door.y/8+1+maph/2,8)
  pset(door.x/8-1,door.y/8-1+maph/2,8)
  pset(door.x/8+1,door.y/8-1+maph/2,8)
  pset(door.x/8-1,door.y/8+1+maph/2,8)
 else
  map(0,0,-cam.x,-cam.y,mapw,maph)
 end

 for torch in all(torches) do
  if object_in_view(torch,cam) then
   lighten_circle(torch.x+4-cam.x,torch.y+4-cam.y,16+2*sin(f/64))
  end
 end
 
 for p in all(players) do
  p:draw(cam)
 end

 for enemy in all(enemies) do
  if object_in_view(enemy,cam) then
   enemy:draw(cam)
  end
 end

 for torch in all(torches) do
  if object_in_view(torch,cam) then
   spr(torch.burn.cur,torch.x-cam.x,torch.y-cam.y)
  end
 end

 for torch in all(enchanted_torches) do
  if object_in_view(torch,cam) then
   spr(torch.burn.cur,torch.x-cam.x,torch.y-cam.y)
  end
 end

 --local fps = stat(7)
 --print(level,2,2,7)
 --print(fps,2,10,7)
 --print(cam.x,2,18,7)
 --print(cam.y,2,26,7)

 spr(key.rotate.cur,key.x-cam.x,key.y-cam.y)
 spr(door.idle.cur,door.x-cam.x,door.y-cam.y)

 f+=1
end
__gfx__
0000000007700ee00000000007760776222200000000000000000000000000000077770000777700007777000000000000000000000000000007000000000000
0000000077eeeeee07e00ee007660766200202200077770000777700007777000660606006606060066060600000000000000000000700000007000000000000
007007007eeeeeee7eeeeeee0666066620020220077777700777777007777770066060600660606006606060000a000000070000000a0000000a000000000000
00077000eeeeeeeeeeeeeeee000000002222000007077070070770700707707000666600006666000066660000aca000007a700007aca700770a077000000000
000770000eeeeee0eeeeeeee7760776000002222070770700707707007077070000606000000600000006000000a000000070000000a0000000a000000000000
0070070000eeee000eeeeee076607660022020020777777007777770077777700000700000070000000007000009000000090000000700000007000000000000
00000000000ee00000eeee00666066600220200207077070007707700770770000070700007070000000707000099000000a0000009900000007000000000000
0000000000000000000ee00000000000000022220000000000000000000000000000600000060000000006000009000000090000000900000009000000000000
07700770000000bbbb0000000220000022000000220000000ee00000ee000000ee0000000ee00000ee000000ee00000000000000000620000000000000000000
7cc77cc7bbbbbbbbbbbbbbbb226666600220000002200000eeccccc00ee000000ee00000ee6666600ee000000ee0000000600000000620000000000000000000
7cccccc7bbbbbbbbbbbbbbbb00667670006666600066666000cc7c7000ccccc000ccccc000667670006666600066666000d7777006dddd200000000000000000
7cccccc7bbbbbbbbbbbbbbbb00667670006676700066767000cc7c7000cc7c7000cc7c7000667670006676700066767066d66667007662000000000000000000
07cccc70333333333333333300666660006676700066767000ccccc000cc7c7000cc7c7000666660006676700066767022d66662007662000000000000000000
007cc700bbbbbbbbbbbbbbbb000666000066666000666660000ccc0000ccccc000ccccc000066600006666600066666000d22220007662000000000000000000
00077000000000bbbb000000000666000006660000066600000ccc00000ccc00000ccc0000066600000666000006660000200000007662000000000000000000
00000000000000000000000000600060006000600006060000c000c000c000c0000c0c0000600060006000600006060000000000000720000000000000000000
00000000000000000000000008008000000000000000000008800000880000008800000000777700000000000000000000000000000000000000000000000000
077007700000000000000000088088000000000000000000885555500880000008800000078aa870000000000000000000000000000000000000000000000000
7cc77cc7000000000000000000888800008080000000000000557570005555500055555078acca87000000000000000000000000000000000000000000000000
7cccccc7000000000000000008878780008888000000000000557570005575700055757068acca86000000000000000000000000000000000000000000000000
7cccccc70000000000000000088787800887878000000000005555500055757000557570688aa886000000000000000000000000000000000000000000000000
07cccc70000000000000000008888880088787800000000000055500005555500055555068acca86000000000000000000000000000000000000000000000000
007cc70000000000000000000088880000888800000000000005550000055500000555006acccca6000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000500050005000500005050067777776000000000000000000000000000000000000000000000000
000880000008800000088000000000000000bb000000000003300000330000003300000000077770000000000000000000000000000000000000000000000000
008800000008800000008800000bb000000bbbb00000000033ddddd0033000000330000000760607000777700007777000000000000000000000000000000000
00888000008888000008880000bbbb0000bb7b7b00bbbb0000dd7d7000ddddd000ddddd000660606007606070076060700000000000000000000000000000000
0088880000888800008888000bbb7b700bbb7b7b0bbbbbb000dd7d7000dd7d7000dd7d7000006060006606060066060600000000000000000000000000000000
00a88a0000a88a0000a88a000bbb7b700bbbbbbbbbbb7b7b00ddddd000dd7d7000dd7d7000000000000060600000606000000000000000000000000000000000
000aa000000aa000000aa0000bbbbbb00bbbbbb0bbbb7b7b000ddd0000ddddd000ddddd000777000000000000000000000000000000000000000000000000000
000cc000000cc000000cc00000bbbb0000bbbb000bbbbbbb000ddd00000ddd00000ddd0000666000007770000077700000000000000000000000000000000000
000aa000000aa000000aa00000000000000000000000000000d000d000d000d0000d0d0006000600060006000060600000000000000000000000000000000000
__label__
17761776177617761776177617761776177617761776177617761776111111111111111117761776177617761776177617761776177617761776177617761776
17661766176617661766176617661766176617661766176617661766111111111111111117661766176617661766176617661766176617661766176617661766
16661666166616661666166616661666166616661666166616661666111111111111111116661666166616661666166616661666166616661666166616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761776177617761776177617761776177617761776177617761111111111111111177617761776177617761776177617761776177617761776177617761
76617661766176617661766176617661766176617661766176617661111111111111111176617661766176617661766176617661766176617661766176617661
66616661666166616661666166616661666166616661666166616661111111111111111166616661666166616661666166616661666166616661666166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
1766176611eee1ee111111eee11111111111111111111111111111111111111111111111111111111111111111111111111eee1eee11111eee11111117661766
1666166611e1e11e111e11e1e11111111111111111111177771111111111111111111111111111111111111111111111111e1e111e11e11e1e11111116661666
1111111111eee11e111111e1e11111111111111111111616166111111111111111111111111111111111111111111111111eee1eee11111e1e11111111111111
7761776111e1111e111e11e1e11111111111111111111616166111111111111111111111111111111111111111111111111e111e1111e11e1e11111177617761
7661766111e111eee11111eee11111111111111111111166661111111111111111111111111111111111111111111111111e111eee11111eee11111176617661
66616661111111111111111111111111111111111111116161111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111112222111122221111111111111111117171111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111112112bb2bb1bb1221111111111111111611111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111112112bb2bb1bb1221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111112222111122221111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111222211112222111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111221222212212112111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111221216666612112111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111226676712222111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111112222116676721111111111111111111111111111111111111111111111111111111111111111111111188111111111111111111117761776
17661766111111112112126666621221111111111111111111111111111111111111111111111111111111111111111111881111111111111111111117661766
16661666111111112112122666121221111111111111111111111111111111111111111111111111111111111111111111888111111111111111111116661666
11111111111111112222116122621111111111111111111111111111111111111111111111111111111111111111111111888811111111111111111111111111
77617761111111111111222211112222111111111111111111111111111111111111111111111111111111111111111111a88a11111111111111111177617761
766176611111111112212112122121121111111111111111111111111111111111111111111111111111111111111111111aa111111111111111111176617661
666166611111111112212112122121121111111111111111111111111111111111111111111111111111111111111111111cc111111111111111111166616661
111111111111111111112222111122221111111111111111111111111111111111111111111111111111111111111111111aa111111111111111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
33333333111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111133333333
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221111111111111111121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111111111111111111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112111111111111111112212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111111111111111111112222111111111111111111111111111111111111111111111111
17761776111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111121121221211212212112122121121221111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111122221111222211112222111122221111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111112212112122121121221211212212112111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111112222111122221111222211112222111111111111111111111111111111111111111111111111
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
33333333111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111133333333
bbbbbbbb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbbb
111111bb1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bb1111111111111111
1776177611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbb111111117761776
176617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111b7b7bb11111117661766
166616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111b7b7bbb1111116661666
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbbb1111111111111
7761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbbbb1111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111bbbb11111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776111111111111111111188111111111111111111111111111111111111111111111111111111111111111111122221111222211111111111117761776
1766176611111111111111111188111111111111111111111111111111111111111111111111111111111111111111112112bb2bb1bb12211111111117661766
1666166611111111111111111188811111181811111111111111111111111111111111111111111111111111111111112112bb2bb1bb12211111111116661666
11111111111111111111111111888811111888811111111111111111111111111111111111111111111111111111111122221111222211111111111111111111
77617761111111111111111111a88a1111887878111111111111111111111111111111111111111111111111111111111111ee22111122221111111177617761
766176611111111111111111111aa111118878781111111111111111111111111111111111111111111111111111111112212ee2122121121111111176617661
666166611111111111111111111cc111111888811111111111111111111111111111111111111111111111111111111112212166666121121111111166616661
111111111111111111111111111aa111111111111111111111111111111111111111111111111111111111111111111111112266767122221111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111122221166767211111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111121121266666212211111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111121121226661212211111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111122221161226211111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112222111122221111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112212112122121121111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112212112122121121111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112222111122221111111111111111
17761776111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117761776
17661766111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117661766
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177617761
76617661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111176617661
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17761776177617761776177617761776177617761776177617761776111111111111111117761776177617761776177617761776177617761776177617761776
17661766176617661766176617661766176617661766176617661766111111111111111117661766176617661766176617661766176617661766176617661766
16661666166616661666166616661666166616661666166616661666111111111111111116661666166616661666166616661666166616661666166616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77617761776177617761776177617761776177617761776177617761111111111111111177617761776177617761776177617761776177617761776177617761
76617661766176617661766176617661766176617661766176617661111111111111111176617661766176617661766176617661766176617661766176617661
66616661666166616661666166616661666166616661666166616661111111111111111166616661666166616661666166616661666166616661666166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
010a00002603018000210302100020030205002103021500260302650029030295002803028500290302950026030265002103021500200302050021030215002303024030230302403021030215002150021500
110a00000c173000000c6550c1000c173000000c655000000c173000000c6550c6000c173000000c655000000c173000000c6550c1000c173000000c655000000c1730c6000c6550c6550c173000000c65500000
010a0000320302650030030300002f030205002d030210002c0302d0302c0302d0302903029000280302900026030260002103021000200302000021030210001d0301d0001a0301a0001c0301c0002100021000
190a00000e0700e0701d7501400009070090701d750210000e0700e0701d7501400009070090701d750210000e0700e0701d7501400009070090701d750210000907009070197501400004070040701975021000
010a000000000000002175021000000000000021750210000000000000217502100000000000002175021000000000000021750210000000000000217502100000000000001c7501c00000000000001c7501c000
010a00000c173000000c6000c1730c1000c1000c173210000c655000000c1730c1730c1730c1000c1730c1000c173000000c6000c1730c1000c1000c173210000c655000000c1730c1730c1730c1000c1730c100
010a00000207002070020700200002000020000207002070020700207002000020001a7261d72621726247261a7261d72621726247261a7261d726217262472626716297162d716307161a7261d7262172624726
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001a050190001905016000160501400015050000001405000000150500000016050000001505000000
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001d050190001c050160001a0501400019050000001a05000000150500000017050000001905000000
010a00001a0300c00015050000001a0500000020050000002105020050210502005021050000001c050000001d050190001c050160001a0501400019050000001a05000000150000000026050000001900000000
010a00001a0320000000000000001d750000000000000000000000000000000000001d750000000000000000000000000000000000001d750000000000000000000000000000000000001d750000000000000000
010a00000000000000000000000021750000000000000000000000000000000000002175000000000000000000000000000000000000217500000000000000000000000000000000000021750000000000000000
010200000e6501a64026630326201d6001d60021600256002a6002f60035600356000160001600016000160000600006000060000600006000060000600006000060000600006000060000600006000060000600
010400001f3501a350153501035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
450200002433627636297362c1362433627636297362c136000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a000021555225552555526555275552a5552b55500500000002b5440b0002b5340b0002b5240a0002b51400000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000394553a4553d4553e4550f4003a4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 40010304
00 40010304
00 40010304
00 40010304
00 00010304
00 00010304
00 02010304
00 02010304
00 00010304
00 00010304
00 02010304
00 02010304
00 0a0b0506
00 0a0b0506
00 0a0b0506
00 0a0b0506
00 070b0506
00 080b0506
00 070b0506
00 090b0506
00 070b0506
00 080b0506
00 070b0506
02 090b0506

