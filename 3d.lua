function gameinit()
    zoffset = .15
    level = {}
    sidecolors ={1, 2, 4,  9, 15}
    frontcolors = {12, 14, 9,  10, 7}
    xsize = 5
    ysize = 5
    zdist = 8
    px = 0
    py = 0
    pz = 0
    speed = .1
    advancespeed = 0.03
    vx=0
    vy=0
    advance=.05
    damp=.9    
    ontheground = true
    gravity = .5
    floatvelocity = 1
    --normalgravity = .5
    maxjumps = 2
    curjumps = 2
    jumpheight = -7
    burstvelocity = .05
    burstmeter = 30
    maxburstmeter = 30
    floatmeter = 30
    maxfloatmeter = 30
    --frames per tick of recharge
    rechargespeed = 16
    curtick = 0

    xstep = 256 / (xsize-1)
    ystep = (128 / (ysize-1))
    zstep = 1
    
    initlevel()

    --copy_sprites_to_map(1,0, 8, 4, 0, 0)
    copy_sprites_to_map(0,64,16,4,0,0)
    shipx=0
    shipy=-10
    shipz=0
    playerpoints = {
        {x=-15, y=60, z=1},
        {x=15, y=60, z=1},
        {x=0, y=50, z=1},
        {x=0, y=60, z=1.5},
    }
    bottompoints = {playerpoints[1], playerpoints[2], playerpoints[4]}
    --NOTE not actually the center point now, but the most useful one to cast shadows from.
    centerpoint = {x=0, y=60, z=1.35}
    -- centerpoint = { 
    --     x= (bottompoints[1].x + bottompoints[2].x + bottompoints[3].x)/3.0,
    --     y= (bottompoints[1].y + bottompoints[2].y + bottompoints[3].y)/3.0,
    --     z= (bottompoints[1].z + bottompoints[2].z + bottompoints[3].z)/3.0
    -- } 
    _update60 = gameupdate
    _draw = gamedraw
end

function initlevel()
    for x=1,xsize do
        add(level,{})
        for y=1,ysize do
            add(level[x], {})
            for z=1,200 do
                add(level[x][y],{})
                --level[x][y][z] =  y == ysize or y == (flr(-z/3)%ysize)
                
                if (y == ysize and z<=10) or (z > 5 and rnd() < .1) then 
                    level[x][y][z] = (x+z) % #sidecolors +1  --((x+z)%10) +1
                else
                    level[x][y][z] =  0
                end 
            end
        end
    end
end

function gameupdate()
    curtick+=1
    if curtick > 30000 then curtick = 0 end
    --if btn(⬆️) then vy+= speed  end
    -- if btn(⬇️) then vy-= speed  end
    if btn(➡️) then 
        if (shipx+ playerpoints[2].x + xstep * 2.5 + speed*30) / xstep <= xsize then
            --px-= speed*20.0  
            shipx+= speed*30
        end
    end
    if btn(⬅️) then 
        if (shipx + playerpoints[1].x + xstep * 2.5 - speed*30) / xstep > 0 then
            --px+= speed*20.0
            shipx-= speed*30  
        end
    end
    px = -shipx * .75
    --py = -shipy * .65
    py = -shipy * .5
    
    --if btnp(⬆️) then advance += advancespeed  end
    --if btnp(⬇️) then advance -= advancespeed  end
    
    if btnp(❎) and curjumps>0 then vy = jumpheight curjumps-=1 end        
    if btn(❎) and vy > 0 and floatmeter > 0 then floatmeter-=1 vy = floatvelocity end
    if btn(🅾️) and burstmeter > 0 then burstmeter -= 1 pz+=advance + burstvelocity vy = 0 end

    shipy+=vy
    pz+=advance

    if curtick % rechargespeed == 0 then 
        if burstmeter < maxburstmeter then burstmeter +=1 end 
        if floatmeter < maxfloatmeter then floatmeter +=1 end 
    end
    
    checkcollisions()
end

