function qfill(x1,y1, x2,y2, x3,y3, x4,y4)
  -- localize globals for speed
  local flr,rectfill,max,min = flr,rectfill,max,min

  -- pack coords
  local xs={x1,x2,x3,x4}
  local ys={y1,y2,y3,y4}

  -- helpers
  local function ceil(a) return -flr(-a) end
  local function inc(i) i+=1 if i>4 then i=1 end return i end
  local function dec(i) i-=1 if i<1 then i=4 end return i end

  -- find top (min y) and bottom (max y) vertices
  local top=1 bottom=1
  for i=2,4 do
    if ys[i]<ys[top] then top=i end
    if ys[i]>ys[bottom] then bottom=i end
  end
  if ys[top]==ys[bottom] then return end -- totally flat or degenerate

  -- build the two edge chains from top->bottom:
  -- forward goes top, top+1, ... until bottom
  -- backward goes top, top-1, ... until bottom
  local f0=top
  local f1=inc(f0)
  -- advance until we hit bottom
  while f1~=bottom do f0=f1; f1=inc(f1) end
  -- at this point, forward chain is: top -> ... -> bottom (implicit)

  local b0=top
  local b1=dec(b0)
  while b1~=bottom do b0=b1; b1=dec(b1) end
  -- backward chain is: top -> ... -> bottom (implicit)

  -- edge walker constructor for segment a->b (assumes ay!=by)
  -- returns {y0,y1,x,dxdy} with y clipped to [0..127]
  local function mkedge(a,b)
    local ax,ay=xs[a],ys[a]
    local bx,by=xs[b],ys[b]
    if ay>by then
      -- enforce a above b
      ax,ay,bx,by = bx,by,ax,ay
    end
    if ay==by then return nil end

    local y0=ceil(ay)
    local y1=ceil(by)-1
    -- clip to screen y
    if y1<0 or y0>127 then return nil end
    if y0<0 then y0=0 end
    if y1>127 then y1=127 end
    if y0>y1 then return nil end

    local dxdy=(bx-ax)/(by-ay)
    local x=ax + dxdy*(y0 - ay)
    return {y0=y0,y1=y1,x=x,dxdy=dxdy}
  end

  -- make first segments on each chain (from top downward)
  local eL = mkedge(top, inc(top))
  local eR = mkedge(top, dec(top))

  -- either chain could start with a horizontal edge; skip ahead if so
  local iL = inc(top)
  while not eL and iL~=bottom do
    local next_i = inc(iL)
    eL = mkedge(iL, next_i)
    iL = next_i
  end

  local iR = dec(top)
  while not eR and iR~=bottom do
    local next_i = dec(iR)
    eR = mkedge(iR, next_i)
    iR = next_i
  end

  if not eL or not eR then return end

  -- decide which chain is actually left/right at the first active scanline
  local ystart = max(eL.y0, eR.y0)
  if ystart>eL.y0 then eL.x = eL.x + eL.dxdy*(ystart - eL.y0); eL.y0=ystart end
  if ystart>eR.y0 then eR.x = eR.x + eR.dxdy*(ystart - eR.y0); eR.y0=ystart end
  if eL.x>eR.x then eL,eR = eR,eL end

  -- draw until both chains finish
  while eL and eR do
    local y0  = max(eL.y0, eR.y0)
    local y1  = min(eL.y1, eR.y1)
    if y0<=y1 then
      -- advance x to y0 (if an edge started higher)
      -- (after first segment this is usually a no-op)
      -- half-pixel bias rounding
      for y=y0,y1 do
        local xl = flr(eL.x+0.5)
        local xr = flr(eR.x+0.5)
        -- clip span to screen x
        if xr>=0 and xl<=127 then
          if xl<0 then xl=0 end
          if xr>127 then xr=127 end
          if xr>=xl then rectfill(xl,y,xr,y) end
        end
        eL.x += eL.dxdy
        eR.x += eR.dxdy
      end
    end

    -- advance whichever edge ended at y1
    local ended_left  = (not eR) or (eL and y1>=eL.y1)
    local ended_right = (not eL) or (eR and y1>=eR.y1)

    if ended_left then
      -- move to next segment on left chain
      if iL~=bottom then
        local next_i = inc(iL)
        eL = mkedge(iL, next_i)
        iL = next_i
        -- align to next scanline
        if eL and y1+1>eL.y0 then
          eL.x = eL.x + eL.dxdy*((y1+1)-eL.y0)
          eL.y0 = y1+1
        end
      else
        eL=nil
      end
    end

    if ended_right then
      -- move to next segment on right chain
      if iR~=bottom then
        local next_i = dec(iR)
        eR = mkedge(iR, next_i)
        iR = next_i
        if eR and y1+1>eR.y0 then
          eR.x = eR.x + eR.dxdy*((y1+1)-eR.y0)
          eR.y0 = y1+1
        end
      else
        eR=nil
      end
    end

    -- keep chains as left/right for the next scan block
    if eL and eR and eL.x>eR.x then eL,eR = eR,eL end
  end
