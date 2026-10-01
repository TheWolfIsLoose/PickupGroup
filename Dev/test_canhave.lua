-- Self-check for Groups.CanHave (Bloodlust / battle rez seats): lua5.1 Dev/test_canhave.lua from the repo root.
local src=io.open("Groups.lua"):read("*a")
local a=src:find("function Groups.CanHave",1,true); local b=src:find("\nend\n",a,true)
local Groups={}
local need
Groups.Need=function() return need end
loadstring("local Groups=...; "..src:sub(a,b+4))(Groups)
local function Roles(...) local o={} for _,r in ipairs({...}) do o[r]=true end return o end
local LUST={SHAMAN=Roles("HEALER","DAMAGER"),MAGE=Roles("DAMAGER"),HUNTER=Roles("DAMAGER"),EVOKER=Roles("HEALER","DAMAGER")}
local function row(classes,t,h,d,fits) return {classes=classes,fits=fits~=false,left={TANK=t,HEALER=h,DAMAGER=d}} end
local function me(cls,t,h,d,flex) return {TANK=t,HEALER=h,DAMAGER=d,size=t+h+d+flex,flex=flex,classes={[cls]=true}} end
local function check(name,want,got) assert(want==got,name) print("ok",name) end
need=me("ROGUE",0,0,1,0)
check("group has lust", true, Groups.CanHave(row({MAGE=true},1,1,0),LUST))
check("rogue dps, 2 dps open -> room for lust", true, Groups.CanHave(row({},0,0,2),LUST))
check("rogue dps, 1 dps + tank open -> no lust seat", false, Groups.CanHave(row({},1,0,1),LUST))
check("rogue dps, 1 dps + healer open -> healer shaman/evoker", true, Groups.CanHave(row({},0,1,1),LUST))
need=me("MAGE",0,0,1,0)
check("I bring lust", true, Groups.CanHave(row({},1,0,1),LUST))
check("no room, no lust", false, Groups.CanHave(row({},0,0,0,false),LUST))
need=me("ROGUE",0,0,0,1) -- unknown role
check("flex takes tank first", true, Groups.CanHave(row({},1,0,1),LUST))
check("flex only dps left", false, Groups.CanHave(row({},0,0,1),LUST))
need={TANK=0,HEALER=0,DAMAGER=2,size=2,flex=0,classes={ROGUE=true,WARRIOR=true}}
check("party 2 dps, 2 dps open", false, Groups.CanHave(row({},1,0,2),LUST))
check("party 2 dps, 3 dps open", true, Groups.CanHave(row({},0,0,3),LUST))