function checkcollisionwithallpoints(x,y,z, scale)    
    for shippoint in all(playerpoints) do
        local ix = (shippoint.x*scale + x) / xstep
        local iy = ((shippoint.y-60)*scale + y) / ystep
        local iz = ((shippoint.z-1)*scale + z) / zstep
        
        --Make sure we're in bounds.  Not sure whether to count this as true or false, but for now true.
        if ix<=0 or ix > xsize or iy > ysize or iz > 100  then return true end
        if iz<=0 or iy<=0  then return false end        

        --printh("ix: " .. ix .. "  iy: " .. iy .. "  iz: " .. iz .. "  cell value: " ..  level[ceil(ix)][ceil(iy)][ceil(iz)])-- .. "  cell  " .. level[ceil(ix)][ceil(ny)][ceil(iz)] )

        if level[ceil(ix)][ceil(iy)][ceil(iz)] != 0 then return true end
    end
    return false
end

function checkcollisions()
    local ny = (shipy+vy+gravity + ystep * 4) / ystep

    --printh("ix: " .. ceil(ix) .. "  ny: " .. ceil(ny) .. "  iz: " .. ceil(iz))-- .. "  cell  " .. level[ceil(ix)][ceil(ny)][ceil(iz)] )

    --if we're below the bottom of the screen, crash
    if ny >=5 then
        printh("fall through the ground crash")
        crash()
    -- If there is ground in the next space we'd go to 
    elseif checkcollisionwithallpoints(shipx + xstep * 2.5, (shipy+vy+gravity + ystep * 4), shipz + pz + zoffset, 1) then
        -- if we're still going up, were jumping into a block so crash
        if vy < -.01 then crash() printh("jump crash") return end
        --Otherwise, we're on ground.  reset max jumps and set y velocity to 0
        vy = 0
        ontheground = true
        curjumps = maxjumps
    else
        --If we're not in contact with any blocks on y then we're falling.  Add gravity to our y velocity.
        vy += gravity
        ontheground = false
    end
    
    
    if checkcollisionwithallpoints(shipx + xstep * 2.5, shipy + ystep * 4 -3, shipz + pz + zoffset, .8) then
        printh("collision crash")
        crash()
    end

end

function crash()
    restartcounter=120
    _update60 = function() 
         p = (120.0-restartcounter) / 60.0
        restartcounter-=1 sspr(0, 64,64, 64, max(64 - 64*p, 0),max(64 - 64*p, 0),min(128,128*p),min(128*p,128))   
        if 
            restartcounter <= 0
        then 
            gameinit() 
        end 
        drawui()
    end 
    _draw = nil    
end

function gamedraw()
    local ix = ceil( (shipx + xstep * 2.5) / xstep)
    local iy = ceil( (shipy + ystep * 4) / ystep)
    local iz = ceil( (shipz + pz) / zstep)

    --printh("ix: " .. ix .. "  iy: " .. iy .. "  iz: " .. iz .. "  cell value: " ..  level[ceil(ix)][ceil(iy)][ceil(iz)])

    drawbox()

    for z=flr(pz+zdist),flr(pz-1), -1.0 do
        for y=ysize,1,-1 do
            for x=1,xsize do
                if level[x][y][z] != 0 then
                    drawcubemids(x,y,z, level[x][y][z])
                end
                if ix == x and iy == y  and iz == z then                     
                    drawplayer()
                end
            end
        end
        for y=ysize,1,-1 do
            for x=1,xsize do            
                if level[x][y][z] != 0 then
                    drawcubefronts(x,y,z, level[x][y][z])
                end
                -- if ix == x and iy == y  and iz == z then                     
                --     drawplayer()
                -- end
            end
        end
    end
    
    if iy <= 0 then
        drawplayer()
    end

    drawui()
end

