function _init() 
    maxdist = 0
    
    splashscreeninit()
end

function splashscreeninit()
    _update60 = splashscreenupdate
    _draw = splashscreendraw
end

function splashscreenupdate()
    if btnp(❎) or btnp(🅾️) then gameinit() end
end

function splashscreendraw()
    cls(0)
    bprint("bobgar's", 19, 5, 10, 3)
    bprint("bobgar's", 20, 6, 12, 3)
    bprint("3d game", 25, 27, 8, 3)
    bprint("3d game", 26, 28, 9, 3)
    local ypos = 50
    printcentered("❎ to jump.  can double jump.", ypos) ypos += 10
    printcentered("hold ❎ while falling to glide.", ypos) ypos += 10
    printcentered("hold 🅾️ to burst forward.", ypos) ypos += 10 
    print("hover and burst", 40, ypos)
    print("deplete meters.", 40, ypos+ 10)
    drawbar(3,ypos, 20, 30,  12, 1) ypos+=10
    drawbar(3,ypos, 20, 30,  10, 9) ypos += 10 color(7)
    printcentered("meters regen over time", ypos) ypos += 15 
    print("press 🅾️ or ❎ to begin", 18, ypos) 
end

function bprint(str,x,y,c,scale)
    _str_to_sprite_sheet(str)
   
    local w = #str*4
    local h = 5
    pal(7,c)
    palt(0,true)
   
    sspr(0,0,w,h,x,y,w*scale,h*scale)
    pal()
       
    _restore_sprites_from_usermem()
end

function obprint(str,x,y,c,co,scale)
    _str_to_sprite_sheet(str)
   
    local w = #str*4
    local h = 5
    palt(0,true)
   
    pal(7,co)
    for xx=-1,1,1 do
        for yy=-1,1,1 do
            sspr(0,0,w,h,x+xx,y+yy,w*scale,h*scale)
        end
    end
   
    pal(7,c)
    sspr(0,0,w,h,x,y,w*scale,h*scale)
   
    pal()
   
    _restore_sprites_from_usermem()
end

function _str_to_sprite_sheet(str)
    _copy_sprites_to_usermem()
   
    _black_out_sprite_row()
    set_sprite_target()
    print(str,0,0,7)
    set_screen_target()
end

function set_sprite_target()
    poke(0x5f55,0x00)
end

function set_screen_target()
    poke(0x5f55,0x60)
end

function _copy_sprites_to_usermem()
    memcpy(0x4300,0x0,0x0200)
end

function _black_out_sprite_row()
    memset(0x0,0,0x0200)
end

function _restore_sprites_from_usermem()
    memcpy(0x0,0x4300,0x0200)
end
