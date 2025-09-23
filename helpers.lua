
--trifill fast
-- ultra-lite ceil (faster than -flr(-x) in practice on pico-8)
local function ceil(x) 
  local i=flr(x)
  if x>i then i+=1 end
  return i
end

-- backface (optional): skip if screen-space area <= 0 (CW)
local function backface4(x1,y1,x2,y2,x3,y3,x4,y4)
  -- sum triangle areas (shoelace). positive => CCW
  local a = (x2-x1)*(y3-y1)-(y2-y1)*(x3-x1)
  a += (x4-x1)*(y3-y1)-(y4-y1)*(x3-x1)
  return a<0
end

-- optional bbox reject (skip if outside screen entirely)
local function bbox_off(x1,y1,x2,y2,x3,y3,x4,y4)
  local minx = min(min(x1,x2),min(x3,x4))
  local maxx = max(max(x1,x2),max(x3,x4))
  local miny = min(min(y1,y2),min(y3,y4))
  local maxy = max(max(y1,y2),max(y3,y4))
  return maxx<0 or minx>127 or maxy<0 or miny>127
end

function qfill_ccw(x1,y1,x2,y2,x3,y3,x4,y4)
    
  --if bbox_off(x1,y1,x2,y2,x3,y3,x4,y4) then return end
  --if backface4(x1,y1,x2,y2,x3,y3,x4,y4) then return end

  tri_ultra(x1,y1,x2,y2,x3,y3)
  tri_ultra(x1,y1,x3,y3,x4,y4)
end


-- triangle fill (solid). uses current pen.
-- order doesn't matter; we sort by y.
function tri_ultra(x1,y1,x2,y2,x3,y3)
  -- sort by y: y1<=y2<=y3
  if y1>y2 then x1,y1,x2,y2=x2,y2,x1,y1 end
  if y1>y3 then x1,y1,x3,y3=x3,y3,x1,y1 end
  if y2>y3 then x2,y2,x3,y3=x3,y3,x2,y2 end

  -- reject (no height)
  if y1==y3 then return end
  -- fast vertical clip
  local y0 = y1
  local y3i = y3
  if y3i<0 or y0>127 then return end
  -- integer row bounds (inclusive)
  local ystart = y0
  local yend   = y3i
  -- ceil without function call (cheap)
  local yi = flr(ystart)
  if yi<ystart then yi+=1 end
  ystart = yi
  yi = flr(yend)
  if yi<yend then yi+=1 end
  yend = yi-1
  if ystart>127 or yend<0 then return end
  if ystart<0 then ystart=0 end
  if yend>127 then yend=127 end
  if ystart>yend then return end

  -- long edge (1->3)
  local dy13 = (y3 - y1)
  local dx13 = (x3 - x1) / dy13
  local x_long = x1 + dx13*(ystart - y1)

  if y1==y2 then
    -- flat top: short edge (2->3)
    local dy23 = (y3 - y2)
    if dy23==0 then return end
    local dx23 = (x3 - x2) / dy23
    local x_short = x3 - dx23*(y3 - ystart)

    for y=ystart,yend do
      local xl, xr = x_long, x_short
      if xl>xr then xl,xr = xr,xl end
      -- x clip
      if xr>=0 and xl<=127 then
        if xl<0 then xl=0 end
        if xr>127 then xr=127 end
        if xr>=xl then rectfill(xl,y,xr,y) end
      end
      x_long += dx13
      x_short += dx23
    end
    return
  end

  if y2==y3 then
    -- flat bottom: short edge (1->2)
    local dy12 = (y2 - y1)
    if dy12==0 then return end
    local dx12 = (x2 - x1) / dy12
    local x_short = x1 + dx12*(ystart - y1)

    for y=ystart,yend do
      local xl, xr = x_short, x_long
      if xl>xr then xl,xr = xr,xl end
      if xr>=0 and xl<=127 then
        if xl<0 then xl=0 end
        if xr>127 then xr=127 end
        if xr>=xl then rectfill(xl,y,xr,y) end
      end
      x_short += dx12
      x_long  += dx13
    end
    return
  end

  -- general case: split at y2
  -- part A: y1..y2 uses short (1->2)
  local ysplit = y2
  local ytop   = ystart
  local ymid   = ysplit
  yi = flr(ymid)
  if yi<ymid then yi+=1 end
  ymid = yi-1

  local dy12 = (y2 - y1)
  local dx12 = (x2 - x1) / dy12
  local x_sA = x1 + dx12*(ytop - y1)
  local x_lA = x_long

  if ytop<=ymid then
    for y=ytop,ymid do
      local xl, xr = x_sA, x_lA
      if xl>xr then xl,xr = xr,xl end
      if xr>=0 and xl<=127 then
        if xl<0 then xl=0 end
        if xr>127 then xr=127 end
        if xr>=xl then rectfill(xl,y,xr,y) end
      end
      x_sA += dx12
      x_lA += dx13
    end
  end

  -- part B: y2..y3 uses short (2->3)
  local ybot = yend
  local dy23 = (y3 - y2)
  local dx23 = (x3 - x2) / dy23

  -- advance long edge to max(y2, ystart)
  local ystartB = ysplit
  if ystartB<ystart then ystartB=ystart end
  -- ceil again quickly
  yi = flr(ystartB)
  if yi<ystartB then yi+=1 end
  ystartB = yi

  local x_sB = x2 + dx23*(ystartB - y2)
  local x_lB = x1 + dx13*(ystartB - y1)

  if ystartB<=ybot then
    for y=ystartB,ybot do
      local xl, xr = x_lB, x_sB
      if xl>xr then xl,xr = xr,xl end
      if xr>=0 and xl<=127 then
        if xl<0 then xl=0 end
        if xr>127 then xr=127 end
        if xr>=xl then rectfill(xl,y,xr,y) end
      end
      x_lB += dx13
      x_sB += dx23
    end
  end
