function _init()
    level = {}
    xsize = 5
    ysize = 5
    zdist = 8
    px = 0
    py = 0
    pz = 0
    speed = .1
    advancespeed = 0.01
    vx=0
    vy=0
    advance=.1
    damp=.9    
    ontheground = true
    gravity = 1

    xstep = 256 / (xsize-1)
    ystep = (128 / (ysize-1))
    zstep = 1

    initlevel()

    copy_sprites_to_map(1,0, 8, 4, 0, 0)
    shipx=0
    shipy=-10
    shipz=0
    playerpoints = {
        {x=-15, y=60, z=1},
        {x=15, y=60, z=1},
        {x=0, y=50, z=1},
        {x=0, y=60, z=1.5},
    }
end

function initlevel()
    for x=1,xsize do
        add(level,{})
        for y=1,ysize do
            add(level[x], {})
            for z=1,100 do
                add(level[x][y],{})
                --level[x][y][z] =  y == ysize or y == (flr(-z/3)%ysize)
                
                if y == ysize or (rnd() < .05) then 
                    level[x][y][z] = ((x+z)%10) +1
                else
                    level[x][y][z] =  0
                end 
            end
        end
    end
end

function _update()
    --if btn(⬆️) then vy+= speed  end
    -- if btn(⬇️) then vy-= speed  end
    if btn(➡️) then px-= speed*20.0  end
    if btn(⬅️) then px+= speed*20.0 end
    if btnp(⬆️) then advance += advancespeed  end
    if btnp(⬇️) then advance -= advancespeed  end
    if btn(➡️) then shipx+= speed*30  end
    if btn(⬅️) then shipx-= speed*30 end
    if btnp(❎ ) and ontheground then vy = -10 end

    
    
    checkdownwardcollision()
    
    -- px+=vx
    shipy+=vy
    -- vx*=damp
    pz+=advance
end

function checkdownwardcollision()
    --printh("x: " .. shipx .. "  y: " .. shipy .. "  z: " .. shipz)
    local ix = (shipx + xstep * 2.5) / xstep
    local iy = (shipy + ystep * 4) / ystep
    local iz = (shipz + pz) / zstep
    

    local ny = (shipy+vy+gravity + ystep * 4) / ystep
    local nz = (shipz + pz + advance) / zstep
    printh("ix: " .. ceil(ix) .. "  ny: " .. ceil(ny) .. "  iz: " .. ceil(iz))-- .. "  cell  " .. level[ceil(ix)][ceil(ny)][ceil(iz)] )
    if level[ceil(ix)][ceil(ny)][ceil(iz)] != 0 then
        vy = 0
        ontheground = true
    else
        vy += gravity
        ontheground = false
    end

    if level[ceil(ix)][ceil(iy)][ceil(nz)] != 0 then
        --printh("crash")
        _update = nil
        _draw = nil
        print("YOU CRASHED")
    end
end

function _draw()
    --rectfill(0,0,127,63,12)
    --rectfill(0,64,127,127,11)
    drawbox()

    for z=flr(pz+zdist),flr(pz-1), -1.0 do
        for x=1,xsize do
            for y=1,ysize do
                if level[x][y][z] != 0 then
                    drawcubemids(x,y,z, level[x][y][z])
                end
            end
        end
        for x=1,xsize do
            for y=1,ysize do
                if level[x][y][z] != 0 then
                    drawcubefronts(x,y,z, level[x][y][z])
                end
            end
        end
    end
    
    --right now always draw the player last (may change)
    
    drawplayer()

    color(0)
    print("FPS: " .. stat(7), 80,100)
    print("CPU: " .. stat(1), 80,108)
end

function drawbox()
    local cz = 1--pz%1

    local x = 1
    local y = 0
    local cx = ((x-1.5) / (xsize-1)) * 256 - 128 + px
    local cy = ((y-1) / (ysize-1)) * 128 - 64 + py

    local px1 = cx / cz +64
    local px2 = (cx+xstep*xsize) / cz +64
    local px3 = cx / (cz+zstep*zdist) +64
    local px4 = (cx+xstep*xsize) / (cz+zstep*zdist) +64

    local py1 = cy / cz + 64
    local py2 = (cy+ystep*ysize) / cz + 64
    local py3 = cy / (cz+zstep*zdist) + 64
    local py4 = (cy+ystep*ysize) / (cz+zstep*zdist) + 64   
    color(6)
    --qfill_ccw(px2, py1, px4, py3, px4, py4, px2, py2)
    --qfill_ccw(px1, py1, px3, py3, px3, py4, px1, py2) 
    --TODO if I want textures here I think I need to tile these.  For now leave as solid colors.
    local z2 = cz+zstep*zdist
--     function qtex_map_persp(
--   x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4,
--   mx,my, tw,th, ru,rv, chunk
    qtex_map_persp_fast(px2, py1, cz, px4, py3, z2, px4, py4, z2, px2, py2, cz, 4,0,2,2,1,1,8, 4)
    qtex_map_persp_fast(px1, py1, cz, px3, py3, z2, px3, py4, z2, px1, py2, cz, 4,0,2,2,1,1,8, 4)
    --qtex_map(px2, py1, px4, py3, px4, py4, px2, py2, 0,0,4,4,1,1)    
    --qtex_map(px1, py1, px3, py3, px3, py4, px1, py2, 0,0,4,4,2,1)

    color(5)
    qfill_ccw(px2, py1, px4, py3, px3, py3, px1, py1)    
    rectfill(px3, py3, px4, py4, 0) 
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

    --px1 += px px2 += px px3 += px px4 += px
    --py1 += py py2 += py py3 += py py4 += py 

    color(c)

    --front
    if iz<=1 or level[x][y][iz-1] == 0 then
        qfill_ccw( px1, py1, px1, py2, px2, py2,px2, py1)
        --qtex_map(px1, py1, px2, py1, px2, py2,px1, py2, 0, 0, 4, 4, 4, 2)        
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

    color(c)

    --back NOTE never needed right now
    --qfill_ccw( px3, py3, px3, py4, px4, py4,px4, py3)
    
    --right
    if x>=xsize or level[x+1][y][iz] == 0 then
        qfill_ccw(px2, py1, px4, py3, px4, py4, px2, py2)
    end

    --left    
    if x<=1 or level[x-1][y][iz] == 0 then
        qfill_ccw(px1, py1, px3, py3, px3, py4, px1, py2)
    end

    --bottom 
    if y<ysize and level[x][y+1][iz] == 0 then
        qfill_ccw(px2,py2,px4,py4, px3,py4, px1, py2)
    end

    --top
    if y<=1 or level[x][y-1][iz] == 0 then
        qfill_ccw(px2, py1, px4, py3, px3, py3, px1, py1)
        --qtex_map(px2, py1, px4, py3, px3, py3, px1, py1, 0, 0, 4, 4, 1, 1)  
    end
end

function drawplayer()
    
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