function drawui()

    drawbar(3,3, floatmeter, maxfloatmeter,  12, 1)
    drawbar(3,8, burstmeter, maxburstmeter,  10, 9)

    local text = "dist: " .. flr(pz)
    print(text,128 - #text * 4, 0, 1)
    print(text,127 - #text * 4, 1, 15)

    if flr(pz) > maxdist then maxdist = flr(pz) end

    local max = "max: " .. maxdist
    print(max,128 - #max * 4, 10, 1)
    print(max,127 - #max * 4, 11, 15)

    color(0)
    --print("FPS: " .. stat(7), 80,100)
    --print("CPU: " .. stat(1), 80,108)
end

function drawbar(x, y, cur,max,  c1,c2)
    rectfill(x,y,x+max,y+3,c2)
    rectfill(x,y,x+cur,y+3,c1)
end

function drawbox()
    local cz = .1--pz%1

    local x = 1
    local y = 0
    local cx = ((x-1.5) / (xsize-1)) * 256 - 128 + px
    local cy = ((y-1) / (ysize-1)) * 128 - 64 + py

    local px1 = cx / cz +64
    local px2 = (cx+xstep*xsize) / cz +64
    local px3 = cx / (cz+zstep*zdist) +64
    local px4 = (cx+xstep*xsize) / (cz+zstep*zdist) +64

    local py1 = (cy-ystep*3) / cz + 64
    local py2 = (cy+ystep*ysize) / cz + 64 
    local py3 = (cy-ystep*3) / (cz+zstep*zdist) + 64
    local py4 = (cy+ystep*ysize) / (cz+zstep*zdist) + 64  

    --qfill_ccw(px2, py1, px4, py3, px3, py3, px1, py1)    
    rectfill(0, 0, 128, py3, 5) 
    rectfill(0, py3, 128, 128, 0) 
    --rectfill(px3, py3, px4, py4, 0) 

    color(6)
    qfill_ccw(px2, py1, px4, py3, px4, py4, px2, py2)
    qfill_ccw(px1, py1, px3, py3, px3, py4, px1, py2) 
    --TODO if I want textures here I think I need to tile these.  For now leave as solid colors.
    local z2 = cz+zstep*zdist
    --qtex_map_persp_fast(px2, py1, cz, px4, py3, z2, px4, py4, z2, px2, py2, cz, 0,0,16,4,16,1,32, 16, pz*20,0)
    --qtex_map_persp_fast(px1, py1, cz, px3, py3, z2, px3, py4, z2, px1, py2, cz, 0,0,16,4,16,1,32, 16, pz*20,0)    

    
    --sspr(8,0,64,32, px3, py3, px4-px3, (py4-py3) * 1.4 )
end

function drawcubefronts(x,y,iz, c)
    local z = iz - pz

    local cz = z * zstep
    if cz < 0 then return end
    if cz < 0.01 then cz += .01 end

    local cx = ((x-1.5) / (xsize-1)) * 256 - 128 + px
    local cy = ((y-1) / (ysize-1)) * 128 - 64 + py

    local px1 = cx / cz +64
    local px2 = (cx+xstep) / cz +64
    local px3 = cx / (cz+zstep) +64
    local px4 = (cx+xstep) / (cz+zstep) +64

    local py1 = cy / cz + 64
    local py2 = (cy+ystep) / cz + 64
    local py3 = cy / (cz+zstep) + 64
    local py4 = (cy+ystep) / (cz+zstep) + 64

    --front
    if iz<=1 or level[x][y][iz-1] == 0 then       
        color(frontcolors[c])
        qfill_ccw( px1, py1, px1, py2, px2, py2,px2, py1)       
    end
end

function drawcubemids(x,y,iz, c)
    local z = iz - pz

    local cz = z * zstep
    if cz < 0 then return end
    if cz < 0.01 then cz += .01 end

    local cx = ((x-1.5) / (xsize-1)) * 256 - 128 + px
    local cy = ((y-1) / (ysize-1)) * 128 - 64 + py

    local px1 = cx / cz +64
    local px2 = (cx+xstep) / cz +64
    local px3 = cx / (cz+zstep) +64
    local px4 = (cx+xstep) / (cz+zstep) +64

    local py1 = cy / cz + 64
    local py2 = (cy+ystep) / cz + 64
    local py3 = cy / (cz+zstep) + 64
    local py4 = (cy+ystep) / (cz+zstep) + 64

    -- px1 += px px2 += px px3 += px px4 += px
    -- py1 += py py2 += py py3 += py py4 += py 

    color(sidecolors[c])

    --back NOTE never needed right now
    --qfill_ccw( px3, py3, px3, py4, px4, py4,px4, py3)
    
    --right
    if x<xsize and level[x+1][y][iz] == 0 then
        qfill_ccw(px2, py1, px4, py3, px4, py4, px2, py2)
    end

    --left    
    if x>1 and level[x-1][y][iz] == 0 then
        qfill_ccw(px1, py1, px3, py3, px3, py4, px1, py2)
    end

    --bottom 
    if y<ysize and level[x][y+1][iz] == 0 then
        qfill_ccw(px2,py2,px4,py4, px3,py4, px1, py2)
    end

    --top
    if y <= 1 or level[x][y-1][iz] == 0 then
        qfill_ccw(px2, py1, px4, py3, px3, py3, px1, py1)
        --qtex_map(px2, py1, px4, py3, px3, py3, px1, py1, 0, 0, 4, 4, 1, 1)  
    end
end

function drawplayer()
    
    drawshadow()

    local p1x = (playerpoints[1].x+shipx + px) / playerpoints[1].z + 64
    local p1y = (playerpoints[1].y+shipy + py) / playerpoints[1].z + 64
    local p2x = (playerpoints[2].x+shipx + px) / playerpoints[2].z + 64
    local p2y = (playerpoints[2].y+shipy + py) / playerpoints[2].z + 64
    local p3x = (playerpoints[3].x+shipx + px) / playerpoints[3].z + 64
    local p3y = (playerpoints[3].y+shipy + py) / playerpoints[3].z + 64
    local p4x = (playerpoints[4].x+shipx + px) / playerpoints[4].z + 64
    local p4y = (playerpoints[4].y+shipy + py) / playerpoints[4].z + 64

    --for right now take the most naive appproachh
    color(3)
    tri_ultra(p1x, p1y , p3x,p3y, p4x,p4y)
    tri_ultra(p2x, p2y , p3x,p3y, p4x,p4y)

    color(11)
    --back
    tri_ultra(p1x, p1y , p2x,p2y, p3x,p3y)

end

function drawshadow()
    local yhits={}
    local ind = 1

    --for p in all(bottompoints) do
    local p = centerpoint
        local ix = ceil((shipx + p.x + xstep * 2.5) / xstep)
        local iy = ceil((shipy + (p.y-60) + ystep * 4) / ystep)
        local iz = ceil((shipz + (p.z-1) + pz) / zstep)
        add(yhits, nil)
        if iy < 1 then iy = 1 end
        for cury=iy,ysize,1 do
            --printh("ix: " .. ix .. "  iy: " .. iy .. "  iz: " .. iz)-- .. "  cell value: " ..  level[ceil(ix)][ceil(iy)][ceil(iz)])
            if level[ix][cury][iz] != 0 then
                yhits[ind] = cury
                break           
            end
        end
        ind+=1
    --end

    local min = yhits[1]
    -- if min == nil or (yhits[2] != nil and yhits[2] < min) then min = yhits[2] end
    -- if min == nil or (yhits[3] != nil and yhits[3] < min) then min = yhits[3] end

    --TODO right now we take a naive approach, find the highest collision under the player and use that for where to draw the triangle
    --We do no clipping so the shadow often overhangs the block, which looks weird.  Ideally I would intersect and calculate the sub-traingles
    --to draw, and draw peices at different layers, but for the purposes of this game the current implementation is probably fine.
    if min != nil then
        dy = ((- 1 / ((shipy + (bottompoints[1].y-60) + ystep * 4) / ystep - min)) - 1) * .5 + 1
        printh(dy)
        -- In this case we can draw the whole dropshadow on the same rect.        
        local cy = ((min-1) / (ysize-1)) * 128 - 64 -4
        local p1x = (bottompoints[1].x*dy+shipx + px) / bottompoints[1].z + 64
        local p1y = (cy+py) / ((bottompoints[1].z-1)*dy+1) + 64
        local p2x = (bottompoints[2].x*dy+shipx + px) / bottompoints[2].z + 64
        local p2y = (cy+py) / ((bottompoints[2].z-1)*dy+1) + 64
        local p3x = (bottompoints[3].x*dy +shipx + px) / bottompoints[3].z + 64
        local p3y = (cy+py) / ((bottompoints[3].z-1)*dy+1) + 64
        color(0)
        --printh("px: " .. p1x .. "  py: " .. p2y .. "px: " .. p2x .. "  py: " .. p1y .. "px: " .. p3x .. "  py: " .. p3y )
        tri_ultra(p1x, p1y , p2x,p2y, p3x,p3y)
    end
end