end


--triangle

function trifill(x1, y1, x2, y2, x3, y3, col)
  if col != nil then color(col) end
  -- Sort points by y-coordinate (p1.y <= p2.y <= p3.y)
  if y1 > y2 then x1, y1, x2, y2 = x2, y2, x1, y1 end
  if y1 > y3 then x1, y1, x3, y3 = x3, y3, x1, y1 end
  if y2 > y3 then x2, y2, x3, y3 = x3, y3, x2, y2 end
  
  -- Check for flat-top or flat-bottom cases
  if y1 == y2 then -- Flat-top triangle
    fill_flat_top(x1, y1, x2, y2, x3, y3)
  elseif y2 == y3 then -- Flat-bottom triangle
    fill_flat_bottom(x1, y1, x2, y2, x3, y3)
  else -- General case, split into two triangles
    local x4 = x1 + (x3 - x1) * (y2 - y1) / (y3 - y1)
    fill_flat_bottom(x1, y1, x4, y2, x2, y2)
    fill_flat_top(x2, y2, x4, y2, x3, y3)
  end
end

function fill_flat_bottom(x1, y1, x2, y2, x3, y3)
  local invslope1 = (x2 - x1) / (y2 - y1)
  local invslope2 = (x3 - x1) / (y3 - y1)
  local curx1 = x1
  local curx2 = x1
  for scanline = y1, y2 do
    line(curx1, scanline, curx2, scanline)
    curx1 += invslope1
    curx2 += invslope2
  end
end

function fill_flat_top(x1, y1, x2, y2, x3, y3)
  local invslope1 = (x3 - x1) / (y3 - y1)
  local invslope2 = (x3 - x2) / (y3 - y2)
  local curx1 = x3
  local curx2 = x3
  for scanline = y3, y1, -1 do
    line(curx1, scanline, curx2, scanline)
    curx1 -= invslope1
    curx2 -= invslope2
  end
end


--trifill fast
-- ultra-lite ceil (faster than -flr(-x) in practice on pico-8)
local function ceil(x) 
  local i=flr(x)
  if x>i then i+=1 end
  return i
end

-- draw spans y0..y1 (inclusive) with running xL/xR and per-scan slopes
-- expects: y0<=y1 and y already clipped to [0..127]
local function _scan(y0,y1, xl, xr, dxl, dxr)
  -- align to first y if the caller started earlier
  local y = y0
  if y<0 then
    local adv = -y
    xl += dxl*adv
    xr += dxr*adv
    y = 0
  end
  if y1>127 then y1=127 end
  for yy=y,y1 do
    -- clip span in x just once per scan (branch is cheap, saves line work)
    local l = flr(xl+0.5)
    local r = flr(xr+0.5)
    if r>=0 and l<=127 then
      if l<0 then l=0 end
      if r>127 then r=127 end
      if r>=l then rectfill(l,yy,r,yy) end
    end
    xl += dxl
    xr += dxr
  end
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
  -- localize hot globals
  local rectfill = rectfill

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