end

-------------------------------------------------------

function copy_sprites_to_map(tx_tile,ty_tile, tw,th, mx,my)  
  for j=0,th-1 do
    for i=0,tw-1 do
      -- set map cell to sprite index
      mset(mx+i, my+j, tx_tile+i + ty_tile+j*16)
    end
  end
end

--------------------------------------------------------
function tri_tex_persp_fast(
  x1,y1,z1,u1,v1,
  x2,y2,z2,u2,v2,
  x3,y3,z3,u3,v3,
  mx,my, tw,th, ru,rv, chunk_max, eps,
  uofs, vofs
)
  -- defaults
  tw,th     = tw or 4, th or 4
  ru,rv     = ru or 1, rv or 1
  chunk_max = chunk_max or 16
  eps       = eps or 0.03
  uofs      = uofs or 0
  vofs      = vofs or 0

  -- scale + phase once (repeat via wrapping below)
  u1,u2,u3 = u1*ru + uofs, u2*ru + uofs, u3*ru + uofs
  v1,v2,v3 = v1*rv + vofs, v2*rv + vofs, v3*rv + vofs

  -- sort by y
  if y1>y2 then x1,y1,z1,u1,v1,x2,y2,z2,u2,v2 = x2,y2,z2,u2,v2,x1,y1,z1,u1,v1 end
  if y1>y3 then x1,y1,z1,u1,v1,x3,y3,z3,u3,v3 = x3,y3,z3,u3,v3,x1,y1,z1,u1,v1 end
  if y2>y3 then x2,y2,z2,u2,v2,x3,y3,z3,u3,v3 = x3,y3,z3,u3,v3,x2,y2,z2,u2,v2 end
  if y1==y3 then return end

  -- perspective terms (w=1/z)
  local w1,w2,w3 = 1/z1, 1/z2, 1/z3
  local u1w,v1w  = u1*w1, v1*w1
  local u2w,v2w  = u2*w2, v2*w2
  local u3w,v3w  = u3*w3, v3*w3

  -- long edge (1->3) slopes per y
  local dy13 = y3 - y1
  local dx13 = (x3 - x1)/dy13
  local du13 = (u3w - u1w)/dy13
  local dv13 = (v3w - v1w)/dy13
  local dw13 = (w3  - w1 )/dy13

  -- y bounds
  local y0  = ceil(y1)
  local y3i = ceil(y3) - 1
  if y0>127 or y3i<0 then return end
  if y0<0 then y0=0 end
  if y3i>127 then y3i=127 end
  if y0>y3i then return end

  -- evaluate long edge at y
  local function long_at(y)
    local t = y - y1
    return x1 + dx13*t,
           u1w+ du13*t,
           v1w+ dv13*t,
           w1 + dw13*t
  end


  local function tline_wrap_chunk(x,y,len, u0,v0, du,dv, mx,my, tw,th)
    local wpx = tw*8
    local hpx = th*8

    local rem = len
    local xx  = x
    local u   = u0
    local v   = v0

    while rem>0 do
      -- current uv inside [0,wpx) x [0,hpx)
      local um = u % wpx; if um<0 then um += wpx end
      local vm = v % hpx; if vm<0 then vm += hpx end

      -- steps until we hit the next wrap boundary on U or V
      local step_u = 32767
      if du>0 then step_u = (wpx - um)/du
      elseif du<0 then step_u = (um)/(-du) end

      local step_v = 32767
      if dv>0 then step_v = (hpx - vm)/dv
      elseif dv<0 then step_v = (vm)/(-dv) end

      local seg = flr(min(rem, step_u, step_v))
      if seg<1 then seg=1 end

      -- draw this subsegment
      tline(xx, y, xx+seg-1, y,
        mx + um/8, my + vm/8,
        du/8, dv/8)

      -- advance
      xx  += seg
      u   += du*seg
      v   += dv*seg
      rem -= seg
    end
  end

  
  -- band scan with short edge a->b
  local function band(ax,ay,au,av,aw, bx,by,bu,bv,bw, yA,yB)
    local dy  = by - ay
    if dy<=0 then return end
    local dxs = (bx-ax)/dy
    local duw = (bu-au)/dy
    local dvw = (bv-av)/dy
    local dww = (bw-aw)/dy

    local t   = yA - ay
    local xs  = ax + dxs*t
    local us  = au + duw*t
    local vs  = av + dvw*t
    local ws  = aw + dww*t

    local xl,ul,vl,wl = long_at(yA)

    -- constants
    local min,max,flr,tline = min,max,flr,tline
    local mx0,my0 = mx,my

    for y=yA,yB do
      -- choose left/right
      local xr,ur,vr,wr = xs,us,vs,ws
      local xl2,xr2 = xl,xr
      local ul2,ur2 = ul,ur
      local vl2,vr2 = vl,vr
      local wl2,wr2 = wl,wr
      if xl2>xr2 then
        xl2,xr2 = xr2,xl2
        ul2,ur2 = ur2,ul2
        vl2,vr2 = vr2,vl2
        wl2,wr2 = wr2,wl2
      end

      -- x clip
      local xL = max(0, ceil(xl2))
      local xR = min(127, flr(xr2))
      if xL<=xR then
        local span = xr2 - xl2
        if span>0 then
          -- per-x slopes for (u/z, v/z, 1/z)
          local invspan = 1/span
          local dux = (ur2-ul2)*invspan
          local dvx = (vr2-vl2)*invspan
          local dwx = (wr2-wl2)*invspan

          -- start at xL
          local dxL = xL - xl2
          local uoz = ul2 + dux*dxL
          local voz = vl2 + dvx*dxL
          local wz  = wl2 + dwx*dxL

          -- adaptive chunk size based on relative change of w within a chunk
          local x = xL
          while x<=xR do
            local remain = xR - x + 1
            -- choose seg so |Δw/w| ≲ eps
            local rel = abs(dwx)/max(0.0001, abs(wz))
            local seg = (rel>0) and flr(min(remain, max(2, eps/rel))) or remain
            if seg>chunk_max then seg=chunk_max end
            if seg<2 then seg=2 end
            if seg>remain then seg=remain end

            -- endpoints in u,v (recover from u/z)
            local u0 = uoz / wz
            local v0 = voz / wz
            local uoz1 = uoz + dux*seg
            local voz1 = voz + dvx*seg
            local wz1  = wz  + dwx*seg
            local u1 = uoz1 / wz1
            local v1 = voz1 / wz1

            -- linear per-pixel delta over the chunk
            local du = (u1 - u0)/seg
            local dv = (v1 - v0)/seg

            --tline(x, y, x+seg-1, y, mx0 + u0/8, my0 + v0/8, du/8, dv/8)
            tline_wrap_chunk(x, y, seg, u0, v0, du, dv, mx, my, tw, th)

            x   += seg
            uoz += dux*seg
            voz += dvx*seg
            wz  += dwx*seg
          end
        end
      end

      -- next scanline
      xs += dxs; us += duw; vs += dvw; ws += dww
      xl += dx13; ul += du13; vl += dv13; wl += dw13
    end
  end

  local yA = y0
  local yB = ceil(y2)-1
  if yA<=yB then
    band(x1,y1,u1w,v1w,w1,  x2,y2,u2w,v2w,w2,  yA,yB)
  end
  local yC = max(ceil(y2), y0)
  local yD = y3i
  if yC<=yD then
    band(x2,y2,u2w,v2w,w2,  x3,y3,u3w,v3w,w3,  yC,yD)
  end
end

-- quad as two tris (convex), perspective-correct
function qtex_map_persp_fast(
  x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4,
  mx,my, tw,th, ru,rv, chunk_max, eps,
  uofs, vofs 
)
  local wpx,hpx = (tw or 4)*8, (th or 4)*8
  tri_tex_persp_fast(
    x1,y1,z1, 0,0,
    x2,y2,z2, wpx,0,
    x3,y3,z3, wpx,hpx,
    mx,my, tw,th, ru,rv, chunk_max, eps, uofs, vofs
  )
  tri_tex_persp_fast(
    x1,y1,z1, 0,0,
    x3,y3,z3, wpx,hpx,
    x4,y4,z4, 0,hpx,
    mx,my, tw,th, ru,rv, chunk_max, eps, uofs, vofs
  )
end