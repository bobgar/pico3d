function _init()
    level = {}
    xsize = 5
    ysize = 5
    zdist = 8
    px = 1
    py = 5
    pz = 1
    speed = .1
    newmove = false;
    initlevel()
end

function initlevel()
    for x=1,xsize do
        add(level,{})
        for y=1,ysize do
            add(level[x], {})
            for z=1,100 do
                add(level[x][y],{})
                level[x][y][z] =  y == ysize or y == (flr(-z/3)%ysize)
                
            end
        end
    end
end

function _update60()
    if btn(⬆️) then pz+= speed newmove=true end
end

function _draw()
    rectfill(0,0,127,63,12)
    rectfill(0,64,127,127,11)
    for x=1,xsize do
        for y=1,ysize do
            for z=flr(pz),flr(pz+zdist), 1.0 do
                if level[x][y][z] then
                    drawcube(x,y,z - pz)
                end
            end
        end
    end
    print("FPS: " .. stat(7), 80,100)
    print("CPU: " .. stat(1), 80,108)
end

function drawcube(x,y,z)
    local c = x
    local xstep = 128 / (xsize-1)
    local ystep = (64 / (ysize-1))
    local zstep = 1

    local cx = ((x-1.5) / (xsize-1)) * 128 - 64
    local cy = ((y-1) / (ysize-1)) * 64 - 32
    local cz = z * zstep

    if abs(cz) < 0.1 or abs(cz +zstep) <0.1 then cz += .3 end

    local px1 = cx / cz +64
    local px2 = (cx+xstep) / cz +64
    local px3 = cx / (cz+zstep) +64
    local px4 = (cx+xstep) / (cz+zstep) +64

    local py1 = cy / cz + 64
    local py2 = (cy+ystep) / cz + 64
    local py3 = cy / (cz+zstep) + 64
    local py4 = (cy+ystep) / (cz+zstep) + 64

    if cz < 0 then return end

    if newmove then 
        printh("x=" .. x .. " y=" .. y .. " z=" .. z .. " points: " .. py1 .. ' , ' .. py2 .. ' , ' .. py3 .. ' , ' .. py4 .. ' , ' )
        newmove=false
    end

    color(c)
    --draw the near square
    line(px1, py1, px2, py1)
    line(px2,py1, px2, py2)
    line(px2, py2, px1, py2)
    line(px1, py2, px1, py1)
    --draw the far square
    line(px3, py3, px4, py3)
    line(px4,py3, px4, py4)
    line(px4, py4, px3, py4)
    line(px3, py4, px3, py3)
    --connect the squares
    line(px1, py1, px3, py3)
    line(px2, py1, px4, py3)
    line(px2, py2, px4, py4)
    line(px1, py2, px3, py4)
end

function checkshouldreturn()
    --if px1 < 0 or px2 > 127 or py1 < 0 or py2 > 127 then return true end
    --if px1 < 0 or py1 < 0 then return true end
    return false
end