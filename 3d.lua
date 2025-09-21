function _init()
    level = {}
    xsize = 5
    ysize = 5
    zdist = 8
    px = 1
    py = 2
    pz = 0
    speed = .1
    vx=0
    vy=0
    advance=.1
    damp=.98
    newmove = false;

    xstep = 256 / (xsize-1)
    ystep = (128 / (ysize-1))
    zstep = 1

    initlevel()

    copy_sprites_to_map(1,0, 8, 4, 0, 0)
    -- copy_sprites_to_map(1,0, 4, 4, 4, 0)
    -- copy_sprites_to_map(1,0, 4, 4, 8, 0)
    -- copy_sprites_to_map(1,0, 4, 4, 12, 0)
    -- copy_sprites_to_map(1,0, 4, 4, 0, 4)
    -- copy_sprites_to_map(1,0, 4, 4, 4, 4)
    -- copy_sprites_to_map(1,0, 4, 4, 8, 4)
    -- copy_sprites_to_map(1,0, 4, 4, 12, 4)
    -- copy_sprites_to_map(1,0, 4, 4, 0, 8)
    -- copy_sprites_to_map(1,0, 4, 4, 4, 8)
    -- copy_sprites_to_map(1,0, 4, 4, 8, 8)
    -- copy_sprites_to_map(1,0, 4, 4, 12, 8)
    -- copy_sprites_to_map(1,0, 4, 4, 0, 12)
    -- copy_sprites_to_map(1,0, 4, 4, 4, 12)
    -- copy_sprites_to_map(1,0, 4, 4, 8, 12)
    -- copy_sprites_to_map(1,0, 4, 4, 12, 12)
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
    if btn(⬆️) then vy+= speed  end
    if btn(⬇️) then vy-= speed  end
    if btn(➡️) then vx-= speed  end
    if btn(⬅️) then vx+= speed end
    px+=vx
    py+=vy
    vx*=damp
    vy*=damp
    pz+=advance
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
